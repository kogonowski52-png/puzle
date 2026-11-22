"""Install/check a PUBLIC Google Play licensing RSA key. No private key is needed."""
import argparse
import base64
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PRODUCTS = {'neon_plus':'neon_plus','rescue_pack':'rescue_pack_10_20'}

def validate_key(value):
    if not isinstance(value,str): raise ValueError('Public licensing key must be Base64 text')
    normalized = ''.join(value.split())
    if not normalized: raise ValueError('Missing PUBLIC Google Play licensing key')
    try: data = base64.b64decode(normalized,validate=True)
    except ValueError as error: raise ValueError('Invalid Base64 public key') from error
    def tlv(content,offset,tag):
        if offset+2>len(content) or content[offset]!=tag: raise ValueError('Invalid RSA public key DER')
        length=content[offset+1];start=offset+2
        if length&128:
            count=length&127
            if count<1 or count>4 or start+count>len(content): raise ValueError('Invalid DER length')
            length=int.from_bytes(content[start:start+count],'big');start+=count
        end=start+length
        if end>len(content): raise ValueError('Truncated RSA public key')
        return content[start:end],end
    outer,end=tlv(data,0,0x30)
    if end!=len(data): raise ValueError('Unexpected data after public key')
    algorithm,pos=tlv(outer,0,0x30)
    if algorithm!=bytes.fromhex('06092a864886f70d0101010500'): raise ValueError('Expected RSA public licensing key')
    bits,end=tlv(outer,pos,0x03)
    if end!=len(outer) or not bits or bits[0]!=0: raise ValueError('Invalid RSA key bit string')
    rsa,end=tlv(bits,1,0x30)
    if end!=len(bits): raise ValueError('Invalid RSA structure')
    modulus,pos=tlv(rsa,0,0x02)
    exponent,end=tlv(rsa,pos,0x02)
    if end!=len(rsa) or not modulus or modulus[0]&128 or int.from_bytes(modulus,'big').bit_length()<2048:
        raise ValueError('Expected a Google Play RSA key of at least 2048 bits')
    if int.from_bytes(exponent,'big')<3 or int.from_bytes(exponent,'big')%2==0: raise ValueError('Invalid RSA exponent')
    return normalized,hashlib.sha256(data).hexdigest()

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--public-key-file',type=Path)
    parser.add_argument('--check',action='store_true')
    args=parser.parse_args()
    path=ROOT/'assets/billing_config.json'
    config=json.loads(path.read_text())
    try:
        text=args.public_key_file.read_text(encoding='utf-8-sig') if args.public_key_file else config.get('public_key_base64','')
        normalized,fingerprint=validate_key(text)
    except (ValueError,OSError) as error:
        parser.exit(2,str(error)+'\n')
    if config.get('products')!=PRODUCTS: parser.exit(2,'Product IDs do not match the native bridge\n')
    if args.public_key_file:
        config['public_key_base64']=normalized
        path.write_text(json.dumps(config,indent=2)+'\n')
    print('Public licensing key valid. SHA-256: '+fingerprint)
    print('This does not activate products or verify real payments in Google Play.')

if __name__=='__main__':main()
