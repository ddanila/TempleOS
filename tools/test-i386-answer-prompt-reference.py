#!/usr/bin/env python3
"""Observe original deferred answers through actual execution and CmdLinePmt."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct
import shutil
import subprocess
import time

ROOT=Path(__file__).resolve().parents[1]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path,nargs='?')
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args();out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-answer-prompt-reference'
    reference=ROOT/'tools/test-i386-timeclock-reference.py'
    paths=[Path(__file__).resolve(),reference,ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py',
           *sorted(fixture.rglob('*.HC'))]
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    paths += [ROOT/('tools/'+n) for n in ('test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','package-i386-native-image.py','build-i386-kernel.py')]
    paths.append(ROOT/'Kernel/FontStd.HC')
    if args.disk:paths.append(args.disk.resolve())
    shutil.copytree(fixture,out/'fixture-source')
    shutil.copyfile(Path(__file__),out/'runner-source.py')
    pins={str(p):sha(p) for p in paths};g=None;report=dict(result='fail',input_sha256=pins,
        scope='Actual original ExePutS/includes/nested ExeDoc and actual CmdLinePmt with queued real GetStr input; task answer state and documents. Optional normal native run uses identical fixture; not physical keyboard or complete terminal qualification')
    try:
        if args.disk:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before_files=pack['snapshot'](args.disk.read_bytes())[1]
            additions={'/Probe/AnswerPrompt.HC':(fixture/'Once.HC').read_bytes()}
            additions.update({'/'+str(p.relative_to(fixture)):p.read_bytes() for p in fixture.rglob('*.HC') if p.name!='Once.HC'})
            image=out/'working.img'
            report['packaging']=pack['package'](args.disk.resolve(),image,additions=additions)
            Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
            g=Guest(image,out/'guest',True)
            g.wait('DONE native kernel startup\n')
            #The fixture deliberately tests one caught syntax rejection. The
            #generic Guest.wait rejects it before the fixture can export state.
            g.type('#include "C:/Probe/AnswerPrompt.HC"');g.press('ret')
            deadline=time.monotonic()+240
            while g.p.poll() is None and time.monotonic()<deadline:
                text=g.collect()
                if 'DONE original answer prompt\n' in text and 'COMMAND OK\n' in text:break
                time.sleep(.1)
            else:raise TimeoutError('Missing complete answer prompt fixture')
            if text.count('INPUT REJECT ')!=1 or 'token prompt_bad ' not in text:
                raise ValueError('Unexpected native compiler rejection')
        else:
            ref=runpy.run_path(str(reference));overlay=out/'overlay';overlay.mkdir()
            report['reference_sha256']=ref['restore_reference'](overlay)
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),
                '--overlay',str(fixture),'--output',str(out/'original.iso')],cwd=ROOT,check=True)
            subprocess.run(['python3','tools/guest-run.py',str(out/'original.iso'),'--out',str(out/'guest'),
                '--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        if (out/'guest/debug.log').read_text().count('ADAM SERVER READY\n')!=1:
            raise ValueError('Original error case ran before real server readiness')
        data=(out/'guest/prompt-state.bin').read_bytes()
        if len(data)!=816:raise ValueError('Bad prompt state size')
        records=[list(struct.unpack_from('<6q',data,n*48)) for n in range(17)]
        report['records']=records
        for n,row in enumerate(records):
            before=(out/f'guest/before-{n}.DD').read_bytes();after=(out/f'guest/after-{n}.DD').read_bytes()
            if b'ans=' in before or b'ansf=' in before:raise ValueError('Original printed answers before prompt')
            if n==3:
                if before.count(b'MARK\n')!=1:raise ValueError('Missing explicit output')
            elif n!=5 and before!=b'':raise ValueError('Unexpected execution output')
            if n==5:
                if row[0]!=0 or row[1]!=41 or row[4]!=41 or b'Undefined' not in before or not re.search(rb'ans=0x[0-9A-F]+=41\n',after):
                    raise ValueError('Pending answer after syntax error differs')
            elif n==7:
                #The original decimal/x87 path can be one ULP above exact 3.75.
                if row[1] not in (0x400E000000000000,0x400E000000000001) or row[4]!=row[1] or not re.search(rb'ansf= +3\.7500000\n',after):
                    raise ValueError('Nested initializer floating answer differs')
            elif n==8:
                if row[1] or row[4] or not re.search(rb'ans=0x[0-9A-F]+=0\n',after):
                    raise ValueError('Nested initializer pointer answer differs')
            elif n==16:
                if row[0]!=0 or row[1]!=1 or row[4]!=1 or not re.search(rb'ans=0x[0-9A-F]+=1\n',after):
                    raise ValueError('Compile-time assignment pending answer differs')
            elif n>=13:
                if row[0]!=7 or row[1]!=7 or row[4]!=7 or not re.search(rb'ans=0x[0-9A-F]+=7\n',after):
                    raise ValueError('Runtime result after compile-time lookahead differs')
            elif n==10:
                if row[0]!=0 or row[1]!=123 or row[4]!=123 or not re.search(rb'ans=0x[0-9A-F]+=123\n',after):
                    raise ValueError('Compile-time integer pending answer differs')
            elif n==11:
                if row[0]!=0 or row[1] not in (0x400E000000000000,0x400E000000000001) or row[4]!=row[1] or not re.search(rb'ansf= +3\.7500000\n',after):
                    raise ValueError('Compile-time floating pending answer differs')
            elif n==12:
                if row[0]!=0 or row[1] or row[4] or not re.search(rb'ans=0x[0-9A-F]+=0\n',after):
                    raise ValueError('Compile-time pointer pending answer differs')
            elif n==9:
                if row[0]!=1 or row[2]&~1!=2 or row[4] or b'ans=' in after or b'ansf=' in after:
                    raise ValueError('Nested directory include final answer differs')
                if not re.match(rb'[0-9]+\.[0-9]+s\n',after):raise ValueError('Nested include missing void timing line')
            elif n<2 or n==6:
                if (n!=6 and row[0]!=22) or row[1]!=22 or row[4]!=22 or not re.search(rb'ans=0x[0-9A-F]+=22\n',after):
                    raise ValueError('Final scalar answer differs')
                if after.count(b'ans=')!=1:raise ValueError('Prompt printed intermediate answers')
            elif b'ans=' in after or b'ansf=' in after or row[4]:raise ValueError('Void result printed scalar answer')
            if row[3]!=1 or row[5]!=0:raise ValueError('Prompt did not consume new_answer')
        if args.disk:
            g.command('6*7;');report['arithmetic_pixels']=g.result_pixels()
            g.close();g=None
            after_files=pack['snapshot'](image.read_bytes())[1]
            if {n for n in set(before_files)|set(after_files) if before_files.get(n)!=after_files.get(n)}!=set(additions):
                raise ValueError('Unexpected filesystem changes')
            report['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        report.update(result='pass',records=records)
    except Exception as exc:
        report['error']=str(exc);raise
    finally:
        if g:g.close()
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report['result']='fail'
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError('Answer prompt reference failed')


if __name__=='__main__':main()
