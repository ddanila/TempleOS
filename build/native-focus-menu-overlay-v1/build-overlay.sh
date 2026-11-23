#!/bin/bash
set -e

out=build/native-focus-menu-overlay-v1
bootstrap=build/i386-graphics-registry-integration/bootstrap/overlay
mkdir -p "$out/overlay/Kernel/I386"
for name in ConsoleRuntime GraphicsFrame WindowManager WindowMouse; do
  cp "Kernel/I386/$name.HC" "$out/overlay/Kernel/I386/"
done
cp "$out/CompilerOnce.HC" "$out/overlay/Once.HC"
patch -d "$out/overlay" -p1 < build/async-popup-focus-retire-v1/candidate.patch
patch -d "$out/overlay" -p1 < build/application-menu-mouse-native-v2/candidate.patch
python3 tools/build-iso.py --overlay "$bootstrap" --overlay "$out/overlay" \
  --output "$out/compiler.iso"
python3 tools/guest-run.py "$out/compiler.iso" --out "$out/exports" --qmp-stdio --timeout 240
python3 "$out/package.py"
