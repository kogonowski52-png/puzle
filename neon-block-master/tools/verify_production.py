#!/usr/bin/env python3
"""Inspect a real production-configured AAB; never claims Play approval."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET
import zipfile

from dex_classes import defined_classes
from prepare_release import validate
from configure_billing import validate_key, PRODUCTS

ANDROID = '{http://schemas.android.com/apk/res/android}'
DEBUG_CERT = '54ab76826c313997d97a8c73ec7a808b5fc230ccc2817f503df1b067134cf18d'


def inspect(bundle, config, bundletool, candidate=False):
    errors = validate(config, require_families_review=not candidate)
    if errors:
        raise ValueError('; '.join(errors))
    with tempfile.TemporaryDirectory() as temp:
        with zipfile.ZipFile(bundle) as archive:
            if archive.testzip() is not None:
                raise ValueError('Corrupt AAB')
            names = archive.namelist()
            configs = [n for n in names if n.endswith('/assets/app_config.json')]
            if len(configs) != 1:
                raise ValueError('AAB must contain exactly one app config')
            actual = json.loads(archive.read(configs[0]))
            billing_entries = [n for n in names if n.endswith('/assets/billing_config.json')]
            if len(billing_entries)!=1: raise ValueError('Missing billing configuration')
            billing = json.loads(archive.read(billing_entries[0]))
            if billing.get('products')!=PRODUCTS: raise ValueError('Wrong billing product IDs')
            billing_configured = False
            try:
                validate_key(billing.get('public_key_base64',''))
                billing_configured = True
            except ValueError:
                if not candidate: raise ValueError('Public Google Play licensing key is required for paid release')
            plugin_configs = [n for n in names if n.endswith('/addons/admob/plugin.cfg')]
            if len(plugin_configs) != 1 or b'version="v4.3.1"' not in archive.read(plugin_configs[0]):
                raise ValueError('Missing or incorrect runtime AdMob plugin.cfg')
            if actual != config or actual.get('mode') != 'production':
                raise ValueError('Embedded configuration must match the production config')
            if any(n.endswith('/config/publishing.json') for n in names):
                raise ValueError('Private local publishing config was exported')
            signatures = [n for n in names if n.startswith('META-INF/') and n.endswith(('.RSA', '.DSA', '.EC'))]
            if candidate and signatures:
                raise ValueError('Review candidate must remain unsigned')
            if not candidate and not signatures:
                raise ValueError('Production AAB requires owner upload signature')
            classes = set()
            for name in names:
                if name.endswith('.dex'):
                    classes.update(defined_classes(archive.read(name)))
            required = {
                'Lcom/google/android/gms/ads/MobileAds;',
                'Lcom/google/android/gms/ads/rewarded/RewardedAd;',
                'Lcom/google/android/gms/ads/interstitial/InterstitialAd;',
                'Lcom/google/android/ump/UserMessagingPlatform;',
                'Lcom/poingstudios/godot/admob/ads/PoingGodotAdMobConsentInformation;',
                'Lcom/neonblockmaster/android/NeonWebView;',
                'Lcom/neonblockmaster/android/NeonConsent;',
                'Lcom/neonblockmaster/billing/NeonBilling;',
                'Lcom/neonblockmaster/billing/PurchaseVerifier;',
                'Lcom/android/billingclient/api/BillingClient;',
            }
            if not required <= classes:
                raise ValueError('Missing native definitions: ' + str(sorted(required - classes)))
            if 'Lcom/neonblockmaster/diagnostics/StartupActivity;' in classes:
                raise ValueError('Debug startup reporter must not ship in release')
            libraries = {}
            for name in names:
                if not name.endswith('.so'):
                    continue
                local = Path(temp) / Path(name).name
                local.write_bytes(archive.read(name))
                headers = subprocess.check_output(['readelf', '-lW', str(local)], text=True)
                alignments = [int(line.split()[-1], 16) for line in headers.splitlines() if line.strip().startswith('LOAD')]
                if not alignments or min(alignments) < 16384:
                    raise ValueError('Native library must support 16 KiB pages: ' + name)
                libraries[name] = alignments
            if not libraries:
                raise ValueError('No native game libraries')
        subprocess.run(['java', '-jar', str(bundletool), 'validate', '--bundle=' + str(bundle)],
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
        xml = subprocess.check_output(['java', '-jar', str(bundletool), 'dump', 'manifest', '--bundle=' + str(bundle)], text=True)
        manifest = ET.fromstring(xml)
        application = manifest.find('application')
        if application is None or application.get(ANDROID + 'debuggable', 'false') != 'false':
            raise ValueError('Release must not be debuggable')
        metadata = {node.get(ANDROID + 'name'): node.get(ANDROID + 'value') for node in application.findall('meta-data')}
        if metadata.get('com.google.android.gms.ads.APPLICATION_ID') != config['admob']['app_id']:
            raise ValueError('Manifest uses the wrong AdMob application ID')
        if metadata.get('org.godotengine.plugin.v2.NeonBilling')!='com.neonblockmaster.billing.NeonBilling':
            raise ValueError('Billing bridge not registered')
        if metadata.get('org.godotengine.plugin.v2.NeonConsent')!='com.neonblockmaster.android.NeonConsent':
            raise ValueError('UI-thread UMP bridge not registered')
        if metadata.get('com.google.android.play.billingclient.version')!='8.0.0':
            raise ValueError('Unexpected Google Play Billing version')
        permissions = {node.get(ANDROID + 'name') for node in manifest.findall('uses-permission')}
        if not {'android.permission.INTERNET', 'android.permission.ACCESS_NETWORK_STATE'} <= permissions:
            raise ValueError('Missing network permissions')
        if 'com.android.vending.BILLING' not in permissions: raise ValueError('Missing Play Billing permission')
        portrait = [n for n in manifest.findall('uses-feature') if n.get(ANDROID+'name')=='android.hardware.screen.portrait']
        if len(portrait)!=1 or portrait[0].get(ANDROID+'required')!='false':
            raise ValueError('Portrait hardware feature must be optional')
        if any('AD_ID' in p or 'AD_SERVICES' in p or 'ADSERVICES' in p or 'PHONE_STATE' in p for p in permissions):
            raise ValueError('Unexpected advertising-ID or phone permission')
        sdk = manifest.find('uses-sdk')
        if sdk is None or sdk.get(ANDROID + 'targetSdkVersion') != '36' or sdk.get(ANDROID + 'minSdkVersion') != '24':
            raise ValueError('Unexpected Android API targets')
        if manifest.get('package') != 'com.neonblockmaster.puzzle':
            raise ValueError('Unexpected package ID')
        if not candidate:
            subprocess.run(['jarsigner', '-verify', str(bundle)], check=True, stdout=subprocess.DEVNULL)
            cert = subprocess.check_output(['keytool', '-printcert', '-jarfile', str(bundle)], text=True)
            if 'Android Debug' in cert or DEBUG_CERT in cert.lower().replace(':', ''):
                raise ValueError('Debug signing certificate cannot be used for Play')
        with bundle.open('rb') as stream:
            digest = hashlib.file_digest(stream, 'sha256').hexdigest()
        return {'artifact': bundle.name, 'sha256': digest, 'bytes': bundle.stat().st_size,
                'package': manifest.get('package'), 'version_code': manifest.get(ANDROID + 'versionCode'),
                'version_name': manifest.get(ANDROID + 'versionName'), 'mode': actual['mode'],
                'admob': actual['admob'], 'signed': bool(signatures), 'debuggable': False,
                'elf_alignment': libraries, 'artifact_checks_passed': True,
                'billing_library': '8.0.0', 'billing_configured': billing_configured,
                'billing_products': billing['products'], 'live_payments_verified': False,
                'play_approval_verified': False, 'device_ad_serving_verified': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bundle', required=True, type=Path)
    parser.add_argument('--config', required=True, type=Path)
    parser.add_argument('--candidate', action='store_true', help='Inspect unsigned review candidate only')
    parser.add_argument('--report', required=True, type=Path)
    args = parser.parse_args()
    config = json.loads(args.config.read_text())
    report = inspect(args.bundle, config, Path(os.environ.get('BUNDLETOOL', '/workspace/toolchain/bundletool.jar')), args.candidate)
    args.report.write_text(json.dumps(report, indent=2) + '\n')
    print('AAB artifact checks passed. ' + ('Unsigned review candidate; not ready for Play upload.' if args.candidate else 'Complete account, device and Play Console checks before publication.'))


if __name__ == '__main__':
    main()
