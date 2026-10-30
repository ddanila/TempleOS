#!/usr/bin/env python3
"""Capture original Budget account views and transaction ordering."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
reference=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    overlay=out/'reference-overlay';overlay.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-budget-report-reference'
    paths=[Path(__file__).resolve(),ROOT/'tools/test-i386-timeclock-reference.py',fixture/'Once.HC',ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py']
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    report=dict(result='running',reference_revision=reference['REFERENCE'],repair_revision=reference['REPAIRS'],reference_sha256=reference['restore_reference'](overlay),input_sha256={str(p):sha(p) for p in paths},scope='Original Budget account views over three constructed transactions; not interactive, reboot or complete application qualification')
    try:
        iso=out/'original.iso'
        subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--overlay',str(fixture),'--output',str(iso)],cwd=ROOT,check=True)
        report['iso_sha256']=sha(iso)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        bank=(out/'guest/budget-bank.DD').read_bytes()
        rent=(out/'guest/budget-rent.DD').read_bytes()
        pointer=re.compile(rb',U=0x([0-9A-F]+)\$')
        bank_ids=pointer.findall(bank);rent_ids=pointer.findall(rent)
        if len(bank_ids)!=3 or bank_ids!=rent_ids or len(set(bank_ids))!=3 or any(int(v,16)==0 for v in bank_ids):
            raise ValueError('Report rows do not retain distinct transaction identities across views')
        def normalize(data):
            return pointer.sub(b',U=<entry>$',data)
        expected_bank=(b'$FG,0$$MU-UL,"09/04/98    WAGES     BANK:  100.00   100.00:salary",U=<entry>$\n'
                       b'$MU-UL,"09/05/98     BANK     FOOD:   80.00    20.00:groceries",U=<entry>$\n'
                       b'$MU-UL,"09/06/98     BANK     RENT:   50.00    30.00:rent",U=<entry>$\n\x05')
        expected_rent=(b'$FG,0$$MU-UL,"09/04/98    WAGES     BANK:    0.00   100.00:salary",U=<entry>$\n'
                       b'$MU-UL,"09/05/98     BANK     FOOD:    0.00    20.00:groceries",U=<entry>$\n'
                       b'$MU-UL,"09/06/98     BANK     RENT:   30.00    30.00:rent",U=<entry>$\n\x05')
        if normalize(bank)!=expected_bank or normalize(rent)!=expected_rent:
            raise ValueError('Budget account document differs from reviewed original oracle')
        report.update(result='pass',bank_latin1=normalize(bank).decode('latin1'),rent_latin1=normalize(rent).decode('latin1'))
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==digest for p,digest in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
