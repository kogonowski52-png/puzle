#!/usr/bin/env python3
"""Validate public release settings; build only with the owner's upload key."""
import argparse, html, ipaddress, json, os, re, subprocess, sys, time
from pathlib import Path
from urllib.parse import urlsplit
ROOT=Path(__file__).resolve().parents[1]
TEST_PUBLISHER='3940256099942544'

def validate(config, *, require_families_review=True):
    errors=[]
    allowed={"mode","publisher_name","contact_email","privacy_url","website_url","audience","admob","ads_enabled","ad_profile","ad_sdk","families_review"}
    if set(config)-allowed: errors.append("Unknown configuration fields rejected; never add passwords or signing credentials")
    if config.get('mode')!='production': errors.append('mode must be production')
    for key in ('publisher_name','contact_email','privacy_url','website_url'):
        if not isinstance(config.get(key),str) or not config[key].strip(): errors.append(f'{key}: required')
    email=config.get('contact_email','')
    if not isinstance(email,str) or not re.fullmatch(r'[^\s@]+@[^\s@]+\.[^\s@]+',email): errors.append('contact_email: valid public email required')
    for key in ('privacy_url','website_url'):
        try: u=urlsplit(config.get(key,''))
        except (ValueError,TypeError,AttributeError): errors.append(f'{key}: invalid URL');continue
        if u.scheme!='https' or not u.hostname or u.username or u.password or u.hostname in ('localhost','example.com','example.net','example.org') or u.hostname.endswith('.example.com'):
            errors.append(f'{key}: public HTTPS URL required')
        if u.hostname:
            try:
                if not ipaddress.ip_address(u.hostname).is_global: errors.append(f'{key}: private/local address rejected')
            except ValueError: pass
    enabled=config.get('ads_enabled',True)
    if not isinstance(enabled,bool): errors.append('ads_enabled must be a boolean')
    if config.get('audience') not in ('16+','18+','mixed','children'): errors.append('audience: choose the actual intended audience')
    if enabled:
        if config.get('ad_profile')!='family_contextual' or config.get('ad_sdk')!='gma_classic_24.9.0': errors.append('The selected classic child-directed SDK profile is required')
        review=config.get('families_review',{})
        if require_families_review and config.get('audience') in ('mixed','children') and (not isinstance(review,dict) or review.get('sdk')!='com.google.android.gms:play-services-ads:24.9.0' or review.get('status')!='verified' or not str(review.get('source','')).startswith('https://support.google.com/')):
            errors.append('Families production review still required for this exact SDK version; development APK uses official Google test units')
    ads=config.get('admob',{})
    if not isinstance(ads,dict): ads={}
    if set(ads)-{"app_id","rewarded_id","interstitial_id"}: errors.append("Unknown AdMob configuration fields rejected")
    if enabled:
        publishers=[]
        for name,sep in [('app_id','~'),('rewarded_id','/'),('interstitial_id','/')]:
            value=ads.get(name,'')
            match=re.fullmatch(r'ca-app-pub-(\d{16})'+re.escape(sep)+r'\d{10}',value) if isinstance(value,str) else None
            if not match or match[1]==TEST_PUBLISHER: errors.append(f'admob.{name}: production ID required (Google test IDs rejected)')
            else: publishers.append(match[1])
        if len(set(publishers))>1: errors.append('All AdMob IDs must belong to the same publisher')
        if ads.get('rewarded_id')==ads.get('interstitial_id'): errors.append('Rewarded and Interstitial must use separate ad units')
    return errors

