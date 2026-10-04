#!/usr/bin/env python3
"""Verify the current BIOS loader reads the last permitted payload byte."""
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
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    report_path = out / 'result.json'
    report_path.unlink(missing_ok=True)
    candidate = out / 'boundary.img'
    if candidate.resolve() == args.disk.resolve():
        parser.error('candidate must not overwrite input disk')
    original = args.disk.read_bytes()
    marker_offset = 512 + BOOT_SECTORS * 512 - 1
    if len(original) <= 2048 * 512 or original[marker_offset] != 0:
        raise ValueError('Expected a padded standard boot reservation')
    mutated = bytearray(original)
    mutated[marker_offset] = 0xA5
    candidate.write_bytes(mutated)
    digest = lambda raw: hashlib.sha256(raw).hexdigest()
    report = dict(result='fail', source_disk_sha256=digest(original),
                  payload_limit=PAYLOAD_LIMIT, marker_address=LOAD_ADDRESS + PAYLOAD_LIMIT - 1,
                  scope='Final fixed-load byte reaches guest RAM and ordinary boot works; not oversized/truncated payload rejection or full capacity qualification')
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(candidate, out / 'behavior', cpu='486,-fpu',
            qmp_stdio=True, startup_check={'status':'ok','answers':[], 'commands':[
                (f'U8 *CapacityTail={report["marker_address"]};CapacityTail[0]==0xA5;', ['1']),
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
