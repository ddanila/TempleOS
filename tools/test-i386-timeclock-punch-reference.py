#!/usr/bin/env python3
"""Exercise unchanged original TimeClock punch commands and decode persisted records."""
import argparse
import importlib.util
import json
from pathlib import Path
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('reference', ROOT/'tools/test-i386-timeclock-reference.py')
reference = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reference)


def decode(data):
    records = []
    offset = 0
    while offset < len(data) and data[offset]:
        kind, date = struct.unpack_from('<BQ', data, offset)
        offset += 9
        end = data.index(b'\0', offset)
        records.append((kind, date, data[offset:end]))
        offset = end+1
    if data[offset:] != b'\0':
        raise ValueError('Missing EOF or trailing application data')
    return records


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    overlay = out/'reference-overlay'
    overlay.mkdir(parents=True)
    fixture = ROOT/'tests/guest/i386-timeclock-punch-reference'
    inputs = [Path(__file__).resolve(), Path(reference.__file__), fixture/'Once.HC',
              ROOT/'tools/build-iso.py', ROOT/'tools/guest-run.py']
    report = dict(result='running', reference_revision=reference.REFERENCE,
                  repair_revision=reference.REPAIRS,
                  reference_sha256=reference.restore_reference(overlay),
                  input_sha256={str(p):reference.sha(p) for p in inputs},
                  scope='Unchanged original Load/Install and PunchIn/PunchOut via scripted real GetStr; duplicate calls, multiline/empty/cancel descriptions, typed saved records and final closed report. Not physical keyboard, reboot or native qualification.')
    try:
        iso = out/'original.iso'
        subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),
                        '--overlay',str(fixture),'--output',str(iso)],cwd=ROOT,check=True)
        report['iso_sha256'] = reference.sha(iso)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),
                        '--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        read = lambda name:(out/'guest'/name).read_bytes()
        bounds = struct.unpack('<8Q', read('bounds.bin'))
        final = decode(read('final.DATA'))
        expected = [(1,b'alpha\nbeta\n'),(2,b'finish\n'),(1,b''),(2,b'')]
        if [(kind,text) for kind,date,text in final] != expected:
            raise ValueError('Punch commands differ from expected record types/descriptions')
        for i,(_,date,_) in enumerate(final):
            if not bounds[2*i] <= date <= bounds[2*i+1]:
                raise ValueError('Application timestamp is outside observed Now bounds')
        for name,count in [('empty-out.DATA',0),('in.DATA',1),('out.DATA',2),('cancel-in.DATA',3)]:
            if decode(read(name)) != final[:count]:
                raise ValueError('Application stage differs from final record prefix: '+name)
        for first,second in [('in.DATA','duplicate-in.DATA'),('out.DATA','duplicate-out.DATA')]:
            if read(first) != read(second):
                raise ValueError('Duplicate punch modified saved bytes')
        report.update(result='pass', records=[dict(type=k,date_ticks=d,description=t.decode('latin1')) for k,d,t in final],
                      timestamp_bounds=list(bounds), cancellation='Cancelled description still commits a punch with an empty description')
    except Exception as exc:
        report.update(result='fail',error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(reference.sha(Path(p))==digest for p,digest in report['input_sha256'].items())
        if not report['inputs_unchanged']:
            report.update(result='fail',error='Reference fixture or tools changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':
        raise ValueError(report['error'])


if __name__=='__main__':
    main()