def website(config,out):
    if config.get('ads_enabled',True) and config.get('ad_profile')=='family_contextual' and config.get('ad_sdk')=='gma_classic_24.9.0':
        return child_ads_website(config,out)
    if not config.get('ads_enabled',True):
        return family_website(config,out)
    out.mkdir(parents=True,exist_ok=True)
    source=(ROOT/'store/privacy.html').read_text()
    publisher=html.escape(config['publisher_name']);email=html.escape(config['contact_email'])
    source=source.replace('[UZUPEŁNIJ NAZWĘ I ADRES]',publisher).replace('[UZUPEŁNIJ E-MAIL]',email).replace('[COMPLETE NAME, ADDRESS AND EMAIL BEFORE PUBLICATION]',publisher+' — '+email)
    source=source.replace('Dokument do uzupełnienia przed publikacją. ','').replace(' Opublikuj ten dokument pod publicznym adresem HTTPS i podaj go w Google Play oraz AdMob UMP.','')
    source=source.replace('Wersja deweloperska korzysta z identyfikatorów testowych.','').replace('Developer builds use test ad identifiers.','')
    source=source.replace('Wydawca musi przed publikacją określić grupę wiekową i skonfigurować odpowiednie flagi SDK oraz formularze UMP. Ten szablon nie stanowi deklaracji zgodności z zasadami Families ani przeznaczenia dla dzieci.',f'Gra przeznaczona jest dla odbiorców {html.escape(config["audience"])}. Nie jest kierowana do dzieci. Formularze zgód i dostawców reklam skonfigurowano w Google UMP; ich działanie należy zweryfikować na urządzeniu.')
    source=source.replace('The publisher must determine the target age group, appropriate SDK flags, lawful bases and consent messages before release, and keep the Play Data safety disclosure accurate.',f'The intended audience is {html.escape(config["audience"])}. This game is not directed at children. The publisher must keep consent configuration and the Play Data safety disclosure accurate.')
    # The generated text describes the chosen configuration; never certify legal or SDK compliance.
    source=source.replace('Formularze zgód i dostawców reklam skonfigurowano w Google UMP; ich działanie należy zweryfikować na urządzeniu.','Zgody obsługuje Google UMP zgodnie z ustawieniami wydawcy.')
    (out/'privacy.html').write_text(source)
    pub=config['admob']['app_id'].split('pub-')[1].split('~')[0]
    (out/'app-ads.txt').write_text(f'google.com, pub-{pub}, DIRECT, f08c47fec0942fa0\n')
    (out/'index.html').write_text(f'<!doctype html><html lang="pl"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Neon Block Master</title><body style="background:#080d1e;color:#eff3ff;font:20px system-ui;max-width:760px;margin:60px auto;padding:24px"><h1>Neon Block Master</h1><p>Classic · Time Attack · Daily Challenge</p><p>{publisher} · <a href="mailto:{email}">{email}</a></p><p><a href="privacy.html">Polityka prywatności / Privacy policy</a></p></body></html>')

