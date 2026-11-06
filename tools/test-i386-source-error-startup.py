#!/usr/bin/env python3
"""Require original declaration survival after the actual native startup-source error."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--reference',type=Path,required=True);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    bad=ROOT/'tests/guest/i386-source-error/Bad.HC';reference=args.reference.resolve()/'result.json';gold=json.loads(reference.read_text())
    if gold.get('result')!='pass' or gold.get('mask')!=15 or not gold.get('inputs_unchanged') or not gold.get('reference_sha256') or gold['input_sha256'].get(str(bad))!=sha(bad):
        raise ValueError('Passing original control with matching malformed source required')
    manifest=args.disk.resolve().parent/'result.json';entry=json.loads(manifest.read_text())['volume']['files']['/Kernel/I386/StartOS.HC']
    paths=[Path(__file__).resolve(),bad,args.disk.resolve(),manifest,reference]+[ROOT/('tools/'+n) for n in ['test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','package-i386-native-image.py','build-i386-kernel.py']]+[ROOT/'Kernel/FontStd.HC']
    pins={str(p):sha(p) for p in paths};out.mkdir();g=None
    report=dict(result='running',input_sha256=pins,ram_mib=8,scope='Actual malformed StartOS.HC at normal startup: previous declaration/macro survive, incomplete declaration absent, subsequent mutation and console recovery. Original semantics control required; not full minimal gate.')
    try:
        data=bytearray(args.disk.read_bytes());offset=entry['block']*512;size=entry['size']
        if hashlib.sha256(data[offset:offset+size]).hexdigest()!=entry['sha256']:raise ValueError('Startup manifest differs from disk')
        if len(bad.read_bytes())>size:raise ValueError('Fixture exceeds startup extent')
        data[offset:offset+size]=bad.read_bytes().ljust(size,b' ');image=out/'working.img';image.write_bytes(data)
        pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));before=pack['snapshot'](args.disk.read_bytes())[1];after=pack['snapshot'](bytes(data))[1]
        changed={n for n in set(before)|set(after) if before.get(n)!=after.get(n)}
        if changed!={'/Kernel/I386/StartOS.HC'}:raise ValueError('Unexpected startup mutation')
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',True,ram_mib=8)
        log=g.wait('DONE native kernel startup\n')
        if 'STARTUP source error\n' not in log:raise ValueError('Expected startup source rejection missing')
        commands=['if(BootCount!=39)throw(\'SrcInit\',TRUE);',
                  'if(HashFind("bad",Fs->hash_table,HTT_GLBL_VAR))throw(\'SrcBad\',TRUE);',
                  'BootCount=41;', 'if(++BootCount!=42 || BOOT_SEEN!=7)throw(\'SrcLater\',TRUE);',
                  'if(Fs->gs!=Gs)throw(\'SrcGs\',TRUE);','6*7;']
        report['commands']=commands
        for command in commands:g.command(command)
        g.result_pixels();g.close();g=None
        if image.read_bytes()!=data:raise ValueError('Guest changed startup test disk')
        report.update(result='pass',changed_files=sorted(changed),working_disk_unchanged=True)
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        if g:g.close()
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
