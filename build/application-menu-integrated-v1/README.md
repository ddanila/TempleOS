# Application menu on the integrated native image

The menu patch is in `../application-menu-mouse-native-v2/candidate.patch`.
Apply it inside an overlay containing copies of the affected production
sources from `3ee5a0f2`. Put the supplied `overlay/Once.HC` in that overlay
to cross-compile ConsoleRuntime using the integrated image's bootstrap tools.

Run from the repository root with the integrated build and its bootstrap
artifacts available.

```sh
d=build/application-menu-integrated-v1
base=build/i386-graphics-registry-integration
python3 tools/build-iso.py --overlay "$base/bootstrap/overlay" \
    --overlay "$d/overlay" --output "$d/menu-compiler.iso"
python3 tools/guest-run.py "$d/menu-compiler.iso" --out "$d/menu-exports" \
    --qmp-stdio --timeout 240
mkdir -p "$d/exports"
cp "$d/menu-exports/ConsoleRuntime.t32m" "$d/exports/"
python3 "$d/package.py"
python3 "$d/run.py" "$d/candidate.img" --out "$d/native64"
python3 "$d/run.py" "$base/native-v2/kernel.img" --out "$d/baseline64"
```

The runner uses physical PS/2 motion and button events. The fixture checks
the message delivered to the focus task and records raw and logical pointer
samples. The overlay verifies the focused menu drag workflow at 64 MiB.
