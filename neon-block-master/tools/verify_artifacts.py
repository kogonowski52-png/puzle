"""Local artifact verification; no device or remote publication is implied."""
from pathlib import Path
import os, zipfile, subprocess, hashlib, tempfile, json
from dex_classes import defined_classes
ROOT=Path(__file__).resolve().parents[1]
SDK=Path(os.environ.get('ANDROID_HOME','/workspace/toolchain/android-sdk'))
TOOLS=SDK/'build-tools/36.1.0'
BUNDLETOOL=Path(os.environ.get('BUNDLETOOL','/workspace/toolchain/bundletool.jar'))
report={}
for name in ['neon-block-master-debug.apk','neon-block-master-debug.aab','neon-block-master-release-unsigned.aab']:
    path=ROOT/'builds'/name
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None
        names=z.namelist()
        assert any(x.endswith('/scripts/main.gdc') for x in names)
        assert any(x.endswith('/assets/GODOT-LICENSE.txt') for x in names)
        assert any(x.endswith('/libgodot_android.so') for x in names)
        assert not any('/tests/run.gdc' in x for x in names)
        assert not any(x.endswith('/config/publishing.json') for x in names)
        config_name=next(x for x in names if x.endswith('/assets/app_config.json'))
        config=json.loads(z.read(config_name))
        assert config['mode']=='test'
        assert config['admob']['app_id']=='ca-app-pub-3940256099942544~3347511713'
        assert config['audience']=='mixed' and config['ads_enabled'] is True
        assert config['ad_sdk']=='gma_classic_24.9.0' and config['ad_profile']=='family_contextual'
        classes=set()
        for entry in names:
            if entry.endswith('.dex'): classes.update(defined_classes(z.read(entry)))
        required={
            'Lcom/google/android/gms/ads/MobileAds;',
            'Lcom/neonblockmaster/android/NeonWebView;',
            'Lcom/neonblockmaster/android/WebViewWarmup;',
            'Lcom/google/android/gms/ads/AdRequest;',
            'Lcom/google/android/gms/ads/rewarded/RewardedAd;',
            'Lcom/google/android/gms/ads/interstitial/InterstitialAd;',
            'Lcom/google/android/ump/UserMessagingPlatform;',
            'Lcom/poingstudios/godot/admob/ads/PoingGodotAdMob;',
        }
        assert required<=classes,('Missing SDK class definitions',sorted(required-classes))
        assert not any(c.startswith('Lcom/google/android/libraries/ads/mobile/sdk/') for c in classes)
        with tempfile.TemporaryDirectory() as tmp:
            aligns={}
            for entry in names:
                if not entry.endswith('.so'): continue
                local=Path(tmp)/Path(entry).name
                local.write_bytes(z.read(entry))
                ph=subprocess.check_output(['readelf','-lW',str(local)],text=True)
                values=[int(line.split()[-1],16) for line in ph.splitlines() if line.strip().startswith('LOAD')]
                assert values and min(values)>=16384,(entry,values)
                aligns[entry]=values
    if path.suffix=='.apk':
        subprocess.run([str(TOOLS/'apksigner'),'verify',str(path)],check=True)
        subprocess.run([str(TOOLS/'zipalign'),'-c','-P','16','4',str(path)],check=True)
        details=subprocess.check_output([str(TOOLS/'aapt'),'dump','badging',str(path)],text=True)
        assert "targetSdkVersion:'36'" in details
        assert "sdkVersion:'24'" in details
        assert "versionCode='9'" in details and "versionName='1.4.2'" in details
        assert "android.permission.INTERNET" in details
        assert "AD_ID" not in details
        manifest=subprocess.check_output([str(TOOLS/'aapt'),'dump','xmltree',str(path),'AndroidManifest.xml'],text=True)
        assert 'com.google.android.gms.ads.APPLICATION_ID' in manifest
        assert 'ca-app-pub-3940256099942544~3347511713' in manifest
        assert 'DELAY_APP_MEASUREMENT_INIT' in manifest
        assert 'PoingGodotAdMob' in manifest
        assert 'org.godotengine.plugin.v2.NeonWebView' in manifest
        assert 'com.neonblockmaster.diagnostics.StartupActivity' in manifest
        assert 'com.google.android.gms.ads.MobileAdsInitProvider' in manifest
        assert 'com.google.android.gms.ads.AdActivity' in manifest
    else:
        # bundletool prints every entry on success, keep that output in a log.
        log=ROOT/'builds'/(name+'.validation.txt')
        with log.open('w') as f:
            subprocess.run(['java','-jar',str(BUNDLETOOL),'validate','--bundle='+str(path)],stdout=f,stderr=subprocess.STDOUT,check=True)
    report[name]={'bytes':path.stat().st_size,'sha256':hashlib.file_digest(path.open('rb'),'sha256').hexdigest(),'elf_load_alignment':aligns}
(ROOT/'builds/artifacts.json').write_text(json.dumps(report,indent=2)+'\n')
for name,info in report.items(): print(name,info['bytes'],'bytes: PASS')
