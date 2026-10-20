#!/usr/bin/env bash
# Compila la versión web y la publica en Vercel (https://tanditas.vercel.app).
# La primera vez en una máquina nueva: `npx vercel@64.7.0 login`.
set -euo pipefail
cd "$(dirname "$0")/.."

flutter build web --release

# Se publica desde una copia para que `flutter build` no borre el enlace al proyecto (.vercel)
DEST=build/tanditas
mkdir -p "$DEST"
find "$DEST" -mindepth 1 -maxdepth 1 ! -name .vercel -exec rm -rf {} +
cp -r build/web/. "$DEST"/

cd "$DEST"
[ -d .vercel ] || npx --yes vercel@64.7.0 link --yes --project tanditas
npx --yes vercel@64.7.0 deploy --prod --yes
