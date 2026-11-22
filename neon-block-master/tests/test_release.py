import copy, importlib.util, json, os, subprocess, tempfile, unittest
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('release',ROOT/'tools/prepare_release.py')
release=importlib.util.module_from_spec(spec);spec.loader.exec_module(release)
# Format-only fixtures; these are not real/working AdMob registrations.
def fixture():
    return {'mode':'production','publisher_name':'Fixture Publisher','contact_email':'fixture@publisher.org','privacy_url':'https://publisher.org/privacy.html','website_url':'https://publisher.org','audience':'16+','ad_profile':'family_contextual','ad_sdk':'gma_classic_24.9.0','admob':{'app_id':'ca-app-pub-1234567890123456~1234567890','rewarded_id':'ca-app-pub-1234567890123456/1234567890','interstitial_id':'ca-app-pub-1234567890123456/0987654321'}}
class ReleaseTests(unittest.TestCase):
    def test_template_blocks_release(self):
        data=json.loads((ROOT/'config/publishing.example.json').read_text())
        self.assertGreaterEqual(len(release.validate(data)),7)
    def test_test_ids_rejected(self):
        data=fixture();data['admob']['app_id']='ca-app-pub-3940256099942544~3347511713'
        self.assertTrue(any('production ID' in e for e in release.validate(data)))
    def test_different_publisher_rejected(self):
        data=fixture();data['admob']['rewarded_id']='ca-app-pub-9999999999999999/1234567890'
        self.assertTrue(any('same publisher' in e for e in release.validate(data)))
    def test_same_ad_unit_rejected(self):
        data=fixture();data['admob']['interstitial_id']=data['admob']['rewarded_id']
        self.assertTrue(any('separate ad units' in e for e in release.validate(data)))
    def test_unset_or_younger_audience_blocks_this_pipeline(self):
        for audience in ['unconfigured','children','13+']:
            data=fixture();data['audience']=audience
            self.assertTrue(any('audience' in e or 'Families' in e for e in release.validate(data)))
    def test_local_or_non_https_policy_rejected(self):
        for url in ['http://publisher.org/privacy','https://127.0.0.1/p','https://localhost/p','https://example.com/p','https://user:pass@publisher.org/p']:
            data=fixture();data['privacy_url']=url
            self.assertTrue(release.validate(data),url)
    def test_invalid_types_do_not_crash(self):
        for field in ['publisher_name','privacy_url','website_url','contact_email','admob']:
            data=fixture();data[field]=123
            self.assertTrue(release.validate(data))
    def test_accidental_credentials_are_rejected(self):
        data=fixture();data["upload_password"]="not-a-real-password"
        self.assertTrue(any("Unknown configuration" in e for e in release.validate(data)))
    def test_family_ad_free_configuration_is_supported(self):
        data=fixture();data.update(audience='mixed',ads_enabled=False);data['admob']={}
        self.assertEqual(release.validate(data),[])
    def test_family_cannot_enable_unverified_sdk(self):
        data=fixture();data.update(audience='mixed',ads_enabled=True)
        self.assertTrue(any('Families' in e for e in release.validate(data)))
    def test_family_policy_has_owner_contact_and_no_fake_child_exclusion(self):
        data=fixture();data.update(audience='mixed',ads_enabled=False)
        with tempfile.TemporaryDirectory() as tmp:
            release.website(data,Path(tmp))
            policy=(Path(tmp)/'privacy.html').read_text()
            self.assertIn('Fixture Publisher',policy)
            self.assertIn('fixture@publisher.org',policy)
            self.assertIn('dzieci i dorosłych',policy)
            self.assertNotIn('not directed at children',policy)
            self.assertNotIn('[UZUPEŁNIJ',policy)
            self.assertTrue((Path(tmp)/'.nojekyll').exists())
    def test_valid_format(self):
        self.assertEqual(release.validate(fixture()),[])
    def test_generated_site_uses_actual_configuration_and_escapes_html(self):
        data=fixture();data['publisher_name']='<script>bad()</script>'
        with tempfile.TemporaryDirectory() as tmp:
            release.website(data,Path(tmp))
            policy=(Path(tmp)/'privacy.html').read_text()
            self.assertNotIn('<script>bad()',policy)
            self.assertNotIn('[UZUPEŁNIJ',policy)
            self.assertIn('fixture@publisher.org',policy)
            self.assertEqual((Path(tmp)/'app-ads.txt').read_text(),'google.com, pub-1234567890123456, DIRECT, f08c47fec0942fa0\n')
    def test_missing_signing_does_not_modify_project(self):
        paths=[ROOT/'assets/app_config.json',ROOT/'project.godot']
        before=[p.read_bytes() for p in paths]
        with tempfile.TemporaryDirectory() as tmp:
            config=Path(tmp)/'publishing.json';config.write_text(json.dumps(fixture()))
            env=os.environ.copy()
            for key in ['GODOT_ANDROID_KEYSTORE_RELEASE_PATH','GODOT_ANDROID_KEYSTORE_RELEASE_USER','GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD']:env.pop(key,None)
            result=subprocess.run(['python3',str(ROOT/'tools/prepare_release.py'),'--config',str(config),'--build'],env=env,capture_output=True,text=True)
            self.assertEqual(result.returncode,2)
            self.assertIn('Signing unavailable',result.stderr)
        self.assertEqual([p.read_bytes() for p in paths],before)
    def test_candidate_does_not_clear_production_review(self):
        data=fixture();data.update(audience='mixed',ads_enabled=True)
        self.assertEqual(release.validate(data,require_families_review=False),[])
        self.assertTrue(any('Families' in error for error in release.validate(data)))
        data['admob']['rewarded_id']='ca-app-pub-3940256099942544/5224354917'
        self.assertTrue(any('production ID' in error for error in release.validate(data,require_families_review=False)))

    def test_failed_candidate_export_restores_development_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);(root/'assets').mkdir();(root/'builds').mkdir()
            config=root/'assets/app_config.json';config.write_text('{"mode":"test"}')
            presets=root/'export_presets.cfg';presets.write_text('export_path="builds/neon-block-master-release-unsigned.aab"')
            before=[config.read_bytes(),presets.read_bytes()]
            with patch.object(release,'ROOT',root),patch.object(release.subprocess,'run',side_effect=subprocess.CalledProcessError(1,['godot'])):
                with self.assertRaises(subprocess.CalledProcessError):release.export_candidate(fixture())
            self.assertEqual([config.read_bytes(),presets.read_bytes()],before)

    def test_candidate_report_records_real_configuration_and_missing_review(self):
        import zipfile
        data=fixture();data.update(audience='mixed',ads_enabled=True)
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);(root/'assets').mkdir();(root/'builds').mkdir()
            config=root/'assets/app_config.json';config.write_text('{"mode":"test"}')
            presets=root/'export_presets.cfg';presets.write_text('export_path="builds/neon-block-master-release-unsigned.aab"')
            def export(*args,**kwargs):
                self.assertIn('production-candidate-unsigned.aab',presets.read_text())
                with zipfile.ZipFile(root/'builds/neon-block-master-production-candidate-unsigned.aab','w') as archive:
                    archive.writestr('base/assets/assets/app_config.json',config.read_bytes())
            with patch.object(release,'ROOT',root),patch.object(release.subprocess,'run',side_effect=export):
                self.assertEqual(release.export_candidate(data),0)
            report=json.loads((root/'builds/neon-block-master-production-candidate-unsigned.json').read_text())
            self.assertFalse(report['signed']);self.assertFalse(report['play_upload_ready'])
            self.assertTrue(any('Families' in error for error in report['outstanding_configuration_checks']))
            self.assertEqual(report['admob'],data['admob'])
            self.assertEqual(json.loads(config.read_text()),{'mode':'test'})

if __name__=='__main__':unittest.main()
