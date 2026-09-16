#!/usr/bin/env python3
"""Check the native keyboard console through emulated hardware and VGA pixels."""
import argparse
import json
from pathlib import Path
import re
import socket
import struct
import subprocess
import time

ROOT=Path(__file__).resolve().parents[1]


def console_pixels(rows):
    #Read the original font, independently of the native framebuffer implementation.
    source=(ROOT/'Kernel/FontStd.HC').read_bytes()
    glyphs=[int(value,16) for value in re.findall(rb'0x[0-9A-Fa-f]{16}',source)]
    if len(glyphs)!=256: raise ValueError('Unexpected TempleOS font')
    font=b''.join(struct.pack('<Q',value) for value in glyphs)
    pixels=bytearray(b'\xff'*(640*480*3))
    if len(rows)>60 or any(len(row)>80 for row in rows): raise ValueError('Invalid expected text grid')
    for row,line in enumerate(rows):
        for column,ch in enumerate(line.encode('cp437')):
            for y in range(8):
                for x in range(8):
                    if font[ch*8+y]&(1<<x):
                        offset=((row*8+y)*640+column*8+x)*3
                        pixels[offset:offset+3]=b'\0\0\0'
    return bytes(pixels)


def run_input(disk,out,startup_check=None,diagnostics=False):
    from PIL import Image
    out=out.resolve(); out.mkdir(parents=True,exist_ok=True)
    (out/'result.json').unlink(missing_ok=True)
    log=out/'debug.log'; log.write_text('')
    qmp=out/'qmp.sock'; qmp.unlink(missing_ok=True)
    cmd=['qemu-system-i386','-machine','pc','-accel','tcg','-cpu','486','-m','8','-nic','none',
         '-drive',f'file={disk.resolve()},format=raw,if=ide','-display','none','-no-reboot',
         '-debugcon',f'file:{log}','-qmp',f'unix:{qmp},server=on,wait=off']
    (out/'command.json').write_text(json.dumps(cmd,indent=2)+'\n')
    sock=socket.socket(socket.AF_UNIX)
    with (out/'qemu.log').open('w') as stderr:
        proc=subprocess.Popen(cmd,stderr=stderr)
        try:
            deadline=time.monotonic()+60
            while not qmp.exists():
                if proc.poll() is not None or time.monotonic()>deadline: raise RuntimeError('No QMP')
                time.sleep(.05)
            sock.connect(str(qmp)); sock.settimeout(5)
            stream=sock.makefile('rwb',buffering=0); json.loads(stream.readline())

            def command(name,**arguments):
                stream.write((json.dumps({'execute':name,'arguments':arguments})+'\n').encode())
                while True:
                    reply=json.loads(stream.readline())
                    if 'error' in reply: raise RuntimeError(reply)
                    if 'return' in reply: return reply['return']

            def wait_for(predicate, timeout=30):
                stop=time.monotonic()+timeout
                while time.monotonic()<stop and proc.poll() is None:
                    if 'FAIL ' in log.read_text(): raise RuntimeError(log.read_text())
                    if predicate(): return
                    time.sleep(.05)
                raise TimeoutError(f'Console check timed out; inspect {out}')

            def key(name,down):
                command('input-send-event',events=[{'type':'key','data':{
                    'down':down,'key':{'type':'qcode','data':name}}}])

            def press(name):
                key(name,True); key(name,False)

            def screen(rows,name):
                expected=console_pixels(rows)
                path=out/f'{name}.ppm'
                def matches():
                    command('screendump',filename=str(path))
                    with Image.open(path) as image:
                        return image.size==(640,480) and image.convert('RGB').tobytes()==expected
                wait_for(matches)
                with Image.open(path) as image: image.save(out/f'{name}.png')

            command('qmp_capabilities')
            startup_started=time.monotonic()
            #Normal interactive boot must not pay for the diagnostic probe suite.
            wait_for(lambda:'DONE native kernel startup\n' in log.read_text(), timeout=180 if diagnostics else 60)
            startup_seconds=time.monotonic()-startup_started
            heading=['TempleOS i386','HolyC console','']
            status='ok' if startup_check is None else startup_check['status']
            evidence=log.read_text()
            if evidence.count('PUBLIC HEADERS ok\n')!=1:
                raise ValueError('Missing public headers before startup')
            if evidence.count('STARTUP source begin\n')!=1 or evidence.count(f'STARTUP source {status}\n')!=1:
                raise ValueError('Missing or repeated native source startup')
            probe_markers=('SOURCE ', 'LEX_SOURCE ', 'MEMORY PROBE ', 'RUNTIME PROBE ',
                           'PROBE MODULE ', 'PROBE RELEASE ', 'PROBE TASK RELEASE ', 'TICK ')
            if diagnostics:
                if not (evidence.index('PROBE RELEASE ') < evidence.index('PROBE TASK RELEASE ') <
                        evidence.index('CONSOLE TASK SPAWNED')):
                    raise ValueError('Diagnostic worker did not finish before console startup')
            elif any(line.startswith(probe_markers) for line in evidence.splitlines()):
                raise ValueError('Normal boot executed diagnostic probes')
            if not (evidence.index('CONSOLE TASK SPAWNED') <
                    evidence.index('STARTUP source begin') < evidence.index(f'STARTUP source {status}') <
                    evidence.index('DONE native kernel startup')):
                raise ValueError('Source startup ran outside the console startup boundary')
            rows=heading+([] if startup_check is None else startup_check['answers'])+['> ']
            screen(rows,'initial')
            plain={'%':'5','#':'3','!':'1','<':'comma','>':'dot',',':'comma',"'":'apostrophe',' ':'spc',';':'semicolon','.':'dot','-':'minus','=':'equal',
                   '/':'slash','(':'9',')':'0','{':'bracket_left','}':'bracket_right',
                   '*':'8','+':'equal','&':'7','_':'minus','[':'bracket_left',']':'bracket_right','"':'apostrophe'}
            shifted=set('(){}*+&_"<>#!%')
            def typed_rows(source):
                text='> '+source
                #The VGA terminal wraps immediately at column 80, including a
                #blank cursor row when the final character exactly fills a row.
                return [text[index:index+80] for index in range(0,len(text)+1,80)]

            def submit(source, answers, name):
                nonlocal rows
                if len(source)>255: raise ValueError('Source exceeds the native input buffer')
                for index,ch in enumerate(source):
                    shift=ch.isupper() or ch in shifted
                    if shift: key('shift',True)
                    press(plain.get(ch,ch.lower()))
                    if shift: key('shift',False)
                    if index%4==3:
                        screen((rows[:-1]+typed_rows(source[:index+1]))[-60:],'command-typing')
                press('ret')
                rows=(rows[:-1]+typed_rows(source)+answers+['> '])[-60:]
                screen(rows,name)
            if startup_check is not None:
                for index,(source,answers) in enumerate(startup_check['commands']):
                    submit(source,answers,f'startup-command-{index:02}')
                result={'result':'pass','cpu':'486','ram_mib':8,'startup_status':status,
                        'boot_mode':'diagnostic' if diagnostics else 'interactive',
                        'startup_seconds':startup_seconds,'commands':len(startup_check['commands']),
                        'vga':'all pixels matched at each checkpoint'}
                (out/'result.json').write_text(json.dumps(result,indent=2)+'\n')
                return result
            def uploads():
                return [int(x.split()[2]) for x in log.read_text().splitlines() if x.startswith('VGA ROWS ')]
            if uploads()!=[60,1]: raise ValueError('Startup must present the heading then the prompt')
            for name in ('a','b','c','backspace'): press(name)
            key('shift',True); press('d'); key('shift',False); press('ret')
            wait_for(lambda:'INPUT LINE abD\n' in log.read_text())
            screen(heading+['> abD','Error: Undefined identifier at ','> '],'edited')
            if uploads()!=[60,1,1,1,1,1,1,2]:
                raise ValueError(f'Unexpected ordinary-edit upload spans: {uploads()}')
            press('y'); press('z'); key('ctrl',True); press('c'); key('ctrl',False)
            wait_for(lambda:'INPUT CANCEL\n' in log.read_text())
            rows=heading+['> abD','Error: Undefined identifier at ','> yz^C','> ']
            screen(rows,'cancelled')
            #Cross a physical text row, then backspace across the wrap boundary.
            for count in range(1,79):
                press('a')
                if count%6==0 or count==78:
                    expected=rows[:-1]+['> '+'a'*count]
                    if count==78: expected+=['']
                    screen(expected,'typing')
            for name in ('z','z','z','backspace','backspace','backspace','backspace','ret'): press(name)
            wait_for(lambda:'INPUT LINE '+'a'*77+'\n' in log.read_text())
            rows=rows[:-1]+['> '+'a'*77,'Error: Undefined identifier at ','> ']
            screen(rows,'wrapped')
            press('tab'); press('b'); press('ret')
            wait_for(lambda:'INPUT LINE '+' '*8+'b\n' in log.read_text())
            rows=rows[:-1]+['> '+' '*8+'b','Error: Undefined identifier at ','> ']
            screen(rows,'tab')
            for count in range(1,61):
                press('ret')
                wait_for(lambda:log.read_text().count('INPUT LINE \n')==count)
            screen(['> ']*60,'scrolled')
            if uploads()[-1]!=60: raise ValueError('Scrolling must invalidate the full screen')
            rows=['> ']*60
            commands=[
                ('GetRFlags&0x200;', ['512']),
                ('U8 *dup=StrNew(0);dup[0]==0&&MHeapCtrl(dup)==Fs->data_heap;', ['1']),
                ('Free(dup);U8 *dup_text=StrNew("VGA",Fs->code_heap);dup_text[0]==86&&dup_text[1]==71&&dup_text[2]==65&&dup_text[3]==0;', ['1']),
                ('U8 *dup2=MAllocIdent(dup_text);dup2!=dup_text&&dup2[0]==86&&dup2[3]==0;', ['1']),
                ('MemSet(dup_text,0x141,3)==dup_text+3&&dup_text[0]==65&&dup_text[2]==65&&dup2[0]==86;', ['1']),
                ('MemCpy(dup_text,dup2,4)==dup_text+4&&dup_text[0]==86&&dup_text[1]==71;', ['1']),
                ('Free(dup_text);Free(dup2);MAllocIdent(0)==0&&MemCpy(0,0,0)==0&&MemSet(0,1,0)==0;', ['1']),

                ('TRUE+FALSE;', ['1']),
                ('NULL(U8 *);', ['0x0']),
                ('6*7;', ['42']),
                ('sizeof(U8 *);', ['4']),
                ('sizeof(I64);', ['8']),
                ('sizeof(CTask);', ['992']),
                ('sizeof(CCPU);', ['232']),
                ('sizeof(CTask.catch_except);', ['1']),
                ('Fs->addr==Fs;', ['1']),
                ('Gs->addr==Gs;', ['1']),
                ('Fs->gs==Gs;', ['1']),
                ('Fs->stk->stk_size>=256;', ['1']),
                ('Fs->data_heap!=0&&Fs->code_heap==Fs->data_heap;', ['1']),
                ('sizeof(CHeapCtrl);', ['1088']),
                ('Fs->data_heap->mem_task==Fs;', ['1']),
                ('U8 *heap_p=CAlloc(64);', []),
                ('heap_p[0]+heap_p[63];', ['0']),
                ('heap_p[63]=42;', ['42']),
                ('Unknown heap_bad;', ['Error: Undefined identifier at ']),
                ('heap_p[63];', ['42']),
                ('MHeapCtrl(heap_p)==Fs->data_heap&&MSize(heap_p)>=64;', ['1']),
                ('MSize2(heap_p)==MSize(heap_p)+12;', ['1']),
                ('Free(heap_p);', []),
                ('I64 MemZero(){U8 *p=MAlloc(0);I64 ok=p!=0&&MSize(p)>=0;Free(p);return ok;}', []),
                ('MemZero;', ['1']),
                ('U0 MemAlign(){heap_p=MAllocAligned(2048,64,Fs,3);}MemAlign;', []),
                ('heap_p(U64)%64;', ['3']),
                ('MSize(heap_p)==MSize(heap_p+heap_p(I64 *)[-1]);', ['1']),
                ('Free(heap_p);Free(0);', []),
                ('I64 MemFail(){I64 ok=0;try{MAlloc(0x800000);}catch{ok=Fs->except_ch==\'OutMem\'&&(GetRFlags&512)!=0;Fs->catch_except=TRUE;}return ok;}', []),
                ('MemFail;', ['1']),
                ('MHeapCtrl(&MemFail)==Fs->code_heap&&MSize(&MemFail)>0;', ['1']),
                ('MAlloc(0x100000000);', ['Out of memory']),
                ('GetRFlags&512;', ['512']),
                ('MAlloc(-1);', ['Out of memory']),
                ('MAllocAligned(64,3);', ['Out of memory']),
                ('MAllocAligned(0xFFFFFFFF,64);', ['Out of memory']),
                ('MemFail;', ['1']),
                ('GetRFlags&512;', ['512']),
                ('GetRSP>=(&Fs->stk->stk_base)(U64);', ['1']),
                ('GetRSP<(&Fs->stk->stk_base)(U64)+Fs->stk->stk_size;', ['1']),
                ('Gs->num;', ['0']),
                ('Fs->task_signature==TASK_SIGNATURE_VAL;', ['1']),
                ('Fs->hash_table->body!=0;', ['1']),
                ('Fs->last_cc!=0;', ['1']),
                ('U0 PubDraw(CTask *t,CDC *d){t->user_data=42;}', []),
                ('I64 PubTest(){CTask t;t.draw_it=&PubDraw;t.draw_it(&t,0);return t.user_data;}', []),
                ('PubTest;', ['42']),
                ('#include "/Kernel/I386/PublicKernel.HH"', []),
                ('PubTest;', ['42']),

                ('extern class Opaque;class Holder{Opaque *p;I64 value;};', []),
                ('sizeof(Holder);', ['12']),
                ('Holder h;h.p=0;h.value=42;', ['0x0','42']),
                ('h.value;', ['42']),
                ('class Opaque{I64 value;};Unknown bad;', ['Error: Undefined identifier at ']),
                ('sizeof(Opaque);', ['0']),
                ('class Opaque{I64 value;};Opaque item;', []),
                ('I64 Attach(){h.p=&item;item.value=42;return h.p->value;}', []),
                ('Attach;', ['42']),
                ('h.p->value;', ['42']),
                ('sizeof(Opaque);', ['8']),
                ('0x100000000+42;', ['4294967338']),
                ('I64 n=40;', []),
                ('I64 Next(){return ++n;}', []),
                ('Next;', ['41']),
                ('Unknown bad;', ['Error: Undefined identifier at ']),
                ('Next;', ['42']),
                ('I64 Count(){static I64 i=9;return ++i;}', []),
                ('Count;', ['10']), ('Count;', ['11']),
                ('U8 *greet="ABC";', []),
                ('greet[1];', ['66']),
                ('greet[1]=90;', ['90']),
                ('U8 *lost="bad";Unknown bad;', ['Error: Undefined identifier at ']),
                ('lost;', ['Error: Undefined identifier at ']),
                ('greet[1];', ['90']),
                ('U8 *lost="ok";', []), ('lost[1];', ['107']),
                ('I64 Letter(){static U8 *s="AZ";return ++s[0];}', []),
                ('Letter;', ['66']), ('Letter;', ['67']),
                ('extern I64 F(I64 x);I64 G(){return F(40);}I64 F(I64 x){return x+2;}', []),
                ('G;', ['42']),
                ('extern I64 Pending();I64 Broken(){return Pending();}', ['Compilation failed']),
                ('G;', ['42']),
                ('StrCmp("abc","abc");', ['0']),
                ('I64 T(){I64 x=0;try{x=42;}catch{}return x;}', []),
                ('T;', ['42']),
                ("throw('Console',TRUE);", ['Exception']),
                ('T;', ['42']),
                ('ToI64(Sqrt(Sqr(6.0))+Abs(-36.0));', ['42']),
                ('ToBool(0x100000000);', ['1']),
                ('GetRFlags&0x200;', ['512']),
                ('SetRFlags(GetRFlags);', []),
                ('1.5+2.25;', ['3.75']),
                ('0x8000000000000000(I64);', ['-9223372036854775808']),
                ('0x8000000000000000;', ['9223372036854775808']),
                ('0xFFFFFFFFFFFFFFFF(U64);', ['18446744073709551615']),
                ('1.0/0.0;', ['Inf']),
                ('0.0/0.0;', ['NaN']),
                ('1(F64);', ['4.9406564584124654e-324']),
                ('0x7FEFFFFFFFFFFFFF(F64);', ['1.7976931348623157e+308']),
                ('0x8000000000000000(F64);', ['-0']),
                ('0(U8 *);', ['0x0']),
                ('0x3FB999999999999A(F64);', ['0.10000000000000001']),
                ('0x3FEFFFFFFFFFFFFF(F64);', ['0.99999999999999989']),
                ('1.0/3.0;', ['0.33333333333333331']),
            ]
            for index,(source,answers) in enumerate(commands):
                submit(source,answers,f'command-{index:02}')
            if 'INPUT RESET' in log.read_text(): raise ValueError('Unexpected keyboard queue loss')
            result={'result':'pass','cpu':'486','ram_mib':8,
                    'boot_mode':'diagnostic' if diagnostics else 'interactive',
                        'startup_seconds':startup_seconds,
                    'vga_uploads':len(uploads()), 'vga_text_rows':sum(uploads()),
                    'vga_payload_bytes':sum(uploads())*2560,
                    'ordinary_edit_payload_bytes':2560,
                    'checks':['make/break','shift','backspace','cancel','wrap','tab','scroll','native compilation','multirow source input','public allocation API','persistent definitions','error recovery','integer and F64 answers'],
                    'vga':'all pixels matched at each checkpoint','submitted_lines':63+len(commands), 'native_commands':len(commands)}
            (out/'result.json').write_text(json.dumps(result,indent=2)+'\n')
            return result
        finally:
            if proc.poll() is None: proc.terminate()
            try: proc.wait(timeout=5)
            except subprocess.TimeoutExpired: proc.kill(); proc.wait()
            sock.close(); qmp.unlink(missing_ok=True)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--diagnostics',action='store_true',help='Expect the diagnostic boot image')
    args=parser.parse_args()
    print(run_input(args.disk,args.out,diagnostics=args.diagnostics))


if __name__=='__main__': main()
