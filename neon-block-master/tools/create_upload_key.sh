#!/usr/bin/env bash
# Run locally. Never commit or send the resulting key or password through chat.
set -euo pipefail
umask 077
if [ "$#" -ne 1 ]; then
  echo 'Usage: tools/create_upload_key.sh /secure/path/neon-upload.p12' >&2
  exit 2
fi
neon_key_path=$1
if [ -e "$neon_key_path" ]; then
  echo 'Refusing to overwrite an existing signing key.' >&2
  exit 2
fi
if [ -z "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:-}" ]; then
  read -r -s -p 'New upload-key password (keep it in your password manager): ' GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
  printf '\n'
  export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
fi
if [ "${#GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD}" -lt 12 ]; then
  echo 'Use at least 12 characters for the upload-key password.' >&2
  exit 2
fi
keytool -genkeypair -keystore "$neon_key_path" -storetype PKCS12 -storepass:env GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD -alias upload -keyalg RSA -keysize 4096 -validity 10000 -dname 'CN=Neon Block Master Upload,OU=Mobile Signing'
chmod 600 "$neon_key_path"
echo 'Upload key created. Back it up securely. Alias: upload. Never use the Android debug key for Play.'
