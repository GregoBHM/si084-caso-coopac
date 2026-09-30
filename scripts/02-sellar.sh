#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
files=(evidencias/P1_puertos.txt evidencias/P2_credenciales.txt evidencias/P3_roles.txt evidencias/P4_cesados.txt evidencias/P4_genericas.txt evidencias/P5_segregacion.txt evidencias/P6_registro.txt evidencias/P7_respaldos.txt evidencias/P7_restauracion.txt)
for f in "${files[@]}"; do
  [[ -s "$f" ]] || { echo "Falta evidencia: $f"; exit 1; }
done
if command -v sha256sum >/dev/null; then
  sha256sum "${files[@]}" > evidencias/SHA256SUMS.txt
  sha256sum -c evidencias/SHA256SUMS.txt
else
  shasum -a 256 "${files[@]}" > evidencias/SHA256SUMS.txt
  shasum -a 256 -c evidencias/SHA256SUMS.txt
fi
echo 'CAPTURA 08-hashes.png: todos los archivos deben indicar OK.'

