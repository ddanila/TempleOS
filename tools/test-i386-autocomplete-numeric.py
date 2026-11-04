#!/usr/bin/env python3
"""Compare all ten real numeric dictionary completion keys with the original."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import subprocess
import sys
import time
from PIL import Image, ImageChops
ROOT=Path(__file__).resolve().parents[1]

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def dictionary_choices(data,prefix=b'Appl'):
    words=[];pos=0
    while pos<len(data)-1:
        if data[pos]==0:pos+=3;continue
        if data[pos]!=1:raise ValueError('Invalid word-list marker')
        end=data.index(0,pos+1);words.append(data[pos+1:end]);pos=end+3
    if len(words)!=95293:raise ValueError('Incomplete pinned dictionary')
    #Linear independent asset scan, rather than reproducing ACDWordPtAt's search.
    first=next(i for i,word in enumerate(words) if word.upper().startswith(prefix.upper()))
    choices=words[first:first+10]
    if len(choices)!=10 or any(not word.startswith(prefix) for word in choices):raise ValueError('Unexpected prefix neighborhood')
    return choices

def prefix_record(data):
    head,body=data.split(b'DOCUMENT ',1);size,document=body.split(b'\n',1)
    if len(document)!=int(size):raise ValueError('Truncated widget document')
    lines=head.splitlines();match=re.fullmatch(rb'INDEX (\d) WORD (\S+) LENGTH (\d+) DICTIONARY (\d+) COUNT (\d+)',lines.pop(0))
    if not match:raise ValueError('Invalid prefix header')
    #The guest header has an explicit trailing newline, followed by ACUILine's.
    if lines and lines[-1]==b'':lines.pop()
    rect=tuple(map(int,lines.pop(0).removeprefix(b'RECT ').split()))
    lines=[line for line in lines if line]
    choices=[]
    for index,line in enumerate(lines):
        lead=f'SLOT {index} '.encode()
        if not line.startswith(lead):raise ValueError('Invalid dictionary slot order')
        choices.append(line[len(lead):])
    return dict(index=int(match[1]),word=match[2],partial=int(match[3]),dictionary=int(match[4]),count=int(match[5]),rect=rect,choices=choices,document=document)

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();out=args.out.resolve();native=args.disk is not None
    if out.exists():ap.error('Use a fresh output directory')
    if native and not args.reference:ap.error('Native run needs --reference')
    out.mkdir(parents=True)
    helper=ROOT/'tools/test-i386-autocomplete-interaction.py';pixel_oracle=ROOT/'tools/check-i386-autocomplete-numeric-pixels.py';fixture=ROOT/'tests/guest/i386-autocomplete-interaction/Numeric.HC';contract=fixture.with_name('Contract.HC');project=fixture.with_name('Project.HC');archive=ROOT/'build/i386-autocomplete-archive-original/guest/ACWords.DATA.Z';archive_report=archive.parents[1]/'result.json'
    paths=[Path(__file__).resolve(),helper,pixel_oracle,fixture,contract,project,archive,archive_report,ROOT/'docs/i386-compatibility-inventory.json']
    paths += [ROOT/name for name in ['tools/build-iso.py','tools/package-i386-native-image.py','tools/build-i386-kernel.py','tools/test-i386-timeclock-welcome.py','Kernel/FontStd.HC','Adam/AutoComplete/MakeAC.HC','Adam/AutoComplete/ACFill.HC','Adam/AutoComplete/ACTask.HC','Adam/AutoComplete/ACInit.HC','Adam/AutoComplete/ACWords.DATA','Adam/AutoComplete/ACDefs.DATA','Adam/DolDoc/DocPutKey.HC','Adam/DolDoc/DocAutoCompleteActionCore.HC','Kernel/I386/DocumentRuntime.HC','Kernel/I386/ConsoleRuntime.HC']]
    for path,name in [(Path(__file__).resolve(),'runner-source.py'),(helper,'helper-source.py'),(pixel_oracle,'pixel-oracle-source.py'),(fixture,'numeric.HC'),(contract,'contract.HC'),(project,'project.HC')]:
        copy=out/name;copy.write_bytes(path.read_bytes());paths.append(copy)
    inventory=json.loads((ROOT/'docs/i386-compatibility-inventory.json').read_text());originals=[e for e in inventory['entries'] if e['path'] in {str(p.relative_to(ROOT)) for p in paths if p.is_relative_to(ROOT/'Adam/AutoComplete')}]
    if len(originals)!=6 or any(sha(ROOT/e['path'])!=e['reference_sha256'] for e in originals):raise ValueError('Application differs from pinned original')
    compressed=json.loads(archive_report.read_text())
    if compressed.get('result')!='pass' or not compressed.get('inputs_unchanged') or compressed.get('archive_sha256')!=sha(archive):raise ValueError('Qualified word archive required')
    expected=dictionary_choices((ROOT/'Adam/AutoComplete/ACWords.DATA').read_bytes())
    if native:
        image=out/'working.img';gold=args.reference.resolve();manifest=args.disk.resolve().parent/'result.json';paths += [args.disk.resolve(),manifest,gold/'result.json']
        if sha(args.disk.resolve())!=json.loads(manifest.read_text())['disk_sha256']:raise ValueError('Factory image differs from manifest')
        reference=json.loads((gold/'result.json').read_text())
        if reference.get('result')!='pass' or not reference.get('inputs_unchanged') or reference.get('indices')!=list(range(10)):raise ValueError('Complete original numeric reference required')
        for index in range(10):paths += [gold/f'guest/ACNPrefix{index}.DATA',gold/f'guest/prefix{index}.png',gold/f'guest/ACNSelected{index}.DATA',gold/f'guest/ACNExecuted{index}.DATA']
    else:
        image=out/'original.iso';manifest=ROOT/'build/rebuild-test/result.json';paths.append(manifest);bootstrap=json.loads(manifest.read_text())
        if bootstrap.get('result')!='pass':raise ValueError('Qualified original rebuild required')
        for name,relative in [('Kernel.BIN','0000Boot/0000Kernel.BIN.C'),('Compiler.BIN','Compiler/Compiler.BIN')]:
            path=ROOT/'build/rebuild-test/overlay'/relative
            if sha(path)!=bootstrap['generations'][-1][name]:raise ValueError('Stale original binary')
            paths.append(path)
    pins={str(path):sha(path) for path in paths};report=dict(result='running',mode='native' if native else 'rebuilt-original',indices=list(range(10)),expected_choices=[word.decode('ascii') for word in expected],input_sha256=pins,cases=[],scope='All ten Ctrl+digit dictionary slots through actual keyboard, ACDFillin/In/filter task, exact completed inputs and executed string arguments. Full dictionary and project load. Original widget documents/rectangles/pixels compared on native. Not editor numeric input, definition popups, all prefixes, exact heap recovery, minimum RAM or full C1-C5.')
    guest=None
    try:
        additions={'/ACUIProject.HC':project.read_bytes(),'/ACUIContract.HC':contract.read_bytes(),'/ACNumeric.HC':fixture.read_bytes(),'/Adam/AutoComplete/ACWords.DATA.Z':archive.read_bytes()}
        if native:report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),image,additions=additions,addition_attributes={'/Adam/AutoComplete/ACWords.DATA.Z':0xC00})
        else:
            overlay=out/'overlay'
            for name,data in additions.items():path=overlay/name.lstrip('/');path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
            (overlay/'Once.HC').write_text('while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\nAdamFile("T:/ACUIProject.HC",FALSE);\nAdamFile("T:/ACUIContract.HC",FALSE);\nAdamFile("T:/ACNumeric.HC",FALSE);\nAdam("ACUIStart;");\nTaskWait(sys_focus_task,TRUE);\nACUILog("ACN ready\\n");\n')
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay','build/rebuild-test/overlay','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        pixel_module=runpy.run_path(str(pixel_oracle));font=pixel_module['font_bytes']()
        guest=runpy.run_path(str(helper))['Guest'](image,out/'guest',native)
        if native:
            guest.wait('DONE native kernel startup\n')
            for command in ['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/ACUIProject.HC",FALSE);','AdamFile("C:/ACUIContract.HC",FALSE);','AdamFile("C:/ACNumeric.HC",FALSE);','Adam("ACUIStart(TRUE);");']:guest.command(command,1800)
        else:guest.wait('ACN ready\n',600);time.sleep(2)
        for index,word in enumerate(expected):
            mark=len(guest.collect());guest.type(f'ACNArm(Fs,{index});');guest.press('ret');guest.wait('ACN armed\n',start=mark)
            if native:guest.wait('COMMAND OK\n',start=mark)
            time.sleep(.5);mark=len(guest.collect());guest.type('ACNCheck("Appl');guest.wait('ACN prefix ready\n',60,start=mark);guest.screenshot(f'prefix{index}')
            record=prefix_record((out/f'guest/ACNPrefix{index}.DATA').read_bytes())
            if record['index']!=index or record['word']!=b'Appl' or record['partial']!=4 or record['dictionary']!=95293 or record['count']!=10 or record['choices']!=expected:raise ValueError(f'Incorrect numeric choices at index {index}')
            if native:
                original=prefix_record((gold/f'guest/ACNPrefix{index}.DATA').read_bytes())
                if record['rect']!=original['rect'] or record['document']!=original['document']:raise ValueError(f'Widget document/geometry differs at index {index}')
                l,r,t,b=record['rect'];crop=(max(0,l*8),max(0,t*8),min(640,(r+1)*8),min(480,(b+1)*8))
                if crop[0]>=crop[2] or crop[1]>=crop[3]:raise ValueError('Empty widget viewport')
                left=Image.open(gold/f'guest/prefix{index}.png').convert('RGB').crop(crop);right=Image.open(out/f'guest/prefix{index}.png').convert('RGB').crop(crop)
                if ImageChops.difference(left,right).getbbox():raise ValueError(f'Widget pixels differ at index {index}')
            mark=len(guest.collect());guest.key('ctrl',True);guest.press(str(index));guest.wait('ACN selected\n',30,start=mark);guest.key('ctrl',False);guest.screenshot(f'selected{index}')
            selected=(out/f'guest/ACNSelected{index}.DATA').read_bytes()
            if selected!=b'ACNCheck("'+word+b'\n':raise ValueError(f'Wrong completed input at index {index}')
            mark=len(guest.collect());guest.type('");');guest.press('ret');guest.wait('ACN executed\n',30,start=mark)
            if native:guest.wait('COMMAND OK\n',start=mark)
            executed=(out/f'guest/ACNExecuted{index}.DATA').read_bytes()
            if executed!=f'EXECUTION {index+1} INDEX {index} WORD '.encode()+word+b'\n':raise ValueError(f'Wrong executed argument/count at index {index}')
            deadline=time.monotonic()+15
            while True:
                guest.screenshot(f'executed{index}')
                try:pixels=pixel_module['verify'](out/f'guest/executed{index}.png',word,font);break
                except ValueError:
                    if time.monotonic()>=deadline:raise
                    time.sleep(.1)
            report['cases'].append(dict(index=index,word=word.decode('ascii'),executions=index+1,rect=record['rect'],widget_document_sha256=hashlib.sha256(record['document']).hexdigest(),result_pixels=pixels))
            (out/'progress.json').write_text(json.dumps(report['cases'],indent=2)+'\n')
        guest.close();guest=None
        if native:
            build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'));report['filesystem_integrity']=build['verify_mutated_volume'](image)
            names={f'/ACN{kind}{index}.DATA' for kind in ['Prefix','Selected','Executed'] for index in range(10)};files=build['mutated_file_contents'](image,names)
            if any(files[name]!=(out/'guest'/name.lstrip('/')).read_bytes() for name in names):raise ValueError('Persisted numeric reports differ from exports')
            report['widget_pixels']='all ten original viewport crops match exactly'
        report['result']='pass'
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        if guest:guest.close()
        report['inputs_unchanged']=all(sha(Path(path))==digest for path,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
