#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
for tool in python3 nasm qemu-system-x86_64 qemu-img; do
    command -v "$tool" >/dev/null || { echo "Missing dependency: $tool" >&2; exit 1; }
done
# Always package the current checkout; HolyC recompilation happens inside TempleOS.
python3 tools/build-iso.py
if [[ ! -e build/TempleOS.qcow2 ]]; then
    qemu-img create -f qcow2 build/TempleOS.qcow2 2G
fi
# TCG works without /dev/kvm permissions and is verified on this machine.
# Extra QEMU options allow e.g. -display vnc=127.0.0.1:1 for a remote session.
exec qemu-system-x86_64 \
    -name TempleOS \
    -machine pc -accel tcg -cpu max -m 1024 -smp 2 \
    -drive file=build/TempleOS.qcow2,format=qcow2,if=ide,index=0 \
    -drive file=build/TempleOS.iso,format=raw,media=cdrom,if=ide,index=2 \
    -boot order=d -vga std -nic none -rtc base=localtime \
    "$@"
