#!/usr/bin/env python3
"""Compare a real dictionary definition popup, navigation, close and resumed input."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import subprocess
import sys
import struct
import time
from PIL import Image, ImageChops, ImageDraw
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

def popup_record(data):
    head,body=data.split(b'DOCUMENT ',1);size,document=body.split(b'\n',1)
    if len(document)!=int(size):raise ValueError('Incomplete popup document')
    lines=head.splitlines()
    first=re.fullmatch(rb'STAGE (\d) MASK (\d+)',lines[0])
    if not first or len(lines)!=6:raise ValueError('Invalid popup header')
    zbuffer,popup_z,ac_z=lines[3].removeprefix(b'ZBUFFER ').split()
    frame,body_address=map(lambda value:int(value,16),lines[5].removeprefix(b'FRAME ').split())
    return dict(frame=frame,body_address=body_address,raster=tuple(map(int,lines[4].removeprefix(b'RASTER ').split())),zbuffer=int(zbuffer,16),popup_z=int(popup_z),ac_z=int(ac_z),stage=int(first[1]),mask=int(first[2]),rect=tuple(map(int,lines[1].removeprefix(b'RECT ').split())),state=tuple(map(int,lines[2].removeprefix(b'STATE ').split())),document=document)

def capture_stage(guest,out,stage,record):
    palette=[]
    for color in range(256):
        rgb=[(42 if color&bit else 0)+(21 if color&8 else 0) for bit in (4,2,1)]
        if color==6:rgb[1]=21
        palette.extend((v<<2)|((v&1)*3) for v in rgb)
    deadline=time.monotonic()+30
    while True:
        guest.call('stop')
        try:
            frame_path=out/f'guest/frame{stage}.DATA'
            guest.call('pmemsave',val=record['frame'],size=32,filename=str(frame_path))
            seq,same,popup_z,ac_z=struct.unpack('<4q',frame_path.read_bytes())
            if seq and same:
                guest.call('pmemsave',val=record['zbuffer'],size=9600,filename=str(out/f'guest/zbuffer{stage}.DATA'))
                guest.call('pmemsave',val=record['body_address'],size=640*480,filename=str(out/f'guest/raster{stage}.DATA'))
                guest.screenshot(f'popup{stage}')
                zbuf=struct.unpack('<4800H',(out/f'guest/zbuffer{stage}.DATA').read_bytes())
                mask=Image.new('L',(640,480));draw=ImageDraw.Draw(mask);l,r,t,b=record['rect']
                for y in range(max(0,t),min(59,b)+1):
                    for x in range(max(0,l),min(79,r)+1):
                        if zbuf[y*80+x]<=popup_z:draw.rectangle((x*8,y*8,x*8+7,y*8+7),fill=255)
                cx,cy=record['raster'][:2]
                if 0<=cx<80 and 0<=cy<60:draw.rectangle((cx*8,cy*8,cx*8+7,cy*8+7),fill=0)
                rendered=Image.frombytes('P',(640,480),(out/f'guest/raster{stage}.DATA').read_bytes());rendered.putpalette(palette)
                screen=Image.open(out/f'guest/popup{stage}.png').convert('RGB')
                if not ImageChops.multiply(ImageChops.difference(screen,rendered.convert('RGB')),mask.convert('RGB')).getbbox():
                    record['popup_z']=popup_z;record['ac_z']=ac_z
                    return
        finally:guest.call('cont')
        if time.monotonic()>=deadline:raise TimeoutError('No self-consistent published popup raster and visibility frame')
        time.sleep(.01)

def expected_definition(data):
    name=b'Apple';start=data.index(b'\x01'+name+b'\0');end=data.index(b'\x01',start+1);pos=start+len(name)+2
    text=name+b':\n\n';count=0;fields=0
    while pos<end:
        kind=data[pos];finish=data.index(0,pos+1);field=data[pos+1:finish]
        if kind not in (2,3,4,5) or b'$' in field:raise ValueError('Unexpected chosen definition encoding')
        if kind==2:count+=1;text+=f'({count}) '.encode()
        text+=field+b'\n';pos=finish+1;fields+=1
    if pos!=end or count!=5:raise ValueError('Incomplete Apple definition record')
    return text,dict(record_bytes=end-start,fields=fields,definitions=count)

def plain_document(document):
    return re.sub(rb'\$[^$]*\$',b'',document).replace(b'\x05',b'')

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();out=args.out.resolve();native=args.disk is not None
    if out.exists():ap.error('Use a fresh output directory')
    if native and not args.reference:ap.error('Native run needs --reference')
    out.mkdir(parents=True)
    helper=ROOT/'tools/test-i386-autocomplete-interaction.py';pixel_oracle=ROOT/'tools/check-i386-autocomplete-numeric-pixels.py';fixture=ROOT/'tests/guest/i386-autocomplete-interaction/Numeric.HC';popup=fixture.with_name('Popup.HC');contract=fixture.with_name('Contract.HC');project=fixture.with_name('Project.HC');archive=ROOT/'build/i386-autocomplete-archive-original/guest/ACWords.DATA.Z';archive_report=archive.parents[1]/'result.json'
    paths=[Path(__file__).resolve(),helper,pixel_oracle,fixture,popup,contract,project,archive,archive_report,ROOT/'docs/i386-compatibility-inventory.json']
    paths += [ROOT/name for name in ['tools/build-iso.py','tools/package-i386-native-image.py','tools/build-i386-kernel.py','tools/test-i386-timeclock-welcome.py','Kernel/FontStd.HC','Adam/AutoComplete/MakeAC.HC','Adam/AutoComplete/ACFill.HC','Adam/AutoComplete/ACTask.HC','Adam/AutoComplete/ACInit.HC','Adam/AutoComplete/ACWords.DATA','Adam/AutoComplete/ACDefs.DATA','Adam/DolDoc/DocPutKey.HC','Adam/DolDoc/DocAutoCompleteActionCore.HC','Kernel/I386/DocumentRuntime.HC','Kernel/I386/ConsoleRuntime.HC','Kernel/I386/PublicDocument.HH','Kernel/I386/ConsoleRuntime.HH','Kernel/I386/PopupRuntime.HC','Adam/DolDoc/DocGetKeyCore.HC','HomeSys.HC','Adam/SrvStartUpCore.HC','Kernel/I386/StartOS.HC']]
    for path,name in [(Path(__file__).resolve(),'runner-source.py'),(helper,'helper-source.py'),(pixel_oracle,'pixel-oracle-source.py'),(fixture,'numeric.HC'),(popup,'popup.HC'),(contract,'contract.HC'),(project,'project.HC')]:
        copy=out/name;copy.write_bytes(path.read_bytes());paths.append(copy)
    inventory=json.loads((ROOT/'docs/i386-compatibility-inventory.json').read_text());originals=[e for e in inventory['entries'] if e['path'] in {str(p.relative_to(ROOT)) for p in paths if p.is_relative_to(ROOT/'Adam/AutoComplete')}]
    if len(originals)!=6 or any(sha(ROOT/e['path'])!=e['reference_sha256'] for e in originals):raise ValueError('Application differs from pinned original')
    compressed=json.loads(archive_report.read_text())
    if compressed.get('result')!='pass' or not compressed.get('inputs_unchanged') or compressed.get('archive_sha256')!=sha(archive):raise ValueError('Qualified word archive required')
    expected=dictionary_choices((ROOT/'Adam/AutoComplete/ACWords.DATA').read_bytes())
    expected_text,definition=expected_definition((ROOT/'Adam/AutoComplete/ACDefs.DATA').read_bytes())
    if native:
        image=out/'working.img';gold=args.reference.resolve();manifest=args.disk.resolve().parent/'result.json';paths += [args.disk.resolve(),manifest,gold/'result.json']
        if sha(args.disk.resolve())!=json.loads(manifest.read_text())['disk_sha256']:raise ValueError('Factory image differs from manifest')
        reference=json.loads((gold/'result.json').read_text())
        if reference.get('result')!='pass' or not reference.get('inputs_unchanged') or reference.get('workflow')!='dictionary-definition-popup':raise ValueError('Complete original numeric reference required')
        for stage in range(3):paths += [gold/f'guest/ACPUPopup{stage}.DATA',gold/f'guest/popup{stage}.png',gold/f'guest/zbuffer{stage}.DATA',gold/f'guest/frame{stage}.DATA',gold/f'guest/raster{stage}.DATA']
    else:
        image=out/'original.iso';manifest=ROOT/'build/rebuild-test/result.json';paths.append(manifest);bootstrap=json.loads(manifest.read_text())
        if bootstrap.get('result')!='pass':raise ValueError('Qualified original rebuild required')
        for name,relative in [('Kernel.BIN','0000Boot/0000Kernel.BIN.C'),('Compiler.BIN','Compiler/Compiler.BIN')]:
            path=ROOT/'build/rebuild-test/overlay'/relative
            if sha(path)!=bootstrap['generations'][-1][name]:raise ValueError('Stale original binary')
            paths.append(path)
    pins={str(path):sha(path) for path in paths};report=dict(result='running',mode='native' if native else 'rebuilt-original',workflow='dictionary-definition-popup',definition=definition,expected_choices=[word.decode('ascii') for word in expected],input_sha256=pins,cases=[],scope='Real Ctrl+Shift+5 Apple definition popup, independent complete pinned definition text, original document/geometry/state and visible static pixels at open and physical PageUp/PageDown, real Escape close and restored document roles/focus/input, real completion and resumed execution. Not all definitions, popup failures, all keys or full C1-C5.')
    guest=None
    try:
        additions={'/ACUIProject.HC':project.read_bytes(),'/ACUIContract.HC':contract.read_bytes(),'/ACNumeric.HC':fixture.read_bytes(),'/ACPopup.HC':popup.read_bytes(),'/Adam/AutoComplete/ACWords.DATA.Z':archive.read_bytes()}
        if native:report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),image,additions=additions,addition_attributes={'/Adam/AutoComplete/ACWords.DATA.Z':0xC00})
        else:
            overlay=out/'overlay'
            for name,data in additions.items():path=overlay/name.lstrip('/');path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
            (overlay/'Once.HC').write_text('while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\nAdamFile("T:/ACUIProject.HC",FALSE);\nAdamFile("T:/ACUIContract.HC",FALSE);\nAdamFile("T:/ACNumeric.HC",FALSE);\nAdamFile("T:/ACPopup.HC",FALSE);\nAdam("ACUIStart;");\nTaskWait(sys_focus_task,TRUE);\nACUILog("ACN ready\\n");\n')
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay','build/rebuild-test/overlay','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        pixel_module=runpy.run_path(str(pixel_oracle));font=pixel_module['font_bytes']()
        guest=runpy.run_path(str(helper))['Guest'](image,out/'guest',native)
        if native:
            guest.wait('DONE native kernel startup\n')
            for command in ['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/ACUIProject.HC",FALSE);','AdamFile("C:/ACUIContract.HC",FALSE);','AdamFile("C:/ACNumeric.HC",FALSE);','AdamFile("C:/ACPopup.HC",FALSE);','Adam("ACUIStart(TRUE);");']:guest.command(command,1800)
        else:guest.wait('ACN ready\n',600);time.sleep(2)
        guest.call('input-send-event',events=[{'type':'rel','data':{'axis':'x','value':1000}},{'type':'rel','data':{'axis':'y','value':-1000}}])
        report['comparison_errors']=[]
        mark=len(guest.collect());guest.type('ACPUArm(Fs);');guest.press('ret');guest.wait('ACPU armed\n',start=mark)
        if native:guest.wait('COMMAND OK\n',start=mark)
        time.sleep(.5);mark=len(guest.collect());guest.type('ACNCheck("Appl');guest.wait('ACN prefix ready\n',60,start=mark);guest.screenshot('prefix')
        choices=prefix_record((out/'guest/ACNPrefix0.DATA').read_bytes())
        if choices['choices']!=expected or choices['word']!=b'Appl' or choices['partial']!=4 or choices['dictionary']!=95293:raise ValueError('Wrong actual dictionary choices')
        mark=len(guest.collect());guest.key('ctrl',True);guest.key('shift',True);guest.press('5');guest.key('shift',False);guest.key('ctrl',False)
        for stage in range(3):
            if stage:mark=len(guest.collect());guest.press('pgup' if stage==1 else 'pgdn')
            guest.wait(f'ACPU stage {stage}\n',60,start=mark)
            record=popup_record((out/f'guest/ACPUPopup{stage}.DATA').read_bytes())
            if record['stage']!=stage or record['mask']!=31:raise ValueError('Popup ownership/focus/document roles differ')
            capture_stage(guest,out,stage,record)
            plain=plain_document(record['document'])
            if plain!=expected_text:raise ValueError(f'Popup text differs from complete independent definition at stage {stage}')
            if native:
                original=popup_record((gold/f'guest/ACPUPopup{stage}.DATA').read_bytes())
                _,_,original['popup_z'],original['ac_z']=struct.unpack('<4q',(gold/f'guest/frame{stage}.DATA').read_bytes())
                if any(record[key]!=original[key] for key in ['rect','state','document']) or record['raster'][:2]!=original['raster'][:2]:report['comparison_errors'].append(f'Popup document/geometry/navigation differs at stage {stage}')
                l,r,t,b=record['rect'];crop=(max(0,l*8),max(0,t*8),min(640,(r+1)*8),min(480,(b+1)*8))
                if crop[0]>=crop[2] or crop[1]>=crop[3]:raise ValueError('Empty popup viewport')
                left=Image.open(gold/f'guest/popup{stage}.png').convert('RGB');right=Image.open(out/f'guest/popup{stage}.png').convert('RGB')
                old_z=struct.unpack('<4800H',(gold/f'guest/zbuffer{stage}.DATA').read_bytes());new_z=struct.unpack('<4800H',(out/f'guest/zbuffer{stage}.DATA').read_bytes())
                mask_image=Image.new('L',(640,480));draw=ImageDraw.Draw(mask_image);visible=0;occluded=0
                for y in range(max(0,t),min(59,b)+1):
                    for x in range(max(0,l),min(79,r)+1):
                        old=old_z[y*80+x];new=new_z[y*80+x]
                        old_visible=old<=original['popup_z'];new_visible=new<=record['popup_z']
                        if not old_visible and old!=original['ac_z'] or not new_visible and new!=record['ac_z']:raise ValueError('Popup is covered by an unexpected window')
                        if old_visible and new_visible:
                            visible+=64;draw.rectangle((x*8,y*8,x*8+7,y*8+7),fill=255)
                        else:occluded+=64
                if not visible:raise ValueError('No mutually visible popup pixels')
                #Blinking caret belongs to this one derived cell. Its position
                #is compared above; phase is intentionally not a raster oracle.
                caret_cells={original['raster'][:2],record['raster'][:2]}
                for cx,cy in caret_cells:
                    if 0<=cx<80 and 0<=cy<60:draw.rectangle((cx*8,cy*8,cx*8+7,cy*8+7),fill=0)
                for state in [original,record]:
                    mx,my=state['raster'][2:]
                    if l*8<=mx<=(r+1)*8-1 and t*8<=my<=(b+1)*8-1:raise ValueError('Mouse pointer still covers popup viewport')
                visible=sum(mask_image.histogram()[1:])
                mask_image.save(out/f'guest/compared{stage}.png')
                difference=ImageChops.multiply(ImageChops.difference(left,right),mask_image.convert('RGB'))
                if difference.getbbox():report['comparison_errors'].append(f'Visible popup pixels differ at stage {stage}: {difference.getbbox()}')
                report.setdefault('visible_pixels',[]).append(dict(stage=stage,compared=visible,occluded_by_autocomplete=occluded))
            report['cases'].append(dict(stage=stage,rect=record['rect'],state=record['state'],document_sha256=hashlib.sha256(record['document']).hexdigest(),plain_bytes=len(plain)))
            (out/'progress.json').write_text(json.dumps(report['cases'],indent=2)+'\n')
        mark=len(guest.collect());guest.press('esc');guest.wait('ACPU closed\n',30,start=mark)
        if (out/'guest/ACPUClosed.DATA').read_bytes()!=b'RESTORED 31\nINPUT ACNCheck("Appl\n':raise ValueError('Popup did not restore original roles/focus/unfinished input')
        guest.wait('ACPU resumed\n',60,start=mark)
        if (out/'guest/ACPUResumed.DATA').read_bytes()!=b'RESUMED Appl 4 10 Applaud\n':raise ValueError('Parent autocomplete choices were not restored')
        mark=len(guest.collect());guest.key('ctrl',True);guest.press('0');guest.key('ctrl',False);guest.wait('ACN selected\n',30,start=mark)
        if (out/'guest/ACNSelected0.DATA').read_bytes()!=b'ACNCheck("Applaud\n':raise ValueError('Resumed completion failed')
        mark=len(guest.collect());guest.type('");');guest.press('ret');guest.wait('ACN executed\n',30,start=mark)
        if native:guest.wait('COMMAND OK\n',start=mark)
        if (out/'guest/ACNExecuted0.DATA').read_bytes()!=b'EXECUTION 1 INDEX 0 WORD Applaud\n':raise ValueError('Resumed execution differs')
        deadline=time.monotonic()+15
        while True:
            guest.screenshot('executed')
            try:report['result_pixels']=pixel_module['verify'](out/'guest/executed.png',b'Applaud',font);break
            except ValueError:
                if time.monotonic()>=deadline:raise
                time.sleep(.1)
        guest.close();guest=None
        if native:
            build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'));report['filesystem_integrity']=build['verify_mutated_volume'](image)
            names={'/ACPUClosed.DATA','/ACPUResumed.DATA','/ACNPrefix0.DATA','/ACNSelected0.DATA','/ACNExecuted0.DATA'}|{f'/ACPUPopup{stage}.DATA' for stage in range(3)};files=build['mutated_file_contents'](image,names)
            if any(files[name]!=(out/'guest'/name.lstrip('/')).read_bytes() for name in names):raise ValueError('Persisted numeric reports differ from exports')
            report['popup_pixels']='all mutually visible static popup pixels match at three stages; actual autocomplete occlusion and the derived blinking caret cell excluded; pointer moved outside pane'
        if report['comparison_errors']:raise ValueError('; '.join(report['comparison_errors']))
        report['result']='pass'
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        if guest:guest.close()
        report['inputs_unchanged']=all(sha(Path(path))==digest for path,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
