#!/usr/bin/env python3
"""Compare real autocomplete source suggestions and Ctrl+F1 input with the original."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct
import subprocess
import sys
import time
from PIL import Image, ImageChops
ROOT=Path(__file__).resolve().parents[1]

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def prefix_record(data):
    header,body=data.split(b'DOCUMENT ',1);size,document=body.split(b'\n',1)
    if len(document)!=int(size):raise ValueError('Incomplete widget document')
    rows=header.decode().splitlines();words=re.fullmatch(r'SOURCE (\d+) DICTIONARY (\d+)',rows[0]);word=re.fullmatch(r'WORD (\S+) LENGTH (\d+) COUNT (\d+)',rows[1])
    if not words or not word:raise ValueError('Invalid suggestion header')
    rect=tuple(map(int,rows[2].removeprefix('RECT ').split()))
    matches=[]
    for row in rows[3:]:
        match=re.fullmatch(r'MATCH (\S+) HITS (\d+)',row)
        if not match:raise ValueError('Invalid suggestion record')
        matches.append((match[1],int(match[2])))
    return dict(source_words=int(words[1]),dictionary_words=int(words[2]),word=word[1],partial=int(word[2]),count=int(word[3]),rect=rect,matches=matches,document=document)

def expected_matches(project,words):
    counts=Counter(re.findall(rb'[A-Za-z0-9_]+',project));entries=[]
    def bucket(name):
        value=0
        for ch in name:value=((value<<1)+ch+(value>>63))&0xFFFFFFFFFFFFFFFF
        return (value+(value>>16)+((value>>15)&1))&2047
    for serial,(name,hits) in enumerate(counts.items()):
        if name.startswith(b'ACUI'):entries.append((name.decode(),hits,bucket(name),serial))
    pos=0;serial=len(counts)
    while pos<len(words)-1:
        if words[pos]==0:pos+=3;continue
        if words[pos]!=1:raise ValueError('Invalid pinned word-list marker')
        end=words.index(0,pos+1);name=words[pos+1:end].upper()
        if name.startswith(b'ACUI'):entries.append((name.decode(),0,bucket(name),serial))
        pos=end+3;serial+=1
    entries.sort(key=lambda item:(-item[1],item[2],-item[3]))
    return counts,[(name,hits) for name,hits,_,_ in entries[:10]]

def has_result_pixels(path):
    font=b''.join(struct.pack('<Q',int(value,16)) for value in re.findall(rb'0x[0-9A-Fa-f]{16}',(ROOT/'Kernel/FontStd.HC').read_bytes()))
    if len(font)!=2048:raise ValueError('Unexpected font size')
    pixels=Image.open(path).convert('RGB').load()
    for row in range(1,60):
        for col in range(49):
            ink=set();matched=True
            for n,ch in enumerate(b'42'):
                for y in range(8):
                    for x in range(8):
                        color=pixels[(col+n)*8+x,row*8+y];bit=bool(font[ch*8+y]&(1<<x))
                        if bit:
                            if color==(255,255,255):matched=False
                            ink.add(color)
                        elif color!=(255,255,255):matched=False
            if matched and len(ink)==1:return dict(column=col,row=row,foreground=list(next(iter(ink))))
    return False

class Guest:
    def __init__(self,image,out,native):
        self.out=out;out.mkdir();self.log=out/'debug.log';self.log.write_text('');self.seen=set()
        common=['-nic','none','-display','none','-no-reboot','-debugcon',f'file:{self.log}','-qmp','stdio']
        if native:cmd=['qemu-system-i386','-machine','pc','-accel','kvm','-cpu','486,-fpu','-m','64','-drive',f'file={image},format=raw,if=ide']+common
        else:cmd=['qemu-system-x86_64','-machine','pc','-accel','tcg','-cpu','max','-m','2048','-smp','2','-drive',f'file={image},format=raw,media=cdrom,if=ide,index=2','-boot','d']+common
        (out/'command.json').write_text(json.dumps(cmd,indent=2)+'\n')
        self.stderr=(out/'qemu.log').open('w');self.p=subprocess.Popen(cmd,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=self.stderr,text=True,bufsize=1)
        json.loads(self.p.stdout.readline());self.call('qmp_capabilities');self.delay=.15 if native else .04
        helper=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'));self.plain=helper['PLAIN'];self.shifted=helper['SHIFTED']
    def call(self,name,**args):
        self.p.stdin.write(json.dumps({'execute':name,'arguments':args})+'\n');self.p.stdin.flush()
        while True:
            line=self.p.stdout.readline()
            if not line:raise RuntimeError('QEMU closed QMP')
            reply=json.loads(line)
            if 'error' in reply:raise RuntimeError(str(reply))
            if 'return' in reply:return reply['return']
    def collect(self):
        text=self.log.read_text(errors='replace')
        for line in text.splitlines():
            if line.startswith('EXPORT ') and line not in self.seen:
                _,name,address,size=line.split()
                if Path(name).name!=name:raise ValueError('Invalid export filename')
                self.call('pmemsave',val=int(address,16),size=int(size,16),filename=str(self.out/name));self.seen.add(line)
        return text
    def wait(self,needle,timeout=180,start=0):
        deadline=time.monotonic()+timeout
        while self.p.poll() is None and time.monotonic()<deadline:
            text=self.collect()
            if needle in text[start:]:return text
            if 'INPUT REJECT ' in text[start:] or '\nFAIL ' in text[start:]:raise ValueError(text[start:][-1000:])
            time.sleep(.1)
        raise TimeoutError('Missing guest marker: '+needle)
    def key(self,name,down):self.call('input-send-event',events=[{'type':'key','data':{'down':down,'key':{'type':'qcode','data':name}}}])
    def press(self,name):self.key(name,True);time.sleep(.04);self.key(name,False)
    def type(self,text):
        for ch in text:
            shift=ch.isupper() or ch in self.shifted
            if shift:self.key('shift',True)
            self.press(self.plain.get(ch,ch.lower()))
            if shift:self.key('shift',False)
            time.sleep(self.delay)
    def command(self,text,timeout=180):
        start=len(self.collect());self.type(text);self.press('ret');self.wait('COMMAND OK\n',timeout,start);time.sleep(1)
    def screenshot(self,name):
        path=self.out/(name+'.ppm');self.call('screendump',filename=str(path));Image.open(path).save(self.out/(name+'.png'))
    def result_pixels(self,timeout=15):
        deadline=time.monotonic()+timeout
        while time.monotonic()<deadline:
            self.screenshot('executed');match=has_result_pixels(self.out/'executed.png')
            if match:return match
            time.sleep(.1)
        raise TimeoutError('Executed result 42 is missing from console pixels')
    def close(self):
        if self.p.poll() is None:
            try:self.screenshot('final');self.call('quit')
            finally:
                if self.p.poll() is None:self.p.terminate()
        self.p.wait(timeout=15);self.stderr.close()

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();out=args.out.resolve();native=args.disk is not None
    if out.exists():ap.error('Use a fresh output directory')
    if native and not args.reference:ap.error('Native run needs --reference')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-autocomplete-interaction/Contract.HC';project=fixture.with_name('Project.HC');archive=ROOT/'build/i386-autocomplete-archive-original/guest/ACWords.DATA.Z'
    paths=[Path(__file__).resolve(),fixture,project,archive,ROOT/'docs/i386-compatibility-inventory.json']+[ROOT/p for p in ['tools/build-iso.py','tools/guest-run.py','tools/package-i386-native-image.py','tools/build-i386-kernel.py','tools/test-i386-timeclock-welcome.py','Kernel/FontStd.HC','Adam/AutoComplete/MakeAC.HC','Adam/AutoComplete/ACFill.HC','Adam/AutoComplete/ACTask.HC','Adam/AutoComplete/ACInit.HC','Adam/AutoComplete/ACWords.DATA','Adam/AutoComplete/ACDefs.DATA']]
    paths += [ROOT/name for name in ['Adam/DolDoc/DocPutKey.HC','Adam/DolDoc/DocAutoCompleteActionCore.HC','Kernel/I386/DocumentRuntime.HC','Kernel/I386/ConsoleRuntime.HC']]
    for source,name in [(Path(__file__).resolve(),'runner-source.py'),(fixture,'fixture.HC'),(project,'project.HC')]:
        snapshot=out/name;snapshot.write_bytes(source.read_bytes());paths.append(snapshot)
    inventory=json.loads((ROOT/'docs/i386-compatibility-inventory.json').read_text())
    originals={entry['path']:entry['reference_sha256'] for entry in inventory['entries'] if entry['path'] in {str(path.relative_to(ROOT)) for path in paths if path.is_relative_to(ROOT/'Adam/AutoComplete')}}
    if len(originals)!=6 or any(sha(ROOT/name)!=digest for name,digest in originals.items()):raise ValueError('Autocomplete inputs differ from pinned original')
    archive_report=archive.parents[1]/'result.json';paths.append(archive_report);compressed=json.loads(archive_report.read_text())
    if compressed.get('result')!='pass' or not compressed.get('inputs_unchanged') or compressed.get('archive_sha256')!=sha(archive):raise ValueError('Qualified word archive required')
    if native:
        image=out/'working.img';paths.append(args.disk.resolve());gold=args.reference.resolve();paths += [gold/'result.json',gold/'guest/ACUIPrefix.DATA',gold/'guest/prefix.png']
        golden=json.loads((gold/'result.json').read_text())
        if golden.get('result')!='pass' or not golden.get('inputs_unchanged'):raise ValueError('Passed original interaction reference required')
    else:
        image=out/'original.iso';manifest=ROOT/'build/rebuild-test/result.json';paths.append(manifest);bootstrap=json.loads(manifest.read_text())
        if bootstrap.get('result')!='pass':raise ValueError('Qualified original rebuild required')
        for name,relative in [('Kernel.BIN','0000Boot/0000Kernel.BIN.C'),('Compiler.BIN','Compiler/Compiler.BIN')]:
            path=ROOT/'build/rebuild-test/overlay'/relative
            if sha(path)!=bootstrap['generations'][-1][name]:raise ValueError('Stale original binary')
            paths.append(path)
    pins={str(p):sha(p) for p in paths};report=dict(result='running',mode='native' if native else 'rebuilt-original',input_sha256=pins,scope='Actual ACInit project traversal and full dictionary, visible source prefix choices, Ctrl+F1 through real keyboard and input queue, completed symbol execution. Not all autocomplete keys, popup definitions, exact app heap recovery or full desktop qualification.')
    guest=None
    try:
        additions={'/ACUIProject.HC':project.read_bytes(),'/ACUIContract.HC':fixture.read_bytes(),'/Adam/AutoComplete/ACWords.DATA.Z':archive.read_bytes()}
        if native:
            packer=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));report['packaging']=packer['package'](args.disk.resolve(),image,additions=additions,addition_attributes={'/Adam/AutoComplete/ACWords.DATA.Z':0xC00})
        else:
            overlay=out/'overlay'
            for name,data in additions.items():p=overlay/name.lstrip('/');p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
            (overlay/'Once.HC').write_text('while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\nAdamFile("T:/ACUIProject.HC",FALSE);\nAdamFile("T:/ACUIContract.HC",FALSE);\nAdam("ACUIStart;");\nTaskWait(sys_focus_task,TRUE);\nAdam("ACUIArm(sys_focus_task);");\n')
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay','build/rebuild-test/overlay','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        guest=Guest(image,out/'guest',native)
        if native:
            guest.wait('DONE native kernel startup\n');time.sleep(3)
            for command in ['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/ACUIProject.HC",FALSE);','AdamFile("C:/ACUIContract.HC",FALSE);','Adam("ACUIStart(TRUE);");','ACUIArm(Fs);']:guest.command(command,1800)
        else:guest.wait('ACUI armed\n',600);time.sleep(2)
        guest.type('ACUI');guest.wait('ACUI prefix ready\n',45);time.sleep(1);guest.screenshot('prefix')
        record=prefix_record((out/'guest/ACUIPrefix.DATA').read_bytes());report['prefix']={k:v for k,v in record.items() if k!='document'}
        guest.key('ctrl',True);guest.press('f1');guest.key('ctrl',False)
        guest.wait('ACUI selected\n',30);guest.screenshot('selected');guest.type(';');guest.press('ret');guest.wait('ACUI executed\n',30)
        report['result_pixels']=guest.result_pixels()
        guest.close();guest=None
        counts,expected=expected_matches(project.read_bytes(),(ROOT/'Adam/AutoComplete/ACWords.DATA').read_bytes())
        if record['source_words']!=len(counts) or record['dictionary_words']!=95293 or record['word']!='ACUI' or record['partial']!=4 or record['count']!=len(expected) or record['matches']!=expected:raise ValueError('Suggestions differ from independent project token counts')
        if (out/'guest/ACUISelected.DATA').read_bytes()!=b'SELECTED ACUIAlpha\n':raise ValueError('Incorrect completed input')
        if native:
            original=prefix_record((gold/'guest/ACUIPrefix.DATA').read_bytes())
            if record['rect']!=original['rect'] or record['document'].replace(b'C:/ACUIProject.HC',b'T:/ACUIProject.HC')!=original['document']:raise ValueError('Widget geometry/document differs from original')
            l,r,t,b=record['rect'];crop=(max(0,l*8),max(0,t*8),min(640,(r+1)*8),min(480,(b+1)*8))
            if crop[0]>=crop[2] or crop[1]>=crop[3]:raise ValueError('Empty autocomplete viewport')
            left=Image.open(gold/'guest/prefix.png').convert('RGB').crop(crop);right=Image.open(out/'guest/prefix.png').convert('RGB').crop(crop)
            if ImageChops.difference(left,right).getbbox():raise ValueError('Autocomplete viewport pixels differ')
            report['widget_pixels']='all viewport pixels matched original'
            build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'));report['filesystem_integrity']=build['verify_mutated_volume'](image)
            files=build['mutated_file_contents'](image,{'/ACUIPrefix.DATA','/ACUISelected.DATA'})
            if any(files['/'+name]!=(out/'guest'/name).read_bytes() for name in ['ACUIPrefix.DATA','ACUISelected.DATA']):raise ValueError('Persisted UI reports differ')
        report.update(result='pass',expected_matches=expected,prefix_sha256=sha(out/'guest/ACUIPrefix.DATA'))
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        if guest:guest.close()
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
