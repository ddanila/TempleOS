#!/usr/bin/env python3
"""Compare public compiler-control and lexer ownership with original TempleOS."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import struct
import time

ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def expected_bytes(count=24):
    return struct.pack(f"<{count}q",*([1]*count))

def main():
    ap=argparse.ArgumentParser(description=__doc__);mode=ap.add_mutually_exclusive_group();mode.add_argument('--attachment',action='store_true',help='Check public document attachment and ownership without character lexing');mode.add_argument('--characters',action='store_true',help='Check raw character, include ownership and document input instead of tokens');ap.add_argument('--lexer-storage',choices=['source','resident','provider'],default='source',help='Require exactly one initialization marker for the selected lexer implementation');ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--out',type=Path,required=True);ap.add_argument('--ram-mib',type=int,default=16);args=ap.parse_args();out=args.out.resolve()
    if args.lexer_storage!='source' and (not args.disk or args.characters or args.attachment):ap.error('Resident/provider storage requires a native token test')
    if out.exists():ap.error('Use a fresh output directory')
    fixture=ROOT/'tests/guest/i386-public-lexer'/('Attachment.HC' if args.attachment else 'Characters.HC' if args.characters else 'Contract.HC')
    includes=sorted(fixture.parent.glob('PublicLexer*.HC'))
    paths=includes+[Path(__file__).resolve(),fixture,ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py']]
    if args.disk:
        paths += [args.disk.resolve(),ROOT/'Kernel/I386/PublicLexer.HH',ROOT/'Compiler/I386/PublicLexSupport.HC',ROOT/'Compiler/LexTokenCore.HC',ROOT/'Compiler/LexExtStrCore.HC',ROOT/'Compiler/LexFilePushCore.HC']
    out.mkdir();pins={str(p):sha(p) for p in paths};report=dict(result='running',ram_mib=args.ram_mib,input_sha256=pins,scope='Twenty-four public CmpCtrlNew/CmpCtrlDel/Lex/LexExtStr checks: buffer identity, scalar tokens, adjacent strings, borrowing, prompt allocation, flags and heap cleanup. Nested includes and song tokens are checked; full compiler/Psalmody behavior remains separate.');g=None
    if args.characters:report['scope']='Sixteen public raw-character checks: cursor skipping, newline/putback, normalization, EOF, include resumption and ownership, document input and heap cleanup; prompt and error unwind remain separate.'
    if args.attachment:report['scope']='Twelve public LexAttachDoc checks: supplied document/file/entry, cursor bounds, root resumption state, owning/borrowed cleanup and original empty-document ownership.'
    report['target_flags'] = 'CCF_TARGET_I386' if args.disk else '0'
    report['lexer_storage']=args.lexer_storage
    report['attachment_mode']=args.attachment
    report['character_mode']=args.characters
    (out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    try:
        if args.disk:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img'
            before=pack['snapshot'](args.disk.read_bytes())[1]
            code=fixture.read_bytes()
            if not args.characters and not args.attachment:code=b'#define PL_TARGET_FLAGS CCF_TARGET_I386\n#include "/Kernel/I386/PublicLexer.HH"\n'+code
            additions={'/Probe/PublicLexer.HC':code,**{'/'+p.name:p.read_bytes() for p in includes}}
            report['packaging']=pack['package'](args.disk.resolve(),image,additions=additions)
        else:
            overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'PublicLexer.HC').write_bytes(fixture.read_bytes())
            for p in includes:(overlay/p.name).write_bytes(p.read_bytes())
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n#include "::/PublicLexer.HC"\nPLCheck();\n')
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(args.disk),ram_mib=args.ram_mib)
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/PublicLexer.HC"');g.command('PLCheck();')
        deadline=time.monotonic()+180
        while True:
            remaining=deadline-time.monotonic()
            if remaining<=0:raise TimeoutError('Missing guest marker: PUBLIC LEXER DONE')
            try:
                g.wait('PUBLIC LEXER DONE\n',timeout=min(30,remaining));break
            except TimeoutError:
                g.call('screendump',filename=str(out/'waiting.ppm'))
        expected={'public-lexer.bin':expected_bytes(12 if args.attachment else 16 if args.characters else 24)}
        for name,want in expected.items():
            actual=(g.out/name).read_bytes();(out/name).write_bytes(actual)
            if actual!=want:raise ValueError(name+' differs from independent byte oracle')
        if args.disk:
            if not args.characters and not args.attachment:
                log=g.collect()
                report['system_loads']=log.count('PUBLIC LEX loaded\n')
                report['resident_initializations']=log.count('PUBLIC LEX resident\n')
                report['provider_initializations']=log.count('PUBLIC LEX provider\n')
                expected_loads={'source':(1,0,0),'resident':(0,1,0),'provider':(0,0,1)}[args.lexer_storage]
                if (report['system_loads'],report['resident_initializations'],report['provider_initializations'])!=expected_loads:
                    raise ValueError('Expected exactly one '+args.lexer_storage+' lexer initialization and none for any other storage mode')
            g.command('6*7;');report['arithmetic_pixels']=g.result_pixels()
            g.close();g=None
            after=pack['snapshot'](image.read_bytes())[1]
            if {n for n in set(before)|set(after) if before.get(n)!=after.get(n)}!=set(additions):raise ValueError('Unexpected filesystem changes')
            report['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        report.update(result='pass',cases_checked=1,
                      table_sha256={n:hashlib.sha256(v).hexdigest() for n,v in expected.items()})
    except BaseException as exc:
        report.update(result='fail',error=str(exc))
        if g:
            try:g.screenshot('failure')
            except Exception as cleanup_error:report['failure_screenshot_error']=str(cleanup_error)
        raise
    finally:
        if g:
            try:g.close()
            except Exception as cleanup_error:report['guest_cleanup_error']=str(cleanup_error)
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
