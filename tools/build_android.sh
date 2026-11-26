#!/usr/bin/env bash
# Gera o APK de teste assinado com a chave fixa.
# Uso: GODOT=/caminho/godot KEYSTORE=/caminho/bentevi-teste.keystore tools/build_android.sh
# A chave NÃO fica no repositório. Antes de cada nova versão, aumente
# version/code no preset "Android" de export_presets.cfg.
set -euo pipefail
cd "$(dirname "$0")/.."

: "${GODOT:?defina GODOT com o caminho do executável do Godot 4.5}"
: "${KEYSTORE:?defina KEYSTORE com o caminho de bentevi-teste.keystore}"
SIGNER="${SIGNER:-tools/uber-apk-signer.jar}"
KS_PASS="${KS_PASS:-bentevi-teste}"

if [ ! -f "$SIGNER" ]; then
  curl -sSL -o "$SIGNER" https://github.com/patrickfav/uber-apk-signer/releases/download/v1.3.0/uber-apk-signer-1.3.0.jar
fi

code=$(grep -A40 '^\[preset.1.options\]' export_presets.cfg | grep '^version/code=' | cut -d= -f2)
name=$(grep -A40 '^\[preset.1.options\]' export_presets.cfg | grep '^version/name=' | cut -d= -f2 | tr -d '"')

mkdir -p build/android
"$GODOT" --headless --export-release "Android" build/android/bentevi-unsigned.apk
rm -rf build/android/signed
java -jar "$SIGNER" --apks build/android/bentevi-unsigned.apk \
  --ks "$KEYSTORE" --ksAlias bentevi --ksPass "$KS_PASS" --ksKeyPass "$KS_PASS" \
  --out build/android/signed
cp build/android/signed/*-aligned-signed.apk "build/android/bentevi-${name}-v${code}.apk"
echo "Pronto: build/android/bentevi-${name}-v${code}.apk"
