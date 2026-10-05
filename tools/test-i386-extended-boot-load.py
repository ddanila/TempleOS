#!/usr/bin/env python3
"""Require a boot payload beyond the legacy ceiling to reach its selected RAM address."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
BOOT_SECTORS = 960
STAGE_BYTES = 4096
LOAD_ADDRESS = 0x11000
PAYLOAD_LIMIT = BOOT_SECTORS * 512 - STAGE_BYTES


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--payload-base',type=lambda s:int(s,0),required=True)
    parser.add_argument('--payload-bytes',type=int,default=640*1024)
    args = parser.parse_args()
    if not PAYLOAD_LIMIT<args.payload_bytes<=2048*512-512-STAGE_BYTES:
        parser.error('Payload must exceed legacy capacity and remain before the volume')
    if args.payload_base<0x100000 or args.payload_base+args.payload_bytes>8*1024*1024:
        parser.error('Select a high-memory payload range below 8 MiB')
    out = args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    report_path = out / 'result.json'
    report_path.unlink(missing_ok=True)
    candidate = out / 'boundary.img'
    if candidate.resolve() == args.disk.resolve():
        parser.error('candidate must not overwrite input disk')
    original = args.disk.read_bytes()
    marker=bytes.fromhex("c1365a920fb8e47d6a038f21d549b7ec")
    marker_offset=512+STAGE_BYTES+args.payload_bytes-len(marker)
    if len(original) <= 2048 * 512 or original[marker_offset:marker_offset+len(marker)] != bytes(len(marker)):
        raise ValueError('Expected a padded standard boot reservation')
    mutated = bytearray(original)
    mutated[marker_offset:marker_offset+len(marker)]=marker
    candidate.write_bytes(mutated)
    digest = lambda raw: hashlib.sha256(raw).hexdigest()
    report = dict(result='fail', source_disk_sha256=digest(original),
                  legacy_payload_limit=PAYLOAD_LIMIT,payload_bytes=args.payload_bytes,payload_base=args.payload_base,marker_address=args.payload_base+args.payload_bytes-len(marker),marker_hex=marker.hex(),checker_sha256=digest(Path(__file__).read_bytes()),
                  scope='Tail marker beyond legacy payload ceiling reaches selected high-memory RAM and ordinary boot works; not payload-header sizing, installation or complete extended-format qualification')
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(candidate, out / 'behavior', cpu='486,-fpu',
            qmp_stdio=True, startup_check={'status':'ok','answers':[], 'commands':[
                (f'U64 *CapacityTail={report["marker_address"]};CapacityTail[0]==0x{int.from_bytes(marker[:8],"little"):016X}&&CapacityTail[1]==0x{int.from_bytes(marker[8:],"little"):016X};', ['1']),
                ('6*7;', ['42'])]})
        if candidate.read_bytes() != mutated:
            raise ValueError('Boundary image changed during snapshot boot')
        if candidate.read_bytes()[2048*512:] != original[2048*512:]:
            raise ValueError('Boundary fixture changed filesystem bytes')
        report.update(result='pass', candidate_sha256=digest(mutated),
                      filesystem_bytes_unchanged=True)
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        report['source_disk_unchanged'] = args.disk.read_bytes() == original
        if not report['source_disk_unchanged']:
            report.update(result='fail', error='Source disk changed')
        report_path.write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
