"""Export a Play update and an isolated Android test app, restoring source configs."""
from pathlib import Path
import argparse,json,os,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
TEST_IDS={'app_id':'ca-app-pub-3940256099942544~3347511713',
          'rewarded_id':'ca-app-pub-3940256099942544/5224354917',
          'interstitial_id':'ca-app-pub-3940256099942544/1033173712'}
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--target',choices=['production','test'],required=True)
    args=parser.parse_args()
    builds=ROOT/'builds';builds.mkdir(exist_ok=True)
    if args.target=='production':
        from configure_billing import validate_key
        validate_key(json.loads((ROOT/'assets/billing_config.json').read_text())['public_key_base64'])
        return subprocess.call([sys.executable,str(ROOT/'tools/prepare_release.py'),'--config',str(ROOT/'config/publishing.json'),'--export-candidate'],cwd=ROOT)
    paths=[ROOT/'assets/app_config.json',ROOT/'assets/billing_config.json']
    backups={p:p.read_bytes() for p in paths}
    try:
        config=json.loads((ROOT/'config/publishing.family.example.json').read_text())
        config['mode']='test';config['admob']=TEST_IDS
        paths[0].write_text(json.dumps(config,indent=2)+'\n')
        billing=json.loads(backups[paths[1]]);billing['public_key_base64']=''
        paths[1].write_text(json.dumps(billing,indent=2)+'\n')
        subprocess.run(['godot','--headless','--path',str(ROOT),'--export-debug','Android Test APK'],cwd=ROOT,check=True)
        print('Unsigned isolated test APK exported. Align/sign with a local TEST key before installation.')
    finally:
        for path,data in backups.items():path.write_bytes(data)
    return 0
if __name__=='__main__':raise SystemExit(main())
