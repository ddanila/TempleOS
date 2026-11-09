#!/usr/bin/env python3
"""Check complete shared DolDoc ownership on pinned original x64 scaffolding."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

ROOT=Path(__file__).resolve().parents[1]
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--baseline-revision',help='Observe a complete historical grammar body instead of qualifying the current body')
    args=parser.parse_args();out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/doc-dollar-error-component/Contract.HC'
    core=ROOT/'Adam/DolDoc/DocDollarParseCore.HC'
    paths=[Path(__file__).resolve(),fixture,ROOT/'Adam/DolDoc/DocDollarFlagsCore.HC',ROOT/'Adam/DolDoc/DocDollarServices.HH']
    paths += [ROOT/'tools'/name for name in ('test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','build-iso.py','i386-kernel-input.py')]
    if not args.baseline_revision:paths.append(core)
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,baseline_revision=args.baseline_revision,
        scope='Complete shared grammar on immutable original x64 services; real Lex/LexExtStr and controlled scalar/effect-failure callbacks test full partial-entry deletion in ordinary parse-error and caught-error paths. Native normal APIs are qualified separately; not a replacement parser or OOM/cancellation qualification.')
    guest=None
    try:
        body=subprocess.check_output(['git','show',args.baseline_revision+':Adam/DolDoc/DocDollarParseCore.HC'],cwd=ROOT) if args.baseline_revision else core.read_bytes()
        report['grammar_sha256']=hashlib.sha256(body).hexdigest()
        (out/'ParseCore.HC').write_bytes(body);(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
        overlay=out/'overlay';overlay.mkdir()
        report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
        probe=overlay/'Probe';probe.mkdir()
        for name,data in [('ParseCore.HC',body),('FlagsCore.HC',paths[2].read_bytes()),('Services.HH',paths[3].read_bytes()),('Contract.HC',fixture.read_bytes())]:(probe/name).write_bytes(data)
        (overlay/'Once.HC').write_text('while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n#include "::/Probe/Contract.HC"\n')
        subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(out/'original.iso')],cwd=ROOT,check=True)
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];guest=Guest(out/'original.iso',out/'guest',False)
        guest.wait('DOLLAR ERROR COMPONENT DONE\n',timeout=180)
        data=(guest.out/'dollar-component.bin').read_bytes();(out/'dollar-component.bin').write_bytes(data)
        report['records']=list(struct.unpack('<40q',data))
        if args.baseline_revision:report['result']='observed'
        else:
            if report['records']!=[1,1,1,0,0]*8:raise ValueError('Shared ownership differs: '+str(report['records']))
            report['result']='pass'
    except BaseException as error:
        report.update(result='fail',error=str(error) or type(error).__name__);raise
    finally:
        if guest:guest.close()
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']=='fail':raise ValueError(report['error'])
    print(report['result'].upper(),'shared x64 DolDoc ownership')
if __name__=='__main__':main()