def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config',type=Path,default=ROOT/'config/publishing.json')
    parser.add_argument('--stage-website',type=Path,help='Prepare static website files; does not host or publish them')
    parser.add_argument('--check',action='store_true')
    parser.add_argument('--build',action='store_true')
    parser.add_argument('--export-candidate',action='store_true',help='Build an unsigned production-configured AAB candidate; not approved for Play upload')
    parser.add_argument('--website',type=Path,help='Generate site and app-ads.txt in this directory after validation')
    args=parser.parse_args(argv)
    try: config=json.loads(args.config.read_text())
    except (OSError,ValueError):
        print('Missing/invalid config. Copy config/publishing.example.json to config/publishing.json and fill public data.',file=sys.stderr);return 2
    if not isinstance(config,dict): print('Config must be an object.',file=sys.stderr);return 2
    if args.stage_website:
        if not isinstance(config.get('publisher_name'),str) or not config['publisher_name'].strip() or not re.fullmatch(r'[^\s@]+@[^\s@]+\.[^\s@]+',config.get('contact_email','')):
            print('Public publisher name and valid contact email required.',file=sys.stderr);return 2
        if config.get('audience') in ('mixed','children') and config.get('ads_enabled',True) and (config.get('ad_profile')!='family_contextual' or config.get('ad_sdk')!='gma_classic_24.9.0'):
            print('A selected child-directed SDK profile is required for this draft.',file=sys.stderr);return 2
        website(config,args.stage_website)
        print('Static website prepared. Hosting and public URL are not verified.')
        if not args.build and not args.export_candidate and not args.check: return 0
    if args.build and args.export_candidate:
        print('Choose either signed production build or unsigned candidate.',file=sys.stderr);return 2
    errors=validate(config,require_families_review=not args.export_candidate)
    if errors:
        print('Release blocked:\n'+'\n'.join('- '+e for e in errors),file=sys.stderr);return 2
    print('Public configuration: valid. This does not verify account ownership, HTTPS hosting, UMP setup or current Play policies.')
    if args.website: website(config,args.website)
    if args.export_candidate:
        return export_candidate(config)
    if not args.build: return 0
    required=['GODOT_ANDROID_KEYSTORE_RELEASE_PATH','GODOT_ANDROID_KEYSTORE_RELEASE_USER','GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD']
    missing=[key for key in required if not os.environ.get(key)]
    if missing: print('Signing unavailable; set securely: '+', '.join(missing),file=sys.stderr);return 2
    key=Path(os.environ[required[0]])
    if not key.is_file(): print('Upload keystore file is unavailable.',file=sys.stderr);return 2
    # Refuse the known test key. Check certificate fingerprint, never print passwords.
    password_env='GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD'
    result=subprocess.run(['keytool','-list','-v','-keystore',str(key),'-storepass:env',password_env,'-alias',os.environ[required[1]]],capture_output=True,text=True)
    if result.returncode or 'CN=Android Debug' in result.stdout:
        print('A valid non-debug upload key is required.',file=sys.stderr);return 2
    paths=[ROOT/'assets/app_config.json',ROOT/'project.godot',ROOT/'export_presets.cfg']
    backups={p:p.read_bytes() for p in paths}
    started=time.time()
    try:
        paths[0].write_text(json.dumps(config,indent=2,ensure_ascii=False)+'\n')
        preset=backups[paths[2]].decode()
        enabled='true' if config.get('ads_enabled',True) else 'false'
        preset=re.sub(r'permissions/(internet|access_network_state)=(true|false)',lambda m:'permissions/'+m[1]+'='+enabled,preset)
        paths[2].write_text(preset)
        subprocess.run(['godot','--headless','--path',str(ROOT),'--export-release','Android Production'],cwd=ROOT,check=True)
        artifact=ROOT/'builds/neon-block-master-production.aab'
        if not artifact.is_file() or artifact.stat().st_mtime<started: raise RuntimeError('No fresh AAB was created')
        import zipfile
        with zipfile.ZipFile(artifact) as z:
            if not any(n.startswith('META-INF/') and n.endswith(('.RSA','.EC','.DSA')) for n in z.namelist()): raise RuntimeError('AAB is unsigned')
        subprocess.run(['jarsigner','-verify',str(artifact)],check=True,stdout=subprocess.DEVNULL)
        if config.get('ads_enabled',True):
            subprocess.run([sys.executable,str(ROOT/'tools/verify_production.py'),'--bundle',str(artifact),'--config',str(args.config.resolve()),'--report',str(ROOT/'builds/production-artifact-validation.json')],check=True)
        print('Built production AAB. Complete device tests, consent tests and Play Console review before publication.')
    finally:
        for path,contents in backups.items(): path.write_bytes(contents)
    return 0
