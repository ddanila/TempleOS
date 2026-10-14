#!/usr/bin/env python3
"""Capture original TimeClock storage/report behavior from the pinned OS tree."""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = 'c26482bb6ad3f80106d28504ec5db3c6a360732c'
REPAIRS = 'ce055f205fc38536443289fb1cfc73632f6624f4'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    overlay = out/'reference-overlay'
    overlay.mkdir(parents=True)
    #Restore every original blob, including the original compiler/kernel binaries.
    original_paths = set(subprocess.check_output(['git','ls-tree','-r','-z','--name-only',REFERENCE],cwd=ROOT).split(b'\0'))
    listing = subprocess.check_output(['git', 'ls-tree', '-r', '-z', REPAIRS], cwd=ROOT)
    entries = [record.split(b'\t',1) for record in listing.split(b'\0') if record and record.split(b'\t',1)[1] in original_paths]
    requests = b''.join(header.split()[2]+b'\n' for header,_ in entries)
    blobs = subprocess.run(['git','cat-file','--batch'],input=requests,cwd=ROOT,
                           stdout=subprocess.PIPE,check=True).stdout
    position = 0
    source_hashes = {}
    for (header, raw_path) in entries:
        newline = blobs.index(b'\n', position)
        oid, kind, raw_size = blobs[position:newline].split()
        if oid != header.split()[2] or kind != b'blob':
            raise ValueError('Original source batch mismatch')
        position = newline+1
        data = blobs[position:position+int(raw_size)]
        position += int(raw_size)+1
        path = raw_path.decode()
        target = overlay/path
        target.parent.mkdir(parents=True,exist_ok=True)
        target.write_bytes(data)
        source_hashes[path] = hashlib.sha256(data).hexdigest()
    fixture = ROOT/'tests/guest/i386-timeclock-reference'
    golden_path = ROOT/'tests/i386/timeclock-reference.json'
    golden = json.loads(golden_path.read_text())
    if golden['reference_revision'] != REFERENCE or golden['repair_revision'] != REPAIRS:
        raise ValueError('Golden capture uses a different original reference')
    iso = out/'original.iso'
    report = dict(result='running', reference_revision=REFERENCE, repair_revision=REPAIRS, reference_sha256=source_hashes,
                  scope='Original TimeClock Load/Install, typed storage, reopen and closed report; interactive PunchIn/PunchOut and reboot persistence remain unqualified',
                  input_sha256={str(p):sha(p) for p in [Path(__file__).resolve(), fixture/'Once.HC',golden_path,ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py']})
    try:
        subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),
                        '--overlay',str(fixture),'--output',str(iso)],cwd=ROOT,check=True)
        report['iso_sha256'] = sha(iso)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),
                        '--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        data = (out/'guest/TimeClock.DATA').read_bytes()
        expected = (struct.pack('<BQ',1,(730000<<32)+0x10000000)+b'start\n\0'+
                    struct.pack('<BQ',2,(730000<<32)+0x20000000)+b'finish\n\0'+b'\0')
        if data != expected:
            raise ValueError('Original TimeClock file differs from independent typed-record oracle')
        document = (out/'guest/TimeClockReport.DD').read_bytes()
        seconds = (0x20000000-0x10000000)*86400//(1<<32)
        total = f'Week Total:{seconds//3600:02d}:{seconds//60%60:02d}:{seconds%60:02d}'.encode()
        if not all(token in document for token in [b'IN ',b'OUT',b'start',b'finish',total]):
            raise ValueError('Original report differs from required fields or independent duration oracle')
        if bytes.fromhex(golden['logical_file_hex']) != expected or document != golden['report_latin1'].encode('latin1'):
            raise ValueError('Original capture differs from reviewed golden data/report')
        report['expected_total_seconds'] = seconds
        report.update(result='pass', logical_file_bytes=len(data),
                      logical_file_sha256=hashlib.sha256(data).hexdigest(), report_sha256=hashlib.sha256(document).hexdigest())
    except Exception as exc:
        report.update(result='fail',error=str(exc))
        raise
    finally:
        if any(sha(Path(p))!=digest for p,digest in report['input_sha256'].items()):
            report.update(result='fail',error='Reference fixture or tools changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':
        raise ValueError(report['error'])


if __name__=='__main__':
    main()