def export_candidate(config):
    """Build an unsigned review candidate. Never substitutes for --build readiness."""
    import hashlib, zipfile
    paths=[ROOT/'assets/app_config.json',ROOT/'export_presets.cfg']
    backups={p:p.read_bytes() for p in paths}
    output=ROOT/'builds/neon-block-master-production-candidate-unsigned.aab'
    started=time.time()
    try:
        paths[0].write_text(json.dumps(config,indent=2,ensure_ascii=False)+'\n')
        presets=backups[paths[1]].decode()
        # Reuse the release template; only this output is redirected, signing stays off.
        presets=presets.replace('export_path="builds/neon-block-master-release-unsigned.aab"',
            'export_path="builds/neon-block-master-production-candidate-unsigned.aab"')
        paths[1].write_text(presets)
        subprocess.run(['godot','--headless','--path',str(ROOT),'--export-release','Android AAB unsigned'],cwd=ROOT,check=True)
        if not output.is_file() or output.stat().st_mtime<started:raise RuntimeError('No fresh candidate AAB was created')
        with zipfile.ZipFile(output) as z:
            if z.testzip() is not None:raise RuntimeError('Invalid candidate ZIP')
            entry=next(n for n in z.namelist() if n.endswith('/assets/app_config.json'))
            actual=json.loads(z.read(entry))
            if actual!=config:raise RuntimeError('Candidate public config differs from requested config')
            if any(n.startswith('META-INF/') and n.endswith(('.RSA','.EC','.DSA')) for n in z.namelist()):raise RuntimeError('Candidate unexpectedly contains a signing certificate')
        checks=validate(config)
        with output.open('rb') as stream:digest=hashlib.file_digest(stream,'sha256').hexdigest()
        report={'artifact':output.name,'sha256':digest,
            'config_mode':config['mode'],'admob':config['admob'],'signed':False,'play_upload_ready':False,
            'outstanding_configuration_checks':checks,
            'other_required_steps':['owner upload signing key','public hosting and app-ads.txt verification','AdMob/UMP account setup and device checks','Play Console declarations and review']}
        output.with_suffix('.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
        print('UNSIGNED REVIEW CANDIDATE ONLY: '+str(output))
        print('Real ad IDs embedded. Not ready for Play upload; requires signing and outstanding release checks.')
    finally:
        for path,contents in backups.items():path.write_bytes(contents)
    return 0

def family_website(config,out):
    out.mkdir(parents=True,exist_ok=True)
    name=html.escape(config['publisher_name']);email=html.escape(config['contact_email'])
    style='<style>body{max-width:780px;margin:48px auto;padding:0 24px;background:#080d1e;color:#eff3ff;font:18px/1.7 system-ui}a,h1,h2{color:#63e8e0}nav{margin-bottom:2em}</style>'
    policy=f'''<!doctype html><html lang="pl"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Neon Block Master — Prywatność</title>{style}<body><nav><a href="index.html">Neon Block Master</a> · <a href="#english">English</a></nav><h1>Polityka prywatności</h1><p>Wersja aplikacji: 1.2.0, wydanie bez reklam.</p><p>Wydawca: {name}<br>Kontakt: <a href="mailto:{email}">{email}</a></p><h2>Dzieci i dorośli</h2><p>Gra jest przeznaczona dla dzieci i dorosłych. Ocena treści w sklepie wynika z ankiety IARC i nie jest deklarowana automatycznie. Ta wersja nie zawiera reklam ani natywnego SDK reklamowego Google, nie oferuje zakupów ani losowych płatnych nagród.</p><h2>Dane lokalne</h2><p>Wyniki, statystyki, monety, odblokowane motywy, efekty, ustawienia, daty odebrania nagród, postęp wyzwań i aktualna rozgrywka są zapisywane na urządzeniu. Starsze zapisy mogą zawierać postęp NEON LAB i identyfikator odebranego bonusu; są zachowywane przy aktualizacji. Gra nie wysyła tych danych na serwer. Nie wymaga konta, imienia, daty urodzenia, kontaktów, zdjęć, mikrofonu ani lokalizacji GPS. W wydaniu bez reklam nie pytamy o wiek. Nie stosujemy własnej analityki ani reklamowych identyfikatorów.</p><h2>Usunięcie i przechowywanie</h2><p>Dane pozostają do wyczyszczenia danych aplikacji lub odinstalowania. Lokalna kopia służy odzyskaniu zapisu po uszkodzeniu. Nie ma synchronizacji między urządzeniami; automatyczna kopia Android jest wyłączona. Wydawca nie ma dostępu do lokalnego zapisu.</p><h2>Kontakt i strona internetowa</h2><p>Rodzic lub opiekun może skontaktować się z wydawcą pod powyższym adresem. Nie przesyłaj danych dziecka ani dokumentów. E-mail może być przetwarzany przez dostawcę poczty wyłącznie w celu odpowiedzi na korespondencję, zgodnie z jego warunkami i prawem właściwym dla wydawcy. Korzystanie z tej strony ujawnia jej hostingowi techniczne dane żądania, np. adres IP; nie dodajemy skryptów śledzących ani cookies reklamowych. Strona jest przygotowana do hostowania w GitHub Pages: <a href="https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement">polityka hostingu GitHub</a>.</p><h2>Zmiany</h2><p>Przed wydaniem z reklamami ta polityka, zgody i deklaracje sklepu muszą zostać ponownie zaktualizowane. Sam plik app-ads.txt nie oznacza, że aplikacja obecnie wyświetla reklamy.</p><hr><section lang="en" id="english"><h1>Privacy policy</h1><p>Publisher: {name}. Contact: {email}. App version 1.2.0, ad-free edition for children and adults.</p><p>Scores, coins, themes, preferences, challenge progress and the current run are stored locally. Migrated saves may retain NEON LAB progress and a bonus receipt. The game sends no progress to a server and requires no account, name, date of birth, contacts, photos, microphone or GPS location. This ad-free edition does not ask your age, include the native Google advertising SDK, show ads, offer purchases or use our own analytics.</p><p>Clear app storage or uninstall to remove local data. A local backup helps recover corrupt saves; cloud backup and synchronization are disabled. Parents/guardians can contact the publisher; do not send child identity details. Email is handled only for correspondence through its provider. Website hosting may receive technical request information such as IP addresses; this site adds no tracking scripts or advertising cookies. A future advertising edition would require an updated policy and appropriate consent and store disclosures.</p></section></body></html>'''
    (out/'privacy.html').write_text(policy)
    (out/'index.html').write_text(f'''<!doctype html><html lang="pl"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Neon Block Master — Krystian Development</title>{style}<body><h1>Neon Block Master</h1><p>Neonowe puzzle dla dzieci i dorosłych.</p><p>Classic · Time Attack · Daily Challenge</p><p>Wydanie 1.2.0: gra offline bez reklam i zakupów. Układaj klocki, usuwaj linie i zdobywaj motywy za monety z rozgrywki.</p><p>{name}<br><a href="mailto:{email}">{email}</a></p><p><a href="privacy.html">Polityka prywatności / Privacy policy</a></p><p>Ocena treści w Google Play zostanie określona przez ankietę IARC. Nie deklarujemy zatwierdzenia aplikacji przez sklep.</p></body></html>''')
    app_id=config.get('admob',{}).get('app_id','')
    match=re.fullmatch(r'ca-app-pub-(\d{16})~\d{10}',app_id)
    if match and match[1]!=TEST_PUBLISHER:
        (out/'app-ads.txt').write_text(f'google.com, pub-{match[1]}, DIRECT, f08c47fec0942fa0\n')
    (out/'.nojekyll').touch()

def child_ads_website(config,out):
    out.mkdir(parents=True,exist_ok=True)
    name=html.escape(config['publisher_name']);email=html.escape(config['contact_email'])
    style='<style>body{max-width:780px;margin:48px auto;padding:0 24px;background:#080d1e;color:#eff3ff;font:18px/1.7 system-ui}a,h1,h2{color:#63e8e0}nav{margin-bottom:2em}</style>'
    mode='Oficjalne reklamy testowe Google; nie generują przychodu.' if config.get('mode')=='test' else 'Wariant z reklamami Google AdMob; warunki emisji określa Google.'
    policy=f'''<!doctype html><html lang="pl"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Neon Block Master — Prywatność</title>{style}<body><nav><a href="index.html">Neon Block Master</a> · <a href="#english">English</a></nav><h1>Polityka prywatności — 1.5.0</h1><p>Wydawca: {name}<br>Kontakt: <a href="mailto:{email}">{email}</a></p><p>{mode}</p><h2>Dzieci i dorośli</h2><p>Gra jest przeznaczona dla dzieci od 3 lat i dorosłych. Ocena treści w sklepie zostanie ustalona przez ankietę IARC. Nie wymagamy konta ani podania daty urodzenia. Wszyscy gracze otrzymują ten sam ograniczony profil żądań reklam: child-directed, under-age, maksymalna treść G i npa=1 (niepersonalizowane). Nie można uzyskać bardziej liberalnych reklam przez wybór starszego wieku.</p><h2>Dane lokalne</h2><p>Wyniki, statystyki, monety, motywy, efekty, ustawienia, daty nagród, postęp wyzwań/NEON LAB, zapas Młotków i Zmian, potwierdzenia jednorazowych nagród, identyfikator jednorazowego bonusu i bieżąca gra są zapisywane na urządzeniu. Wydawca nie przesyła ich na serwer gry. Nie ma synchronizacji postępu między urządzeniami. Opcjonalne zakupy jednorazowe obsługuje Google Play: Neon Plus oraz pakiet 10 Młotków i 20 Zmian. Gra przechowuje lokalnie uprawnienie Neon Plus i skróty potwierdzeń zakupów, aby uniknąć ponownego przyznania tego samego pakietu. Nie otrzymujemy danych karty płatniczej. Cenę i potwierdzenie płatności pokazuje Google Play. Neon Plus można przywrócić z konta Google Play; zużyte pomocniki i lokalny postęp nie wracają po usunięciu danych. Ekran rodzica wymaga rozwiązania działania i nie zbiera wieku ani daty urodzenia. Zapis usuwa wyczyszczenie danych aplikacji lub odinstalowanie; lokalna kopia służy naprawie uszkodzenia.</p><h2>Diagnostyka lokalna</h2><p>Testowe APK może zapisać lokalny raport awarii oraz pokazać wersję WebView, wynik lokalnego testu JavaScript i błędy SDK. Po błędzie silnika reklamy próbuje odczytać ograniczony log SDK wyłącznie własnego procesu, bez logów innych aplikacji. Raport nie jest automatycznie wysyłany; można go samodzielnie skopiować lub udostępnić. Dane aplikacji i raporty usuwa wyczyszczenie jej danych.</p><h2>Google Mobile Ads i UMP</h2><p>Używamy klasycznego Google Mobile Ads SDK 24.9.0 przez Poing Studios 4.3.1 oraz UMP 4.0.0. Ustawienia ograniczające są przekazywane przed inicjalizacją reklam. Aplikacja nie żąda uprawnień AD_ID, stanu telefonu ani reklamowych API Privacy Sandbox. Nie jest to twierdzenie, że zewnętrzny SDK nie przetwarza żadnych danych. Google może przetwarzać m.in. adres IP, techniczne informacje urządzenia/aplikacji, diagnostykę oraz interakcje z reklamą zgodnie ze swoimi zasadami i konfiguracją. Nie wymagamy GPS, kontaktów, zdjęć ani mikrofonu.</p><p>W wariancie produkcyjnym Google UMP otrzymuje ustawienie under-age; nie używamy zgody dorosłego jako zgody trzylatka i nie oferujemy personalizacji za nagrodę. Błąd lub nierozwiązany wymóg zgody pozostawia reklamy niezaładowane. Developerzy testują SDK na oficjalnych jednostkach testowych z tym samym ograniczonym profilem. Zmiana sposobu przetwarzania wymaga aktualizacji dokumentu i konfiguracji prawnej.</p><h2>Dobrowolne nagrody</h2><p>Za obejrzenie reklamy z nagrodą można otrzymać pokazany wcześniej bonus: pakiet 1 Młotek + 2 Zmiany, monety, ładunek PLASMA, podwojenie monet zdobytych w rozgrywce albo jedną dodatkową szansę. Nagroda wynika z potwierdzenia SDK, nie z kliknięcia reklamy lub zainstalowania innej aplikacji. Pominięcie reklamy nie blokuje zwykłej gry. Monety i motywy są wirtualne, bez wartości pieniężnej. Interstitiale są ograniczone częstotliwością i wyświetlane między rozgrywkami, nigdy podczas przeciągania. Brak internetu nie uniemożliwia gry.</p><h2>Kontakt, prawa i hosting</h2><p>Rodzic lub opiekun może skontaktować się z wydawcą pod powyższym adresem. Nie przesyłaj dokumentów ani danych identyfikujących dziecko. Lokalnych zapisów wydawca nie widzi; korespondencja e-mail jest obsługiwana wyłącznie w celu odpowiedzi, przez dostawcę poczty. W zakresie danych przetwarzanych przez wydawcę można zgłosić żądania dostępu, sprostowania, usunięcia lub inne prawa zgodnie z właściwym prawem, a także skargę do organu nadzorczego. Przetwarzanie, retencja i transfery po stronie Google podlegają zasadom Google. Hosting strony GitHub Pages może otrzymywać techniczne informacje żądania, np. IP; nie dodajemy skryptów śledzących na tej stronie.</p><p><a href="https://policies.google.com/privacy">Polityka Google</a> · <a href="https://developers.google.com/admob/android/privacy/play-data-disclosure">Dane SDK Google</a> · <a href="https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement">Polityka hostingu GitHub</a></p><hr><section lang="en" id="english"><h1>Privacy policy — 1.5.0</h1><p>Publisher: {name}. Contact: {email}. Intended for children aged 3 and above and adults; IARC determines the store rating.</p><p>We do not require an account or date of birth. Progress, coins, themes, preferences, challenges, Hammer/Shuffle inventory, purchase entitlement and hashed purchase receipts stay on your device; clear app data to remove them. Optional one-time purchases use Google Play: Neon Plus and a 10 Hammer / 20 Shuffle pack. We do not receive payment card details. Restore Neon Plus with the purchasing Google Play account; consumed boosters and local progress do not restore after deletion. A parent challenge does not collect age or birth date. All players use the same child-directed, under-age, G-rated, non-personalised ad request profile. Advertising-ID/phone/Privacy Sandbox permissions are not requested. This is not a zero-data claim for Google: its SDK may process IP addresses, technical device/app information, diagnostics and ad interactions under Google's policies. We do not request GPS, contacts, photos or microphone access.</p><p>Google Mobile Ads 24.9.0, Poing 4.3.1 and UMP 4.0.0 are used. Production UMP errors or unresolved consent requirements leave ads unloaded. An adult consent form is not used as a young child's consent. Developer test builds use Google's official demo ad units and earn no revenue. Optional earned-reward ads award the stated virtual benefit only on the SDK event, never for clicks or installing an app. Normal play remains available without ads or a connection. Interstitials are limited to breaks between games.</p><p>Debug APKs may store a local crash report and show the WebView version, local JavaScript check and SDK errors. After an ad-engine failure, a bounded SDK log from this app process may be read; other apps are excluded. Reports are not automatically uploaded. You can choose to copy or share them; clearing app data removes local reports.</p><p>Parents/guardians may contact the publisher; do not send identity documents or child identity details. Email is used for correspondence through the mail provider. Applicable rights can be exercised with the publisher; Google governs data it processes. Website hosting may receive request metadata such as IP addresses. This site adds no tracking scripts.</p></section></body></html>'''
    (out/'privacy.html').write_text(policy)
    (out/'index.html').write_text(f'''<!doctype html><html lang="pl"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Neon Block Master — Krystian Development</title>{style}<body><h1>Neon Block Master</h1><p>Neonowe puzzle dla dzieci od 3 lat i dorosłych.</p><p>Classic · Time Attack · Daily Challenge</p><p>1.5.0: integracja klasycznych reklam Google AdMob w ograniczonym profilu dla dzieci dla wszystkich graczy. {mode}</p><p>{name}<br><a href="mailto:{email}">{email}</a></p><p><a href="privacy.html">Polityka prywatności / Privacy policy</a></p><p>Ocena IARC i zatwierdzenie Google Play nie zostały nadane automatycznie.</p></body></html>''')
    match=re.fullmatch(r'ca-app-pub-(\d{16})~\d{10}',config.get('admob',{}).get('app_id',''))
    if match and match[1]!=TEST_PUBLISHER:(out/'app-ads.txt').write_text(f'google.com, pub-{match[1]}, DIRECT, f08c47fec0942fa0\n')
    (out/'.nojekyll').touch()

if __name__=='__main__': sys.exit(main())
