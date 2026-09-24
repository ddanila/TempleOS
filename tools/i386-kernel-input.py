#!/usr/bin/env python3
"""Check the native keyboard console through emulated hardware and VGA pixels."""
import argparse
import json
import hashlib
from pathlib import Path
import re
import socket
import struct
import subprocess
import time

ROOT=Path(__file__).resolve().parents[1]


def console_pixels(rows, foreground_cells=None, background_cells=None, underline_cells=None,
                   pixel_colors=None, pointer=None):
    #Read the original font, independently of the native framebuffer implementation.
    source=(ROOT/'Kernel/FontStd.HC').read_bytes()
    glyphs=[int(value,16) for value in re.findall(rb'0x[0-9A-Fa-f]{16}',source)]
    if len(glyphs)!=256: raise ValueError('Unexpected TempleOS font')
    font=b''.join(struct.pack('<Q',value) for value in glyphs)
    pixels=bytearray(b'\xff'*(640*480*3))
    if len(rows)>60 or any(len(row)>80 for row in rows): raise ValueError('Invalid expected text grid')
    foreground_cells=foreground_cells or {}
    background_cells=background_cells or {}
    underline_cells=underline_cells or set()
    pixel_colors=pixel_colors or {}
    palette=[]
    for color in range(16):
        red=42 if color&4 else 0
        green=42 if color&2 else 0
        blue=42 if color&1 else 0
        if color&8: red+=21; green+=21; blue+=21
        if color==6: green=21
        #QEMU exposes the programmed six-bit VGA DAC channels as value<<2.
        palette.append(bytes((255 if red==63 else red<<2,
                              255 if green==63 else green<<2,
                              255 if blue==63 else blue<<2)))
    for row,line in enumerate(rows):
        for column,ch in enumerate(line.encode('cp437')):
            foreground=palette[foreground_cells.get((row,column),0)]
            background=palette[background_cells[(row,column)]] if (row,column) in background_cells else b'\xff\xff\xff'
            for y in range(8):
                for x in range(8):
                    offset=((row*8+y)*640+column*8+x)*3
                    if font[ch*8+y]&(1<<x) or (row,column) in underline_cells and y==7:
                        pixels[offset:offset+3]=foreground
                    else: pixels[offset:offset+3]=background
    for (x,y),color in pixel_colors.items():
        if not (0<=x<640 and 0<=y<480 and 0<=color<16):
            raise ValueError('Invalid expected graphics pixel')
        offset=(y*640+x)*3; pixels[offset:offset+3]=palette[color]
    if pointer is not None:
        pointer_x,pointer_y=pointer
        masks=(0x01,0x03,0x07,0x0f,0x1f,0x3f,0x0f,0x1b,0x31,0x20)
        palette_index={value:index for index,value in enumerate(palette)}
        for row,mask in enumerate(masks):
            for column in range(8):
                x=pointer_x+column; y=pointer_y+row
                if mask&(1<<column) and 0<=x<640 and 0<=y<480:
                    offset=(y*640+x)*3
                    color=palette_index[bytes(pixels[offset:offset+3])]^15
                    pixels[offset:offset+3]=palette[color]
    return bytes(pixels)


GROUPS=('keyboard','mouse','sound','windows','graphics','date','math','definitions','text-frames',
        'compiler','breaks','documents','file-navigation','document-editing','document-resources','document-latency',
        'document-sprites','document-compatibility','help','text')


class MutationDetected(AssertionError):
    """The unchanged assertion observed the specified faulty result on VGA."""


def run_input(disk,out,startup_check=None,diagnostics=False,groups=None,mutation=None,snapshot=True,cpu='486'):
    from PIL import Image
    if groups is not None and (not groups or set(groups)-set(GROUPS)):
        raise ValueError('Select one or more known test groups')
    if startup_check is not None and (groups is not None or mutation is not None):
        raise ValueError('Startup checks cannot be combined with groups or mutations')
    active_group=None
    submitted=0
    interaction_latencies={}
    mouse_host_x=320
    mouse_host_y=240
    out=out.resolve(); out.mkdir(parents=True,exist_ok=True)
    (out/'result.json').unlink(missing_ok=True)
    log=out/'debug.log'; log.write_text('')
    qmp=out/'qmp.sock'; qmp.unlink(missing_ok=True)
    cmd=['qemu-system-i386','-machine','pc','-accel','tcg','-cpu',cpu,'-m','8','-nic','none',
         '-drive',f'file={disk.resolve()},format=raw,if=ide']
    if snapshot: cmd+=['-snapshot']
    cmd += ['-display','none','-no-reboot',
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

            def screen(rows,name,timeout=30,rejected_rows=None,colors=None,backgrounds=None,underlines=None,pixels=None,pointer=None):
                expected=console_pixels(rows,colors,backgrounds,underlines,pixels,pointer)
                rejected=console_pixels(rejected_rows) if rejected_rows is not None else None
                path=out/f'{name}.ppm'
                def matches():
                    command('screendump',filename=str(path))
                    with Image.open(path) as image:
                        pixels=image.convert('RGB').tobytes()
                        if image.size==(640,480) and rejected is not None and pixels==rejected:
                            image.save(out/f'{name}-detected.png')
                            raise MutationDetected(f'{name}: observed injected faulty answer')
                        return image.size==(640,480) and pixels==expected
                wait_for(matches,timeout=timeout)
                with Image.open(path) as image: image.save(out/f'{name}.png')

            command('qmp_capabilities')
            startup_started=time.monotonic()
            #Normal interactive boot must not pay for the diagnostic probe suite.
            wait_for(lambda:'DONE native kernel startup\n' in log.read_text(), timeout=1200 if diagnostics else 60)
            startup_seconds=time.monotonic()-startup_started
            heading=['TempleOS i386','HolyC console','']
            status='ok' if startup_check is None else startup_check['status']
            evidence=log.read_text()
            if evidence.count('PUBLIC HEADERS ok\n')!=1:
                raise ValueError('Missing public headers before startup')
            if evidence.count('STARTUP source begin\n')!=1 or evidence.count(f'STARTUP source {status}\n')!=1:
                raise ValueError('Missing or repeated native source startup')
            probe_markers=('PUBLIC MATH REBIND CHECK', 'SOURCE ', 'LEX_SOURCE ', 'MEMORY PROBE ', 'STRING COPY PROBE ', 'RUNTIME PROBE ',
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
            plain={'\\':'backslash','|':'backslash','~':'grave_accent','%':'5','#':'3','!':'1','<':'comma','>':'dot',',':'comma',"'":'apostrophe',' ':'spc',';':'semicolon','.':'dot','-':'minus','=':'equal',
                   '/':'slash','(':'9',')':'0','{':'bracket_left','}':'bracket_right',
                   '*':'8','+':'equal','&':'7','_':'minus','[':'bracket_left',']':'bracket_right','"':'apostrophe'}
            shifted=set('(){}*+&_"<>#!%|~:')
            plain[':']='semicolon'
            def typed_rows(source):
                text='> '+source
                #The VGA terminal wraps immediately at column 80, including a
                #blank cursor row when the final character exactly fills a row.
                return [text[index:index+80] for index in range(0,len(text)+1,80)]

            def submit(source, answers, name, hotkey=False, frame=None, timeout=30,
                       interaction=None):
                nonlocal rows,submitted,mouse_host_x,mouse_host_y
                if groups is not None and active_group is not None and active_group not in groups:
                    return
                submitted+=1
                (out/'checkpoint.json').write_text(json.dumps({'group':active_group,'name':name,'source':source})+'\n')
                if len(source)>255: raise ValueError('Source exceeds the native input buffer')
                for index,ch in enumerate(source):
                    shift=ch.isupper() or ch in shifted
                    if shift: key('shift',True)
                    press(plain.get(ch,ch.lower()))
                    if shift: key('shift',False)
                    if index%4==3:
                        screen((rows[:-1]+typed_rows(source[:index+1]))[-60:],'command-typing')
                marks=log.read_text().count('@')
                press('ret')
                if interaction is not None:
                    wait_for(lambda:interaction['begin'] in log.read_text(),timeout=timeout)
                    screen(interaction['initial_rows'],name+'-initial',timeout=timeout,
                           colors=interaction.get('initial_colors'),
                           backgrounds=interaction.get('initial_backgrounds'),
                           underlines=interaction.get('initial_underlines'),
                           pixels=interaction.get('initial_pixels'))
                    interaction_marks={}
                    latency_started=None
                    latency_name=None
                    for action in interaction['events']:
                        if 'measure_latency' in action:
                            latency_started=time.monotonic()
                            latency_name=action['measure_latency']
                        if 'mark_log' in action:
                            interaction_marks[action['mark_log']]=log.read_text().count(action['mark_log'])
                        elif 'wait_log_after' in action:
                            marker=action['wait_log_after']
                            wait_for(lambda:log.read_text().count(marker)>interaction_marks[marker],timeout=timeout)
                        elif 'wait_log' in action:
                            wait_for(lambda:action['wait_log'] in log.read_text(),timeout=timeout)
                        elif 'expect_rows' in action:
                            screen(action['expect_rows'],name+'-'+action.get('label','checkpoint'),timeout=timeout,
                                   colors=action.get('colors'),backgrounds=action.get('backgrounds'),
                                   underlines=action.get('underlines'),pixels=action.get('pixels'),
                                   pointer=action.get('pointer'))
                            if latency_started is not None:
                                interaction_latencies[latency_name]=time.monotonic()-latency_started
                                if interaction_latencies[latency_name]>interaction.get('latency_budget_seconds',1.0):
                                    raise ValueError(f'{latency_name} exceeded visible-update budget')
                                latency_started=None; latency_name=None
                        elif action.get('hotkey')=='break':
                            key('ctrl',True); key('alt',True); press('c');
                            key('alt',False); key('ctrl',False)
                        elif 'ctrl_key' in action:
                            key('ctrl',True)
                            if action.get('shift'): key('shift',True)
                            press(action['ctrl_key'])
                            if action.get('shift'): key('shift',False)
                            key('ctrl',False)
                        elif 'shift_key' in action:
                            key('shift',True); press(action['shift_key']); key('shift',False)
                        elif 'alt_key' in action:
                            key('alt',True); press(action['alt_key']); key('alt',False)
                        elif 'delay' in action:
                            time.sleep(action['delay'])
                        elif 'mouse_to' in action:
                            target_x,target_y=action['mouse_to']
                            command('input-send-event',events=[
                                {'type':'rel','data':{'axis':'x','value':target_x-mouse_host_x}},
                                {'type':'rel','data':{'axis':'y','value':target_y-mouse_host_y}}])
                            mouse_host_x=target_x; mouse_host_y=target_y
                        elif 'mouse_rel' in action:
                            delta_x,delta_y=action['mouse_rel']
                            command('input-send-event',events=[
                                {'type':'rel','data':{'axis':'x','value':delta_x}},
                                {'type':'rel','data':{'axis':'y','value':delta_y}}])
                        elif 'mouse_button' in action:
                            command('input-send-event',events=[{'type':'btn','data':{
                                'down':action.get('down',True),'button':action['mouse_button']}}])
                        elif 'text' in action:
                            for ch in action['text']:
                                shift=ch.isupper() or ch in shifted
                                if shift: key('shift',True)
                                press(plain.get(ch,ch.lower()))
                                if shift: key('shift',False)
                        else:
                            press(action['key'])
                    screen(interaction['final_rows'],name+'-edited',timeout=timeout,
                           colors=interaction.get('final_colors'),
                           backgrounds=interaction.get('final_backgrounds'),
                           underlines=interaction.get('final_underlines'),
                           pixels=interaction.get('final_pixels'),
                           pointer=interaction.get('final_pointer'))
                    if latency_started is not None:
                        interaction_latencies[latency_name]=time.monotonic()-latency_started
                        if interaction_latencies[latency_name]>interaction.get('latency_budget_seconds',1.0):
                            raise ValueError(f'{latency_name} exceeded visible-update budget')
                    if interaction.get('exit_hotkey'):
                        key('ctrl',True); key('alt',True); press('c')
                        key('alt',False); key('ctrl',False)
                    elif interaction.get('exit_shift'):
                        key('shift',True); press('esc'); key('shift',False)
                    elif interaction.get('exit_key'):
                        press(interaction['exit_key'])
                    else: press('esc')
                    wait_for(lambda:interaction['end'] in log.read_text(),timeout=timeout)
                if hotkey:
                    wait_for(lambda:log.read_text().count('@')>marks)
                    if frame is not None:
                        import runpy
                        if isinstance(frame,tuple):
                            expected=runpy.run_path(str(ROOT/'tools/i386-graphics-frame.py'))['graphics_frame_pixels'](frame[1])
                        else:
                            expected=runpy.run_path(str(ROOT/'tools/i386-text-frame.py'))['text_frame_pixels'](frame)
                        path=out/f'{name}-frame.ppm'
                        def frame_matches():
                            command('screendump',filename=str(path))
                            with Image.open(path) as image:
                                return image.size==(640,480) and image.convert('RGB').tobytes()==expected
                        wait_for(frame_matches)
                        with Image.open(path) as image: image.save(out/f'{name}-frame.png')
                    key('ctrl',True); key('alt',True); press('c'); key('alt',False); key('ctrl',False)
                rejected_rows=None
                if mutation is not None and name==mutation['checkpoint']:
                    rejected_rows=(rows[:-1]+typed_rows(source)+mutation['answers']+['> '])[-60:]
                if interaction is not None:
                    rows=(heading+answers+['> '])[-60:]
                else:
                    rows=(rows[:-1]+typed_rows(source)+answers+['> '])[-60:]
                screen(rows,name,timeout=timeout,rejected_rows=rejected_rows)
            if startup_check is not None:
                for index,command_spec in enumerate(startup_check['commands']):
                    source,answers=command_spec[:2]
                    interaction=command_spec[2] if len(command_spec)>2 else None
                    submit(source,answers,f'startup-command-{index:02}',
                           timeout=startup_check.get('command_timeout',30),interaction=interaction)
                result={'result':'pass','cpu':cpu,'ram_mib':8,'startup_status':status,
                        'boot_mode':'diagnostic' if diagnostics else 'interactive',
                        'startup_seconds':startup_seconds,'commands':len(startup_check['commands']),
                        'vga':'all pixels matched at each checkpoint',
                        'interaction_latencies_seconds':interaction_latencies}
                (out/'result.json').write_text(json.dumps(result,indent=2)+'\n')
                return result
            def uploads():
                return [int(x.split()[2]) for x in log.read_text().splitlines() if x.startswith('VGA ROWS ')]
            if mutation is not None:
                submit(mutation['source'],['1'],'mutation-installed')
            active_group='keyboard'
            if groups is None or 'keyboard' in groups:
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
                ('CQue queue;sizeof(CQue)==8&&(queue.next=&queue)==&queue&&(queue.last=&queue)==queue.next;', ['1']),
                ('CQue *queue_identity=&queue;queue_identity==&queue&&offset(CQue.last)==4;', ['1']),
                ('CQue queue_item;QueInit(&queue);QueInsRev(&queue_item,&queue);queue.next==&queue_item&&queue_item.last==&queue;', ['1']),
                ('QueRem(&queue_item);queue.next==&queue&&queue.last==&queue&&queue_item.next==&queue;', ['1']),

                ('sizeof(CDoc)==680&&sizeof(CDocEntry)==160&&offset(CDocBin.end)-offset(CDocBin.start)==16;', ['1']),
                ('Fs->next_task->last_task==Fs&&Fs->last_task->next_task==Fs&&Fs->next_task!=Fs;', ['1']),
                ('JIFFY_FREQ==1000&&cnts.jiffies>0;', ['1']),
                ('I64 equ_bits=0;', []),
                ('LBEqu(&equ_bits,35,TRUE)==0&&equ_bits==0x800000000;', ['1']),
                ('BEqu(&equ_bits,35,TRUE)==1&&BEqu(&equ_bits,35,FALSE)==1&&equ_bits==0;', ['1']),
                ('StrLen("");', ['0']),
                ('StrLen("VGA")+StrLen("adapter"+2);', ['8']),
                ('U8 *copy_buf=CAlloc(8);StrCpy(copy_buf+1,"VGA");StrLen(copy_buf+1)==3&&copy_buf[0]==0&&copy_buf[5]==0;', ['1']),
                ('StrCpy(0,1);StrCpy(copy_buf+1,0);copy_buf[1]==0&&copy_buf[2]==71;', ['1']),
                ('Free(copy_buf);', []),
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
                ('Fs->task_flags|=1<<TASKf_PENDING_BREAK;', ['Exception']),
                ('Bt(&Fs->task_flags,TASKf_PENDING_BREAK);', ['0']),
                ('I64 BreakPrivate(){return 99;} Fs->task_flags|=1<<TASKf_PENDING_BREAK;', ['Exception']),
                ('BreakPrivate;', ['Error: Undefined identifier at ']),
                ('U0 LockPending(){Fs->task_flags|=1<<TASKf_BREAK_LOCKED|1<<TASKf_PENDING_BREAK;}', []),
                ('LockPending;', []),
                ('Fs->task_flags&=~(1<<TASKf_BREAK_LOCKED);', ['Exception']),
                ('Bt(&Fs->task_flags,TASKf_PENDING_BREAK);', ['0']),
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
            active_group='mouse'
            submit('I64 mouse_x,mouse_y,mouse_buttons,mouse_packets;MouseGet(&mouse_x,&mouse_y,&mouse_buttons,&mouse_packets)&&mouse_x==320&&mouse_y==240&&mouse_buttons==0&&mouse_packets==0;', ['1'], 'mouse-initial')
            if groups is None or 'mouse' in groups:
                console_pointer_marks=log.read_text().count('CONSOLE mouse pointer\n')
                command('input-send-event',events=[
                    {'type':'rel','data':{'axis':'x','value':24}},
                    {'type':'rel','data':{'axis':'y','value':16}}])
                mouse_host_x+=24; mouse_host_y+=16
                wait_for(lambda:log.read_text().count('CONSOLE mouse pointer\n')>console_pointer_marks)
                screen(rows,'mouse-console-pointer',pointer=[mouse_host_x,mouse_host_y])
            submit('MouseGet(&mouse_x,&mouse_y,&mouse_buttons,&mouse_packets)&&mouse_x>320&&mouse_y>240&&mouse_packets>0;', ['1'], 'mouse-motion')
            if groups is None or 'mouse' in groups:
                command('input-send-event',events=[{'type':'btn','data':{'down':True,'button':'left'}}])
            submit('MouseGet(&mouse_x,&mouse_y,&mouse_buttons,&mouse_packets)&&(mouse_buttons&1);', ['1'], 'mouse-left-down')
            if groups is None or 'mouse' in groups:
                command('input-send-event',events=[{'type':'btn','data':{'down':False,'button':'left'}}])
            submit('MouseGet(&mouse_x,&mouse_y,&mouse_buttons,&mouse_packets)&&!(mouse_buttons&1);', ['1'], 'mouse-left-up')
            active_group='sound'
            submit('I64 SndProbe(){I64 flags=GetRFlags,lo,hi,period;Snd(60);OutU8(0x43,0x80);lo=InU8(0x42);hi=InU8(0x42);period=lo+(hi<<8);return period>=2400&&period<=2712&&(InU8(0x61)&3)==3&&(GetRFlags&512)==(flags&512);}SndProbe;', ['1'], 'speaker-on')
            submit('I64 SndOffProbe(){I64 flags=GetRFlags;Snd;return (InU8(0x61)&3)==0&&(GetRFlags&512)==(flags&512);}SndOffProbe;', ['1'], 'speaker-off')
            submit('Snd(72);SndRst;(InU8(0x61)&3)==0;', ['1'], 'speaker-reset')
            active_group='windows'
            submit('#include "/Kernel/I386/WindowServiceCheck.HC"', [], 'window-service-source')
            submit('WindowServiceCheck;', ['14'], 'window-service-check')
            submit('#include "/Kernel/I386/WindowVisibilityCheck.HC"', [], 'window-visibility-source')
            submit('WindowVisibilityCheck(Fs);', ['6'], 'window-visibility-check')
            submit('#include "/Kernel/I386/WindowTextCheck.HC"', [], 'window-text-source')
            submit('WindowTextCheck;', ['10'], 'window-text-check')
            submit('Fs->win_width==80 && Fs->win_height==60 && Fs->pix_width==640 && Fs->pix_height==480;', ['1'], 'console-viewport')
            active_group='graphics'
            submit('#include "/Kernel/I386/GraphicsAllocationCheck.HC"', [], 'graphics-allocation-source')
            submit('GraphicsAllocationCheck;', ['2'], 'graphics-allocation-check')
            submit('#include "/Kernel/I386/GraphicsFrameCheck.HC"', [], 'graphics-frame-source')
            submit('GraphicsFrameCheck;', ['5'], 'graphics-frame-check')
            submit('#include "/Kernel/I386/GraphicsFrameDemo.HC"', [], 'graphics-frame-definition', timeout=120)
            for mode in range(4):
                submit(f'GraphicsFrameDemo({mode});', ['1'], f'graphics-frame-{mode}', hotkey=True, frame=('graphics',mode))
            submit('#include "/Kernel/I386/GraphicsContextCheck.HC"', [], 'graphics-context-source', timeout=120)
            submit('GraphicsContextCheck;', ['20'], 'graphics-context-check')
            active_group='date'
            submit('#include "/Kernel/I386/DateCheck.HC"', [], 'date-source', timeout=120)
            submit('DateCheck;', ['1333'], 'date-check')
            active_group='math'
            submit('#include "/Kernel/I386/PublicMathCheck.HC"', [], 'public-math-source', timeout=120)
            submit('PublicMathCheck;', ['4107'], 'public-math-check')
            submit('HashFind("_ROUND",Fs->hash_table,HTT_EXPORT_SYS_SYM)!=0&&HashFind("_ROUND",Fs->hash_table,HTT_EXPORT_SYS_SYM,2)==0;', ['1'], 'public-math-single-binding')
            active_group='definitions'
            submit('#include "/Kernel/I386/DefineLookupCheck.HC"', [], 'definition-lookup-source')
            submit('I64 LookupReclaim(){I64 n=Fs->data_heap->used_u8s,r=DefineLookupCheck;if(Fs->data_heap->used_u8s!=n)return -17;return r;}', [], 'definition-lookup-reclaim')
            submit('LookupReclaim;', ['16'], 'definition-lookup-check')
            for kind in range(4):
                submit(f'DefineMissingCheck({kind},TRUE);', ["ERROR: Undefined Define: 'Missing%sLookup'.", '1'], f'definition-missing-{kind}')
            active_group='text-frames'
            submit('#include "/Kernel/I386/TextFrameDemo.HC"', [], 'text-frame-definition')
            for mode in range(4):
                submit(f'TextFrameDemo({mode});', ['1'], f'text-frame-{mode}', hotkey=True, frame=mode)
            active_group='compiler'
            for index,(source,answers) in enumerate(commands):
                submit(source,answers,f'command-{index:02}')
            active_group='breaks'
            submit("U0 HotkeyWait(I64 locked){if(locked) Fs->task_flags|=1<<TASKf_BREAK_LOCKED;OutU8(0xE9,64);while(!Bt(&Fs->task_flags,TASKf_PENDING_BREAK)){}}", [], 'hotkey-definition')
            submit('HotkeyWait(0);', ['Exception'], 'hotkey-break', hotkey=True)
            submit('HotkeyWait(1);', [], 'hotkey-locked', hotkey=True)
            submit('Fs->task_flags&=~(1<<TASKf_BREAK_LOCKED);', ['Exception'], 'hotkey-unlock')
            submit('Bt(&Fs->task_flags,TASKf_PENDING_BREAK);', ['0'], 'hotkey-consumed')
            submit('6*7;', ['42'], 'hotkey-recovery')
            submit('U0 Forever(){OutU8(0xE9,64);while(1){}}', [], 'loop-definition')
            submit('Forever;', ['Exception'], 'loop-break', hotkey=True)
            submit('U0 GotoLoop(){OutU8(0xE9,64);hotkey_spin:goto hotkey_spin;}', [], 'goto-definition')
            submit('GotoLoop;', ['Exception'], 'goto-break', hotkey=True)
            submit('U0 DoLoop(I64 again){OutU8(0xE9,64);do{}while(again);}', [], 'do-loop-definition')
            submit('DoLoop(1);', ['Exception'], 'do-loop-break', hotkey=True)
            submit("I64 CatchLoop(){I64 value=0;try{OutU8(0xE9,64);while(1){}}catch{value=Fs->except_ch=='Break';Fs->catch_except=TRUE;}return value;}", [], 'catch-loop-definition')
            submit('CatchLoop;', ['1'], 'catch-loop-break', hotkey=True)
            submit('Bt(&Fs->task_flags,TASKf_PENDING_BREAK);', ['0'], 'loop-consumed')
            submit('6*7;', ['42'], 'loop-recovery')
            active_group='documents'
            submit('CDoc locked_doc;', [], 'doc-record')
            submit('DocLock(&locked_doc);', ['1'], 'doc-lock')
            submit('DocLock(&locked_doc);', ['0'], 'doc-lock-nested')
            submit('U0 DocHeld(){OutU8(0xE9,64);while(!Bt(&Fs->task_flags,TASKf_PENDING_BREAK)){}}', [], 'doc-held-definition')
            submit('DocHeld;', [], 'doc-held-break', hotkey=True)
            submit('DocUnlock(&locked_doc);', ['Exception'], 'doc-unlock-break')
            submit('locked_doc.owning_task==0&&!Bt(&locked_doc.locked_flags,DOClf_LOCKED)&&!Bt(&Fs->task_flags,TASKf_PENDING_BREAK);', ['1'], 'doc-released')
            submit('DocUnlock(&locked_doc);', ['0'], 'doc-unlock-again')
            submit('I64 DocAgain(){I64 ok=DocLock(&locked_doc);return ok&&DocUnlock(&locked_doc);}', [], 'doc-again-definition')
            submit('DocAgain;', ['1'], 'doc-again')
            submit('6*7;', ['42'], 'doc-recovery')
            submit('#include "/Kernel/I386/DocAccessCheck.HC"', [], 'doc-access-definition')
            submit('DocAccessCheck(&DocPut,&DocDisplay,&DocBorder);', ['8'], 'doc-access-check')
            submit('#include "/Kernel/I386/HashTableCheck.HC"', [], 'hash-tables-definition')
            submit('HashTableCheck(&HashTableNew,&HashTableDel,&HashLstAdd,&HashFind,&MHeapCtrl);', ['10'], 'hash-tables-check')
            submit('#include "/Kernel/I386/DefineListCheck.HC"', [], 'define-list-definition')
            submit('DefineListCheck(&DefineLstLoad,&HashDefineLstAdd,&HashTableNew,&HashTableDel,&HashDel,&HashFind);', ['6'], 'define-list-check')
            submit('#include "/Kernel/I386/DocInitCheck.HC"', [], 'doc-init-definition')
            submit('DocInitCheck;', ['137'], 'doc-init-check')
            submit('#include "/Kernel/I386/DocEntryAllocCheck.HC"', [], 'doc-entry-definition')
            submit('DocEntryAllocCheck;', ['8'], 'doc-entry-check')
            submit('#include "/Kernel/I386/DocFormNavCheck.HC"', [], 'doc-form-definition')
            submit('DocFormNavCheck;', ['8'], 'doc-form-check')
            submit('Bool DocStartAgain(){CHashTable *p=doldoc.hash;I64 used=Fs->data_heap->used_u8s;ConsoleDocumentStart;return p==doldoc.hash&&used==Fs->data_heap->used_u8s;}', [], 'doc-start-repeat-definition')
            submit('DocStartAgain;', ['1'], 'doc-start-repeat-check')
            submit('#include "/Kernel/I386/DocEntryLifeCheck.HC"', [], 'doc-life-definition')
            submit('DocEntryLifeCheck;', ['8'], 'doc-life-check')
            submit('#include "/Kernel/I386/DocLifecycleCheck.HC"', [], 'doc-lifecycle-definition')
            submit('DocLifecycleCheck;', ['7'], 'doc-lifecycle-check')
            active_group='document-editing'
            submit('CDoc *exe_check=DocNew("C:/NativeExecute.HC",Fs);U8 *exe_source="I64 NativeDocAnswer()";', [], 'doc-execute-new')
            submit('while(*exe_source)DocPutKey(exe_check,*exe_source++);', [], 'doc-execute-type-declaration')
            submit('DocPutKey(exe_check,10);', [], 'doc-execute-newline-before-body')
            submit('U8 *exe_body="{return 40+2;}";while(*exe_body)DocPutKey(exe_check,*exe_body++);', [], 'doc-execute-type-body')
            submit('DocPutKey(exe_check,10);', [], 'doc-execute-newline-before-call')
            submit('U8 *exe_call="NativeDocAnswer;";while(*exe_call)DocPutKey(exe_check,*exe_call++);', [], 'doc-execute-type-call')
            submit('Bool exe_ok=DocExe(exe_check);', ['42'], 'doc-execute')
            submit('exe_ok&&NativeDocAnswer==42;', ['1'], 'doc-execute-retained-definition')
            submit('DocDel(exe_check);', [], 'doc-execute-delete')
            submit('#include "/Kernel/I386/DocBasicEditCheck.HC"', [], 'doc-basic-edit-definition')
            submit('DocBasicEditCheck(&DocPutKey);', ['5'], 'doc-basic-edit-check')
            submit('CDoc *multi_check=DocNew("C:/BasicMultiline.DD",Fs);', [], 'doc-basic-multiline-new')
            submit("DocPutKey(multi_check,'a');DocPutKey(multi_check,'b');DocPutKey(multi_check,10);DocPutKey(multi_check,'c');DocPutKey(multi_check,'d');", [], 'doc-basic-multiline-type')
            submit('I64 multi_check_size;U8 *multi_check_text=DocSave(multi_check,&multi_check_size);multi_check_size==6&&multi_check_text[2]==10&&multi_check_text[5]==5;', ['1'], 'doc-basic-multiline-newline')
            submit('Free(multi_check_text);DocPutKey(multi_check,0,0x4B);DocPutKey(multi_check,0,0x4B);DocPutKey(multi_check,\'X\');', [], 'doc-basic-multiline-insert')
            submit("(multi_check_text=DocSave(multi_check,&multi_check_size))&&multi_check_size==7&&multi_check_text[3]=='X'&&multi_check_text[4]==5;", ['1'], 'doc-basic-multiline-insert-check')
            submit('Free(multi_check_text);DocPutKey(multi_check,8);(multi_check_text=DocSave(multi_check,&multi_check_size))&&multi_check_size==6&&multi_check_text[3]==5&&multi_check_text[4]==\'c\';', ['1'], 'doc-basic-multiline-remove-insert')
            submit('Free(multi_check_text);DocPutKey(multi_check,8);(multi_check_text=DocSave(multi_check,&multi_check_size))&&multi_check_size==5&&multi_check_text[2]==5&&multi_check_text[3]==\'c\';', ['1'], 'doc-basic-multiline-join')
            submit("Free(multi_check_text);DocPutKey(multi_check,'Z');(multi_check_text=DocSave(multi_check,&multi_check_size))&&multi_check_size==6&&multi_check_text[2]=='Z'&&multi_check_text[3]==5;", ['1'], 'doc-basic-multiline-final')
            submit('Free(multi_check_text);DocDel(multi_check);', [], 'doc-basic-multiline-delete')
            submit('CDoc *recovery_doc=DocNew("C:/Recovery.DD",Fs);CDoc *recovery_put=Fs->put_doc,*recovery_display=Fs->display_doc;', [], 'doc-editor-recovery-new')
            recovery_rows=['TempleOS i386','DolDoc editor','C:/Recovery.DD','',bytes([0xDB]).decode('cp437')]
            submit('DocEd(recovery_doc);', ['Exception'], 'doc-editor-recovery-break', interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT exception\n','exit_hotkey':True,
              'initial_rows':recovery_rows,'events':[],'final_rows':recovery_rows})
            submit('Fs->put_doc==recovery_put&&Fs->display_doc==recovery_display&&!recovery_doc->owning_task&&!Bt(&recovery_doc->locked_flags,DOClf_LOCKED)&&!Bt(&Fs->task_flags,TASKf_PENDING_BREAK);', ['1'], 'doc-editor-recovery-state')
            submit('DocDel(recovery_doc);6*7;', ['42'], 'doc-editor-recovery-continued')
            submit('CDoc *nav_check=DocNew("C:/BasicNavigation.DD",Fs);', [], 'doc-basic-navigation-new')
            submit("DocPutKey(nav_check,'a');DocPutKey(nav_check,'b');DocPutKey(nav_check,'c');DocPutKey(nav_check,0,0x47);", [], 'doc-basic-navigation-home')
            submit("I64 nav_check_size;U8 *nav_check_text=DocSave(nav_check,&nav_check_size);nav_check_size==3&&nav_check_text[0]=='a'&&nav_check_text[2]=='c';", ['1'], 'doc-basic-navigation-home-check')
            submit("Free(nav_check_text);DocPutKey(nav_check,0,0x4D);DocPutKey(nav_check,0,0x53);(nav_check_text=DocSave(nav_check,&nav_check_size))&&nav_check_size==3&&nav_check_text[0]=='a'&&nav_check_text[1]==5&&nav_check_text[2]=='c';", ['1'], 'doc-basic-navigation-right-delete')
            submit("Free(nav_check_text);DocPutKey(nav_check,9,0x0F);DocPutKey(nav_check,0,0x4F);(nav_check_text=DocSave(nav_check,&nav_check_size))&&nav_check_size==4&&nav_check_text[1]==9&&nav_check_text[2]=='c'&&nav_check_text[3]==5;", ['1'], 'doc-basic-navigation-tab-end')
            submit("Free(nav_check_text);DocPutKey(nav_check,0,0x47);DocPutKey(nav_check,0,0x4D);DocPutKey(nav_check,0,0x4D);(nav_check_text=DocSave(nav_check,&nav_check_size))&&nav_check_size==4&&nav_check_text[1]==9&&nav_check_text[2]==5&&nav_check_text[3]=='c';", ['1'], 'doc-basic-navigation-cross-tab')
            submit('Free(nav_check_text);DocDel(nav_check);', [], 'doc-basic-navigation-delete')
            submit('I64 SavedAt(CDoc *d,I64 want,I64 at){I64 n;U8 *s=DocSave(d,&n);Bool ok=n==want&&(at<0||s[at]==5);Free(s);return ok;}', [], 'doc-basic-edit-save-helper')
            submit('U0 CursorSave(CDoc *d,Bool on){if(on)d->flags&=~DOCF_NO_CURSOR;else d->flags|=DOCF_NO_CURSOR;}', [], 'doc-basic-edit-cursor-helper')
            submit('CDoc *vert_check=DocNew("C:/BasicVertical.DD",Fs);', [], 'doc-basic-vertical-new')
            submit("DocPutKey(vert_check,'a');DocPutKey(vert_check,'b');DocPutKey(vert_check,'c');DocPutKey(vert_check,'d');DocPutKey(vert_check,'e');DocPutKey(vert_check,10);DocPutKey(vert_check,'x');DocPutKey(vert_check,'y');", [], 'doc-basic-vertical-type-first')
            submit("DocPutKey(vert_check,10);DocPutKey(vert_check,'1');DocPutKey(vert_check,'2');DocPutKey(vert_check,'3');DocPutKey(vert_check,'4');DocPutKey(vert_check,'5');", [], 'doc-basic-vertical-type-last')
            submit('DocPutKey(vert_check,0,0x47);DocPutKey(vert_check,0,0x4D);DocPutKey(vert_check,0,0x4D);', [], 'doc-basic-vertical-position')
            submit('DocPutKey(vert_check,0,0x50);', [], 'doc-basic-vertical-down-short')
            submit('SavedAt(vert_check,15,8);', ['1'], 'doc-basic-vertical-down-short-check')
            submit('DocPutKey(vert_check,0,0x50);', [], 'doc-basic-vertical-down-long')
            submit('SavedAt(vert_check,15,11);', ['1'], 'doc-basic-vertical-down-long-check')
            submit('DocPutKey(vert_check,0,0x48);', [], 'doc-basic-vertical-up-short')
            submit('SavedAt(vert_check,15,8);', ['1'], 'doc-basic-vertical-up-short-check')
            submit('DocPutKey(vert_check,0,0x48);', [], 'doc-basic-vertical-up-long')
            submit('SavedAt(vert_check,15,2);', ['1'], 'doc-basic-vertical-up-long-check')
            submit('DocPutKey(vert_check,0,0x48);', [], 'doc-basic-vertical-top-boundary')
            submit('SavedAt(vert_check,15,2);', ['1'], 'doc-basic-vertical-top-boundary-check')
            submit('DocPutKey(vert_check,0,0x4F);DocPutKey(vert_check,0,0x50);', [], 'doc-basic-vertical-bottom-boundary')
            submit('SavedAt(vert_check,15,14);', ['1'], 'doc-basic-vertical-bottom-boundary-check')
            submit('DocDel(vert_check);', [], 'doc-basic-vertical-delete')
            submit('CDoc *boundary_check=DocNew("C:/BasicBoundary.DD",Fs);', [], 'doc-basic-boundary-new')
            submit('SavedAt(boundary_check,0,-1);', ['1'], 'doc-basic-boundary-empty')
            submit('DocPutKey(boundary_check,0,0x48);DocPutKey(boundary_check,0,0x50);DocPutKey(boundary_check,8);DocPutKey(boundary_check,0,0x53);DocPutKey(boundary_check,0,0x47);DocPutKey(boundary_check,0,0x4F);', [], 'doc-basic-boundary-empty-keys')
            submit('SavedAt(boundary_check,0,-1);', ['1'], 'doc-basic-boundary-empty-keys-check')
            submit("DocPutKey(boundary_check,'a');DocPutKey(boundary_check,10);DocPutKey(boundary_check,10);DocPutKey(boundary_check,'b');DocPutKey(boundary_check,0,0x47);DocPutKey(boundary_check,0,0x50);", [], 'doc-basic-boundary-content')
            submit('SavedAt(boundary_check,5,2);', ['1'], 'doc-basic-boundary-empty-line')
            submit('CursorSave(boundary_check,FALSE);', [], 'doc-basic-boundary-no-cursor-set')
            submit('SavedAt(boundary_check,4,-1);', ['1'], 'doc-basic-boundary-no-cursor')
            submit('CursorSave(boundary_check,TRUE);', [], 'doc-basic-boundary-cursor-restore')
            submit('DocPutKey(boundary_check,0,0x50);', [], 'doc-basic-boundary-down')
            submit('SavedAt(boundary_check,5,3);', ['1'], 'doc-basic-boundary-down-check')
            submit('DocPutKey(boundary_check,0,0x48);', [], 'doc-basic-boundary-up')
            submit('SavedAt(boundary_check,5,2);', ['1'], 'doc-basic-boundary-up-check')
            submit("DocPutKey(boundary_check,'X');", [], 'doc-basic-boundary-insert')
            submit('SavedAt(boundary_check,6,3);', ['1'], 'doc-basic-boundary-insert-check')
            submit('DocPutKey(boundary_check,8);', [], 'doc-basic-boundary-remove-insert')
            submit('SavedAt(boundary_check,5,2);', ['1'], 'doc-basic-boundary-remove-insert-check')
            submit('DocPutKey(boundary_check,0,0x53);', [], 'doc-basic-boundary-delete-empty-line')
            submit('SavedAt(boundary_check,4,2);', ['1'], 'doc-basic-boundary-delete-empty-line-check')
            submit('DocPutKey(boundary_check,8);', [], 'doc-basic-boundary-backspace-join')
            submit('SavedAt(boundary_check,3,1);', ['1'], 'doc-basic-boundary-backspace-join-check')
            submit('DocPutKey(boundary_check,0,0x47);DocPutKey(boundary_check,8);', [], 'doc-basic-boundary-backspace-top')
            submit('SavedAt(boundary_check,2,-1);', ['1'], 'doc-basic-boundary-backspace-top-check')
            submit('DocPutKey(boundary_check,0,0x4F);DocPutKey(boundary_check,0,0x53);', [], 'doc-basic-boundary-delete-end')
            submit('SavedAt(boundary_check,3,2);', ['1'], 'doc-basic-boundary-delete-end-check')
            submit('DocDel(boundary_check);', [], 'doc-basic-boundary-delete')
            submit('#include "/Kernel/I386/DocBasicSaveCheck.HC"', [], 'doc-basic-save-definition')
            submit('DocBasicSaveCheck(&DocSave);', ['5'], 'doc-basic-save-check')
            submit('CDoc *find_check=DocNew("C:/Find.HC",Fs);', [], 'doc-find-new')
            find_text_rows=['TempleOS i386','DolDoc editor','C:/Find.HC','',
                            'one two one'+bytes([0xDB]).decode('cp437')]
            find_prompt_rows=['TempleOS i386','Find','C:/Find.HC','',
                              'Search: '+bytes([0xDB]).decode('cp437')]
            find_query_rows=['TempleOS i386','Find','C:/Find.HC','',
                             'Search: one'+bytes([0xDB]).decode('cp437')]
            find_first_rows=['TempleOS i386','DolDoc editor','C:/Find.HC','',
                             bytes([0xDB]).decode('cp437')+'one two one']
            find_second_rows=['TempleOS i386','DolDoc editor','C:/Find.HC','',
                              'one two '+bytes([0xDB]).decode('cp437')+'one']
            find_missing_rows=['TempleOS i386','DolDoc editor - Not found','C:/Find.HC','',
                               bytes([0xDB]).decode('cp437')+'one two one']
            replace_prompt_rows=['TempleOS i386','Find','C:/Find.HC','',
                                 'Search: one','Replace: '+bytes([0xDB]).decode('cp437')]
            replace_query_rows=['TempleOS i386','Find','C:/Find.HC','',
                                'Search: one','Replace: ONE'+bytes([0xDB]).decode('cp437')]
            replace_result_rows=['TempleOS i386','DolDoc editor','C:/Find.HC','',
                                 'one two ONE'+bytes([0xDB]).decode('cp437')]
            replace_undo_rows=['TempleOS i386','DolDoc editor','C:/Find.HC','',
                               'one two '+bytes([0xDB]).decode('cp437')+'one']
            submit('DocEd(find_check);', ['1'], 'doc-find-editor', interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/Find.HC','',
                              bytes([0xDB]).decode('cp437')],
              'events':[{'text':'one two one'},
                        {'expect_rows':find_text_rows,'label':'find-source'},
                        {'mark_log':'DOC FIND begin\n'},{'ctrl_key':'f'},
                        {'wait_log_after':'DOC FIND begin\n'},
                        {'expect_rows':find_prompt_rows,'label':'find-prompt'},
                        {'text':'one'},
                        {'expect_rows':find_query_rows,'label':'find-query'},
                        {'mark_log':'DOC FIND end\n'},{'key':'ret'},
                        {'wait_log_after':'DOC FIND end\n'},
                        {'expect_rows':find_first_rows,'label':'find-first'},
                        {'key':'f3'},
                        {'expect_rows':find_second_rows,'label':'find-next'},
                        {'shift_key':'f3'},
                        {'expect_rows':find_first_rows,'label':'find-previous'},
                        {'mark_log':'DOC FIND begin\n'},{'ctrl_key':'f'},
                        {'wait_log_after':'DOC FIND begin\n'},
                        {'text':'missing'},
                        {'mark_log':'DOC FIND end\n'},{'key':'ret'},
                        {'wait_log_after':'DOC FIND end\n'},
                        {'expect_rows':find_missing_rows,'label':'find-missing'},
                        {'mark_log':'DOC FIND begin\n'},{'ctrl_key':'f'},
                        {'wait_log_after':'DOC FIND begin\n'},
                        {'text':'one'},{'key':'tab'},
                        {'expect_rows':replace_prompt_rows,'label':'replace-prompt'},
                        {'text':'ONE'},
                        {'expect_rows':replace_query_rows,'label':'replace-query'},
                        {'mark_log':'DOC FIND end\n'},{'key':'ret'},
                        {'wait_log_after':'DOC FIND end\n'},
                        {'expect_rows':replace_result_rows,'label':'replace-result'},
                        {'alt_key':'backspace'},
                        {'wait_log':'DOC EDIT undo ok\n'},
                        {'expect_rows':replace_undo_rows,'label':'replace-undo'}],
              'final_rows':replace_undo_rows})
            submit('DocDel(find_check);', [], 'doc-find-delete')
            submit('CDoc *undo_check=DocNew("C:/Undo.HC",Fs);', [], 'doc-undo-new')
            undo_empty_rows=['TempleOS i386','DolDoc editor','C:/Undo.HC','',
                             bytes([0xDB]).decode('cp437')]
            submit('DocEd(undo_check);', ['1'], 'doc-undo-editor', interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':undo_empty_rows,
              'events':[{'text':'abc'},
                        {'expect_rows':['TempleOS i386','DolDoc editor','C:/Undo.HC','',
                                        'abc'+bytes([0xDB]).decode('cp437')],'label':'undo-c'},
                        {'alt_key':'backspace'},
                        {'expect_rows':undo_empty_rows,'label':'undo-typing-run'},
                        {'text':'a'},
                        {'delay':2.0},
                        {'text':'b'},
                        {'expect_rows':['TempleOS i386','DolDoc editor','C:/Undo.HC','',
                                        'ab'+bytes([0xDB]).decode('cp437')],'label':'undo-level-one'},
                        {'alt_key':'backspace'},
                        {'expect_rows':['TempleOS i386','DolDoc editor','C:/Undo.HC','',
                                        'a'+bytes([0xDB]).decode('cp437')],'label':'undo-level-two'},
                        {'alt_key':'backspace'},
                        {'expect_rows':undo_empty_rows,'label':'undo-before-timed-runs'}],
              'final_rows':undo_empty_rows})
            submit('DocDel(undo_check);', [], 'doc-undo-delete')
            submit('CDoc *selection_check=DocNew("C:/Selection.HC",Fs);', [], 'doc-selection-new')
            selection_source_rows=['TempleOS i386','DolDoc editor','C:/Selection.HC','',
                                   'abc'+bytes([0xDB]).decode('cp437')]
            selection_rows=['TempleOS i386','DolDoc editor','C:/Selection.HC','',
                            'ab'+bytes([0xDB]).decode('cp437')+'c']
            selection_contract_rows=['TempleOS i386','DolDoc editor','C:/Selection.HC','',
                                     'a'+bytes([0xDB]).decode('cp437')+'bc']
            selection_replace_rows=['TempleOS i386','DolDoc editor','C:/Selection.HC','',
                                    'X'+bytes([0xDB]).decode('cp437')+'c']
            submit('DocEd(selection_check);', ['1'], 'doc-selection-editor', interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/Selection.HC','',
                              bytes([0xDB]).decode('cp437')],
              'events':[{'text':'abc'},{'expect_rows':selection_source_rows,'label':'selection-source'},
                        {'key':'home'},{'shift_key':'right'},{'shift_key':'right'},
                        {'expect_rows':selection_rows,'colors':{(4,0):15,(4,1):15},
                         'backgrounds':{(4,0):0,(4,1):0},'label':'selection-two'},
                        {'shift_key':'left'},
                        {'expect_rows':selection_contract_rows,'colors':{(4,0):15},
                         'backgrounds':{(4,0):0},'label':'selection-contract'},
                        {'shift_key':'right'},
                        {'expect_rows':selection_rows,'colors':{(4,0):15,(4,1):15},
                         'backgrounds':{(4,0):0,(4,1):0},'label':'selection-reextend'},
                        {'text':'X'},
                        {'expect_rows':selection_replace_rows,'label':'selection-replace'}],
              'final_rows':selection_replace_rows})
            submit('DocDel(selection_check);', [], 'doc-selection-delete')
            submit('CDoc *clip_check=DocNew("C:/Clipboard.HC",Fs);', [], 'doc-clipboard-new')
            clip_copy_rows=['TempleOS i386','DolDoc editor','C:/Clipboard.HC','',
                            'ab'+bytes([0xDB]).decode('cp437')+'c']
            clip_paste_rows=['TempleOS i386','DolDoc editor','C:/Clipboard.HC','',
                             'abcab'+bytes([0xDB]).decode('cp437')]
            clip_cut_rows=['TempleOS i386','DolDoc editor','C:/Clipboard.HC','',
                           bytes([0xDB]).decode('cp437')+'cab']
            clip_restore_rows=['TempleOS i386','DolDoc editor','C:/Clipboard.HC','',
                               'ab'+bytes([0xDB]).decode('cp437')+'cab']
            submit('DocEd(clip_check);', ['1'], 'doc-clipboard-editor', interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/Clipboard.HC','',
                              bytes([0xDB]).decode('cp437')],
              'events':[{'text':'abc'},{'key':'home'},
                        {'shift_key':'right'},{'shift_key':'right'},
                        {'ctrl_key':'c'},
                        {'expect_rows':clip_copy_rows,'label':'clipboard-copy'},
                        {'key':'end'},{'ctrl_key':'v'},
                        {'expect_rows':clip_paste_rows,'label':'clipboard-paste'},
                        {'key':'home'},{'shift_key':'right'},{'shift_key':'right'},
                        {'ctrl_key':'x'},
                        {'expect_rows':clip_cut_rows,'label':'clipboard-cut'},
                        {'ctrl_key':'v'},
                        {'expect_rows':clip_restore_rows,'label':'clipboard-restore'}],
              'final_rows':clip_restore_rows})
            submit('DocDel(clip_check);', [], 'doc-clipboard-delete')
            submit('CDoc *select_all_check=DocNew("C:/SelectAll.HC",Fs);', [], 'doc-select-all-new')
            select_all_rows=['TempleOS i386','DolDoc editor','C:/SelectAll.HC','',
                             bytes([0xDB]).decode('cp437')+'xyz']
            select_all_empty_rows=['TempleOS i386','DolDoc editor','C:/SelectAll.HC','',
                                   bytes([0xDB]).decode('cp437')]
            select_all_restore_rows=['TempleOS i386','DolDoc editor','C:/SelectAll.HC','',
                                     'xyz'+bytes([0xDB]).decode('cp437')]
            submit('DocEd(select_all_check);', ['1'], 'doc-select-all-editor', interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':select_all_empty_rows,
              'events':[{'text':'xyz'},{'ctrl_key':'up','shift':True},
                        {'expect_rows':select_all_rows,
                         'colors':{(4,0):15,(4,1):15,(4,2):15,(4,3):15},
                         'backgrounds':{(4,0):0,(4,1):0,(4,2):0,(4,3):0},
                         'label':'select-all'},
                        {'ctrl_key':'x'},
                        {'expect_rows':select_all_empty_rows,'label':'select-all-cut'},
                        {'ctrl_key':'v'},
                        {'expect_rows':select_all_restore_rows,'label':'select-all-paste'}],
              'final_rows':select_all_restore_rows})
            submit('DocDel(select_all_check);', [], 'doc-select-all-delete')
            submit('CDoc *select_line_check=DocNew("C:/SelectLine.HC",Fs);', [], 'doc-select-line-new')
            select_line_rows=['TempleOS i386','DolDoc editor','C:/SelectLine.HC','',
                              'aa','bb'+bytes([0xDB]).decode('cp437'),'cc']
            select_line_clear_rows=['TempleOS i386','DolDoc editor','C:/SelectLine.HC','',
                                    'aa','bb','cc'+bytes([0xDB]).decode('cp437')]
            select_line_replace_rows=['TempleOS i386','DolDoc editor','C:/SelectLine.HC','',
                                      'aa','bbX'+bytes([0xDB]).decode('cp437')]
            submit('DocEd(select_line_check);', ['1'], 'doc-select-line-editor', interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/SelectLine.HC','',
                              bytes([0xDB]).decode('cp437')],
              'events':[{'text':'aa'},{'key':'ret'},{'text':'bb'},{'key':'ret'},
                        {'text':'cc'},{'shift_key':'up'},
                        {'expect_rows':select_line_rows,
                         'colors':{(5,2):15,(6,0):15,(6,1):15},
                         'backgrounds':{(5,2):0,(6,0):0,(6,1):0},
                         'label':'select-line-up'},
                        {'shift_key':'down'},
                        {'expect_rows':select_line_clear_rows,'label':'select-line-contract'},
                        {'shift_key':'up'},
                        {'expect_rows':select_line_rows,
                         'colors':{(5,2):15,(6,0):15,(6,1):15},
                         'backgrounds':{(5,2):0,(6,0):0,(6,1):0},
                         'label':'select-line-reextend'},
                        {'text':'X'},
                        {'expect_rows':select_line_replace_rows,'label':'select-line-replace'}],
              'final_rows':select_line_replace_rows})
            submit('DocDel(select_line_check);', [], 'doc-select-line-delete')
            submit('CDoc *select_page_check=DocNew("C:/SelectPage.HC",Fs);', [], 'doc-select-page-new')
            select_page_rows=['TempleOS i386','DolDoc editor','C:/SelectPage.HC','',
                              'aa'+bytes([0xDB]).decode('cp437'),'bb','cc']
            select_page_clear_rows=['TempleOS i386','DolDoc editor','C:/SelectPage.HC','',
                                    'aa','bb','cc'+bytes([0xDB]).decode('cp437')]
            select_page_replace_rows=['TempleOS i386','DolDoc editor','C:/SelectPage.HC','',
                                      'aaP'+bytes([0xDB]).decode('cp437')]
            submit('DocEd(select_page_check);', ['1'], 'doc-select-page-editor', interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/SelectPage.HC','',
                              bytes([0xDB]).decode('cp437')],
              'events':[{'text':'aa'},{'key':'ret'},{'text':'bb'},{'key':'ret'},
                        {'text':'cc'},{'shift_key':'pgup'},
                        {'expect_rows':select_page_rows,
                         'colors':{(4,2):15,(5,0):15,(5,1):15,
                                   (6,0):15,(6,1):15},
                         'backgrounds':{(4,2):0,
                                       (5,0):0,(5,1):0,(6,0):0,(6,1):0},
                         'label':'select-page-up'},
                        {'shift_key':'pgdn'},
                        {'expect_rows':select_page_clear_rows,'label':'select-page-contract'},
                        {'shift_key':'pgup'},
                        {'expect_rows':select_page_rows,
                         'colors':{(4,2):15,(5,0):15,(5,1):15,
                                   (6,0):15,(6,1):15},
                         'backgrounds':{(4,2):0,(5,0):0,(5,1):0,
                                       (6,0):0,(6,1):0},
                         'label':'select-page-reextend'},
                        {'text':'P'},
                        {'expect_rows':select_page_replace_rows,'label':'select-page-replace'}],
              'final_rows':select_page_replace_rows})
            submit('DocDel(select_page_check);', [], 'doc-select-page-delete')
            submit('CDoc *goto_check=DocNew("C:/Goto.HC",Fs);', [], 'doc-goto-new')
            goto_source_rows=['TempleOS i386','DolDoc editor','C:/Goto.HC','',
                              'aa','bb','cc'+bytes([0xDB]).decode('cp437')]
            goto_prompt_rows=['TempleOS i386','Go to line','C:/Goto.HC','',
                              'Line: '+bytes([0xDB]).decode('cp437')]
            goto_query_rows=['TempleOS i386','Go to line','C:/Goto.HC','',
                             'Line: 2'+bytes([0xDB]).decode('cp437')]
            goto_second_rows=['TempleOS i386','DolDoc editor','C:/Goto.HC','',
                              'aa',bytes([0xDB]).decode('cp437')+'bb','cc']
            goto_missing_rows=['TempleOS i386','DolDoc editor - Line not found',
                               'C:/Goto.HC','','aa',
                               bytes([0xDB]).decode('cp437')+'bb','cc']
            submit('DocEd(goto_check);', ['1'], 'doc-goto-editor', interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/Goto.HC','',
                              bytes([0xDB]).decode('cp437')],
              'events':[{'text':'aa'},{'key':'ret'},{'text':'bb'},
                        {'key':'ret'},{'text':'cc'},
                        {'expect_rows':goto_source_rows,'label':'goto-source'},
                        {'mark_log':'DOC GOTO begin\n'},{'ctrl_key':'g'},
                        {'wait_log_after':'DOC GOTO begin\n'},
                        {'expect_rows':goto_prompt_rows,'label':'goto-prompt'},
                        {'text':'2'},
                        {'expect_rows':goto_query_rows,'label':'goto-query'},
                        {'mark_log':'DOC GOTO end\n'},{'key':'ret'},
                        {'wait_log_after':'DOC GOTO end\n'},
                        {'expect_rows':goto_second_rows,'label':'goto-second'},
                        {'mark_log':'DOC GOTO begin\n'},{'ctrl_key':'g'},
                        {'wait_log_after':'DOC GOTO begin\n'},
                        {'text':'9'},
                        {'mark_log':'DOC GOTO end\n'},{'key':'ret'},
                        {'wait_log_after':'DOC GOTO end\n'},
                        {'expect_rows':goto_missing_rows,'label':'goto-missing'}],
              'final_rows':goto_missing_rows})
            submit('DocDel(goto_check);', [], 'doc-goto-delete')
            submit('CDoc *color_check=DocNew("C:/Color.DD",Fs);CDocEntry *color_entry=CAlloc(sizeof(CDocEntry));', [], 'doc-color-new')
            submit('color_entry->type=DOCT_FOREGROUND;color_entry->attr=4;DocInsEntry(color_check,color_entry);', ['15','4'], 'doc-color-red')
            submit('U8 *color_text="red";while(*color_text)DocPutKey(color_check,*color_text++);', [], 'doc-color-red-text')
            submit('CDocEntry *color_default=CAlloc(sizeof(CDocEntry));color_default->type=DOCT_FOREGROUND;color_default->attr=DOC_DFT;DocInsEntry(color_check,color_default);', ['15','-2147483648'], 'doc-color-default')
            submit('U8 *color_plain=" plain";while(*color_plain)DocPutKey(color_check,*color_plain++);', [], 'doc-color-default-text')
            submit('CDocEntry *color_background=CAlloc(sizeof(CDocEntry));color_background->type=DOCT_BACKGROUND;color_background->attr=1;DocInsEntry(color_check,color_background);', ['16','1'], 'doc-color-blue-background')
            submit('U8 *color_blue=" blue";while(*color_blue)DocPutKey(color_check,*color_blue++);', [], 'doc-color-blue-text')
            submit('CDocEntry *color_background_default=CAlloc(sizeof(CDocEntry));color_background_default->type=DOCT_BACKGROUND;color_background_default->attr=DOC_DFT;DocInsEntry(color_check,color_background_default);', ['16','-2147483648'], 'doc-color-background-default')
            submit('U8 *color_end=" end";while(*color_end)DocPutKey(color_check,*color_end++);', [], 'doc-color-end-text')
            submit('CDocEntry *style_invert=CAlloc(sizeof(CDocEntry));style_invert->type=DOCT_INVERT;style_invert->attr=1;DocInsEntry(color_check,style_invert);', ['22','1'], 'doc-style-invert')
            submit('U8 *style_invert_text=" inv";while(*style_invert_text)DocPutKey(color_check,*style_invert_text++);', [], 'doc-style-invert-text')
            submit('CDocEntry *style_normal=CAlloc(sizeof(CDocEntry));style_normal->type=DOCT_INVERT;style_normal->attr=0;DocInsEntry(color_check,style_normal);', ['22','0'], 'doc-style-normal')
            submit('CDocEntry *style_underline=CAlloc(sizeof(CDocEntry));style_underline->type=DOCT_UNDERLINE;style_underline->attr=1;DocInsEntry(color_check,style_underline);', ['23','1'], 'doc-style-underline')
            submit('U8 *style_under_text=" under";while(*style_under_text)DocPutKey(color_check,*style_under_text++);', [], 'doc-style-underline-text')
            submit('CDocEntry *style_plain=CAlloc(sizeof(CDocEntry));style_plain->type=DOCT_UNDERLINE;style_plain->attr=0;DocInsEntry(color_check,style_plain);', ['23','0'], 'doc-style-plain')
            submit('U8 *style_done=" done";while(*style_done)DocPutKey(color_check,*style_done++);', [], 'doc-style-done-text')
            color_rows=['TempleOS i386','DolDoc editor','C:/Color.DD','',
                        'red plain blue end inv under done'+bytes([0xDB]).decode('cp437')]
            color_cells={(4,index):4 for index in range(3)}
            color_cells.update({(4,index):15 for index in range(18,22)})
            background_cells={(4,index):1 for index in range(9,14)}
            background_cells.update({(4,index):0 for index in range(18,22)})
            underline_cells={(4,index) for index in range(22,28)}
            submit('DocEd(color_check);', ['1'],'doc-color-editor',interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':color_rows,'initial_colors':color_cells,
              'initial_backgrounds':background_cells,
              'initial_underlines':underline_cells,
              'events':[],'final_rows':color_rows,'final_colors':color_cells,
              'final_backgrounds':background_cells,
              'final_underlines':underline_cells,
            })
            submit('I64 color_size;U8 *color_saved=DocSave(color_check,&color_size);', [], 'doc-style-save')
            submit('color_size==78&&color_saved[38]==36&&color_saved[39]==73&&color_saved[43]==36&&color_saved[48]==36&&color_saved[54]==36&&color_saved[55]==85&&color_saved[59]==36&&color_saved[66]==36&&color_saved[71]==36&&color_saved[77]==5;', ['1'], 'doc-style-save-check')
            submit('Free(color_saved);DocDel(color_check);', [], 'doc-color-delete')
            submit('CDoc *style_key_check=DocNew("C:/StyleKeys.DD",Fs);', [], 'doc-style-keys-new')
            style_key_rows=['TempleOS i386','DolDoc editor','C:/StyleKeys.DD','',
                            'under inv done'+bytes([0xDB]).decode('cp437')]
            submit('DocEd(style_key_check);', ['1'],'doc-style-keys-editor',interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/StyleKeys.DD','',
                              bytes([0xDB]).decode('cp437')],
              'events':[{'ctrl_key':'u'},{'text':'under'},
                        {'ctrl_key':'u','shift':True},{'text':' '},
                        {'ctrl_key':'z'},{'text':'inv'},
                        {'ctrl_key':'z','shift':True},{'text':' done'}],
              'final_rows':style_key_rows,
              'final_colors':{(4,index):15 for index in range(6,9)},
              'final_backgrounds':{(4,index):0 for index in range(6,9)},
              'final_underlines':{(4,index) for index in range(5)},
            })
            submit('I64 style_key_size;U8 *style_key_saved=DocSave(style_key_check,&style_key_size);', [], 'doc-style-keys-save')
            submit('style_key_size==39&&style_key_saved[0]==36&&style_key_saved[1]==85&&style_key_saved[5]==36&&style_key_saved[11]==36&&style_key_saved[12]==85&&style_key_saved[16]==36;', ['1'], 'doc-style-keys-save-check-a')
            submit('style_key_saved[18]==36&&style_key_saved[19]==73&&style_key_saved[23]==36&&style_key_saved[27]==36&&style_key_saved[32]==36&&style_key_saved[38]==5;', ['1'], 'doc-style-keys-save-check-b')
            submit('Free(style_key_saved);DocDel(style_key_check);', [], 'doc-style-keys-delete')
            submit('CDoc *blink_key_check=DocNew("C:/BlinkKeys.DD",Fs);', [], 'doc-blink-keys-new')
            blink_key_rows=['TempleOS i386','DolDoc editor','C:/BlinkKeys.DD','',
                            'blink steady'+bytes([0xDB]).decode('cp437')]
            submit('DocEd(blink_key_check);', ['1'],'doc-blink-keys-editor',interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/BlinkKeys.DD','',
                              bytes([0xDB]).decode('cp437')],
              'events':[{'ctrl_key':'k'},{'text':'blink'},
                        {'ctrl_key':'k','shift':True},{'text':' steady'},
                        {'expect_rows':blink_key_rows,
                         'colors':{(4,index):15 for index in range(5)},
                         'backgrounds':{(4,index):0 for index in range(5)},
                         'label':'blink-on'},
                        {'expect_rows':blink_key_rows,'label':'blink-off'}],
              'final_rows':blink_key_rows,
            })
            submit('I64 blink_key_size;U8 *blink_key_saved=DocSave(blink_key_check,&blink_key_size);', [], 'doc-blink-keys-save')
            submit('blink_key_size==25&&blink_key_saved[0]==36&&blink_key_saved[1]==66&&blink_key_saved[2]==75&&blink_key_saved[24]==5;', ['1'], 'doc-blink-keys-save-check')
            submit('Free(blink_key_saved);DocDel(blink_key_check);', [], 'doc-blink-keys-delete')
            submit('CDoc *save_key_check=DocNew("C:/CtrlSave.DD",Fs);', [], 'doc-ctrl-save-new')
            submit('DocEd(save_key_check);', ['1'],'doc-ctrl-save-editor',interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/CtrlSave.DD','',
                              bytes([0xDB]).decode('cp437')],
              'events':[{'text':'saved'},{'ctrl_key':'s'},
                        {'expect_rows':['TempleOS i386','DolDoc editor - Saved',
                                        'C:/CtrlSave.DD','','saved'+bytes([0xDB]).decode('cp437')],
                         'label':'saved-status'}],
              'final_rows':['TempleOS i386','DolDoc editor - Saved',
                            'C:/CtrlSave.DD','','saved'+bytes([0xDB]).decode('cp437')],
            })
            submit('CDoc *save_key_read=DocRead("C:/CtrlSave.DD");save_key_read!=0;', ['1'], 'doc-ctrl-save-read')
            submit('I64 save_key_size;U8 *save_key_text=DocSave(save_key_read,&save_key_size);save_key_size==6&&save_key_text[0]==115&&save_key_text[4]==100&&save_key_text[5]==5;', ['1'], 'doc-ctrl-save-check')
            submit('Free(save_key_text);DocDel(save_key_read);DocDel(save_key_check);', [], 'doc-ctrl-save-delete')
            submit('CDoc *save_fail_check=DocNew("C:/NoSuchParent/CtrlSave.DD",Fs);', [], 'doc-ctrl-save-fail-new')
            submit('DocEd(save_fail_check);', ['1'],'doc-ctrl-save-fail-editor',interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor',
                              'C:/NoSuchParent/CtrlSave.DD','',
                              bytes([0xDB]).decode('cp437')],
              'events':[{'text':'kept'},{'ctrl_key':'s'},
                        {'expect_rows':['TempleOS i386','DolDoc editor - Save failed',
                                        'C:/NoSuchParent/CtrlSave.DD','',
                                        'kept'+bytes([0xDB]).decode('cp437')],
                         'label':'save-failed-status'},
                        {'text':'!'}],
              'final_rows':['TempleOS i386','DolDoc editor',
                            'C:/NoSuchParent/CtrlSave.DD','',
                            'kept!'+bytes([0xDB]).decode('cp437')],
            })
            submit('CDoc *save_fail_read=DocRead("C:/NoSuchParent/CtrlSave.DD");save_fail_read==0;', ['1'], 'doc-ctrl-save-fail-read')
            submit('I64 save_fail_size;U8 *save_fail_text=DocSave(save_fail_check,&save_fail_size);save_fail_size==6&&save_fail_text[0]==107&&save_fail_text[4]==33&&save_fail_text[5]==5;', ['1'], 'doc-ctrl-save-fail-check')
            submit('Free(save_fail_text);DocDel(save_fail_check);', [], 'doc-ctrl-save-fail-delete')
            submit('Ed("C:/FileEditor.DD");', ['1'], 'file-editor-create',interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/FileEditor.DD','',
                              bytes([0xDB]).decode('cp437')],
              'events':[{'text':'original'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/FileEditor.DD','',
                            'original'+bytes([0xDB]).decode('cp437')],
            })
            submit('CDoc *file_editor_read=DocRead("C:/FileEditor.DD");file_editor_read!=0;', ['1'], 'file-editor-create-read')
            submit('I64 file_editor_size;U8 *file_editor_text=DocSave(file_editor_read,&file_editor_size);file_editor_size==9&&file_editor_text[0]==111&&file_editor_text[7]==108&&file_editor_text[8]==5;', ['1'], 'file-editor-create-check')
            submit('Free(file_editor_text);DocDel(file_editor_read);', [], 'file-editor-create-delete')
            submit('Ed("C:/FileEditor.DD");', ['0'], 'file-editor-cancel',interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n','exit_shift':True,
              'initial_rows':['TempleOS i386','DolDoc editor','C:/FileEditor.DD','',
                              'original'+bytes([0xDB]).decode('cp437')],
              'events':[{'text':'X'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/FileEditor.DD','',
                            'originalX'+bytes([0xDB]).decode('cp437')],
            })
            submit('CDoc *cancel_read=DocRead("C:/FileEditor.DD");U8 *cancel_text=DocSave(cancel_read,&file_editor_size);', [], 'file-editor-cancel-read')
            submit('file_editor_size==9&&cancel_text[7]==108&&cancel_text[8]==5;', ['1'], 'file-editor-cancel-check')
            submit('Free(cancel_text);DocDel(cancel_read);', [], 'file-editor-cancel-delete')
            active_group='document-resources'
            submit('#include "/Kernel/I386/DocSessionResourceCheck.HC"', [], 'doc-session-resource-definition')
            submit('DocSessionResourceCheck;', ['Exception']*21+['21'], 'doc-session-resource-check', timeout=120)
            submit('doc_session_data_used>0&&doc_session_code_used>0&&doc_session_data_reserved>=doc_session_data_used&&doc_session_code_reserved>=doc_session_code_used;', ['1'], 'doc-session-resource-accounting')
            submit('doc_session_heap_peak>doc_session_heap_base&&doc_session_heap_reserved_peak>=doc_session_heap_peak;', ['1'], 'doc-session-resource-peak')
            active_group='document-latency'
            submit('CDoc *long_doc=DocNew("C:/Long.DD",Fs);I64 long_i;', [], 'doc-long-new')
            submit("for(long_i=0;long_i<65;long_i++){DocPutKey(long_doc,'0'+long_i/10);DocPutKey(long_doc,'0'+long_i%10);if(long_i<64)DocPutKey(long_doc,10);}", ['0'], 'doc-long-fill')
            long_initial=['TempleOS i386','DolDoc editor','C:/Long.DD','']+[
                f'{index:02d}' for index in range(9,64)]+[
                '64'+bytes([0xDB]).decode('cp437')]
            long_up=['TempleOS i386','DolDoc editor','C:/Long.DD','']+[
                f'{index:02d}' for index in range(8,63)]+[
                '63'+bytes([0xDB]).decode('cp437')]
            long_page_up=['TempleOS i386','DolDoc editor','C:/Long.DD','']+[
                ('08'+bytes([0xDB]).decode('cp437')) if index==8 else f'{index:02d}'
                for index in range(56)]
            long_top=['TempleOS i386','DolDoc editor','C:/Long.DD','']+[
                (bytes([0xDB]).decode('cp437')+'00') if index==0 else f'{index:02d}'
                for index in range(56)]
            submit('DocEd(long_doc);', ['1'], 'doc-long-editor',interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':long_initial,
              'events':[{'key':'up','measure_latency':'long_document_up_to_vga'},
                        {'expect_rows':long_up,'label':'single-up'},
                        {'key':'pgup'},
                        {'expect_rows':long_page_up,'label':'page-up'},
                        {'key':'pgdn'},
                        {'expect_rows':long_up,'label':'page-down'},
                        {'ctrl_key':'up'},
                        {'expect_rows':long_top,'label':'control-up'},
                        {'ctrl_key':'down'}],
              'latency_budget_seconds':1.0,
              'final_rows':long_initial,
            })
            submit('DocDel(long_doc);', [], 'doc-long-delete')
            active_group='mouse'
            submit('CDoc *mouse_doc=DocNew("C:/Mouse.HC",Fs);', [], 'doc-mouse-new')
            submit('U8 *mouse_source="alpha\\nbeta";I64 mouse_at;for(mouse_at=0;mouse_source[mouse_at];mouse_at++)DocPutKey(mouse_doc,mouse_source[mouse_at]);', ['0'], 'doc-mouse-fill')
            mouse_block=bytes([0xDB]).decode('cp437')
            mouse_initial=['TempleOS i386','DolDoc editor','C:/Mouse.HC','',
                           'alpha','beta'+mouse_block]
            mouse_clicked=['TempleOS i386','DolDoc editor','C:/Mouse.HC','',
                           'alpha','b'+mouse_block+'eta']
            mouse_inserted=['TempleOS i386','DolDoc editor','C:/Mouse.HC','',
                            'alpha','bX'+mouse_block+'eta']
            submit('DocEd(mouse_doc);', ['1'], 'doc-mouse-editor',interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':mouse_initial,
              'events':[{'mouse_to':[12,44]},
                        {'expect_rows':mouse_initial,'label':'mouse-pointer',
                         'pointer':[12,44]},
                        {'mark_log':'DOC EDIT mouse cursor\n'},
                        {'mouse_button':'left','down':True},
                        {'wait_log_after':'DOC EDIT mouse cursor\n'},
                        {'expect_rows':mouse_clicked,'label':'mouse-click','pointer':[12,44]},
                        {'mouse_button':'left','down':False},
                        {'text':'X'}],
              'final_rows':mouse_inserted,'final_pointer':[12,44]})
            submit('I64 mouse_size;U8 *mouse_saved=DocSave(mouse_doc,&mouse_size);mouse_size==12&&mouse_saved[6]==98&&mouse_saved[7]==88&&mouse_saved[8]==5&&mouse_saved[9]==101;', ['1'], 'doc-mouse-canonical-check')
            submit('Free(mouse_saved);DocDel(mouse_doc);', [], 'doc-mouse-delete')
            submit('CDoc *mouse_scroll=DocNew("C:/MouseScroll.HC",Fs);I64 mouse_line;', [], 'doc-mouse-scroll-new')
            submit("for(mouse_line=0;mouse_line<60;mouse_line++){DocPutKey(mouse_scroll,'0'+mouse_line/10);DocPutKey(mouse_scroll,'0'+mouse_line%10);if(mouse_line<59)DocPutKey(mouse_scroll,10);}", ['0'], 'doc-mouse-scroll-fill')
            mouse_scroll_initial=['TempleOS i386','DolDoc editor','C:/MouseScroll.HC','']+[
                f'{index:02d}' for index in range(4,59)]+['59'+mouse_block]
            mouse_scroll_clicked=['TempleOS i386','DolDoc editor','C:/MouseScroll.HC','']+[
                (mouse_block+'04') if index==4 else f'{index:02d}' for index in range(56)]
            submit('DocEd(mouse_scroll);', ['1'], 'doc-mouse-scroll-editor',interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':mouse_scroll_initial,
              'events':[{'mouse_to':[4,36]},
                        {'mark_log':'DOC EDIT mouse cursor\n'},
                        {'mouse_button':'left','down':True},
                        {'wait_log_after':'DOC EDIT mouse cursor\n'},
                        {'mouse_button':'left','down':False}],
              'final_rows':mouse_scroll_clicked,'final_pointer':[4,36]})
            submit('U8 *mouse_scroll_saved=DocSave(mouse_scroll,&mouse_size);mouse_size==180&&mouse_scroll_saved[12]==5&&mouse_scroll_saved[13]==48&&mouse_scroll_saved[14]==52;', ['1'], 'doc-mouse-scroll-canonical-check')
            mouse_scroll_auto=['TempleOS i386','DolDoc editor','C:/MouseScroll.HC','']+[
                f'{index:02d}' for index in range(2,57)]+['57'+mouse_block]
            mouse_scroll_auto_colors={(row,column):15 for row in range(4,60)
                                      for column in range(2)}
            mouse_scroll_auto_backgrounds={(row,column):0 for row in range(4,60)
                                           for column in range(2)}
            submit('DocEd(mouse_scroll);', ['1'], 'doc-mouse-autoscroll-editor',interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':mouse_scroll_clicked,
              'events':[{'mouse_to':[4,36]},
                        {'mark_log':'DOC EDIT mouse cursor\n'},
                        {'mouse_button':'left','down':True},
                        {'wait_log_after':'DOC EDIT mouse cursor\n'},
                        {'mark_log':'DOC EDIT mouse autoscroll\n'},
                        {'mouse_to':[20,479]},
                        {'wait_log_after':'DOC EDIT mouse autoscroll\n'},
                        {'mark_log':'DOC EDIT mouse autoscroll\n'},
                        {'mouse_rel':[0,8]},
                        {'wait_log_after':'DOC EDIT mouse autoscroll\n'},
                        {'mouse_button':'left','down':False},
                        {'mouse_to':[120,479]}],
              'final_rows':mouse_scroll_auto,
              'final_colors':mouse_scroll_auto_colors,
              'final_backgrounds':mouse_scroll_auto_backgrounds,
              'final_pointer':[120,479]})
            submit('I64 MouseScrollAutoCheck(){Free(mouse_scroll_saved);mouse_scroll_saved=DocSave(mouse_scroll,&mouse_size);return mouse_size==180&&mouse_scroll_saved[173]==5&&mouse_scroll_saved[174]==10&&mouse_scroll_saved[175]==53&&mouse_scroll_saved[176]==56;}', [], 'doc-mouse-autoscroll-canonical-definition')
            submit('MouseScrollAutoCheck;', ['1'], 'doc-mouse-autoscroll-canonical-check')
            mouse_scroll_auto_up=['TempleOS i386','DolDoc editor','C:/MouseScroll.HC','']+[
                (mouse_block+'00') if index==0 else f'{index:02d}'
                for index in range(56)]
            mouse_scroll_up_colors={(row,column):15 for row in range(4,60)
                                    for column in range(2)}
            mouse_scroll_up_backgrounds={(row,column):0 for row in range(4,60)
                                         for column in range(2)}
            mouse_scroll_up_colors[4,2]=15
            mouse_scroll_up_backgrounds[4,2]=0
            submit('DocEd(mouse_scroll);', ['1'], 'doc-mouse-autoscroll-up-editor',interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':mouse_scroll_auto,
              'initial_colors':mouse_scroll_auto_colors,
              'initial_backgrounds':mouse_scroll_auto_backgrounds,
              'events':[{'mouse_to':[4,476]},
                        {'mark_log':'DOC EDIT mouse cursor\n'},
                        {'mouse_button':'left','down':True},
                        {'wait_log_after':'DOC EDIT mouse cursor\n'},
                        {'mark_log':'DOC EDIT mouse autoscroll\n'},
                        {'mouse_to':[4,32]},
                        {'wait_log_after':'DOC EDIT mouse autoscroll\n'},
                        {'mark_log':'DOC EDIT mouse autoscroll\n'},
                        {'mouse_rel':[0,-8]},
                        {'wait_log_after':'DOC EDIT mouse autoscroll\n'},
                        {'mouse_button':'left','down':False},
                        {'mouse_rel':[0,8]},
                        {'mouse_to':[120,32]}],
              'final_rows':mouse_scroll_auto_up,
              'final_colors':mouse_scroll_up_colors,
              'final_backgrounds':mouse_scroll_up_backgrounds,
              'final_pointer':[120,32]})
            submit('I64 MouseScrollUpCheck(){Free(mouse_scroll_saved);mouse_scroll_saved=DocSave(mouse_scroll,&mouse_size);return mouse_size==179&&mouse_scroll_saved[0]==48&&mouse_scroll_saved[1]==48&&mouse_scroll_saved[2]==10;}', [], 'doc-mouse-autoscroll-up-canonical-definition')
            submit('MouseScrollUpCheck;', ['1'], 'doc-mouse-autoscroll-up-canonical-check')
            submit('Free(mouse_scroll_saved);DocDel(mouse_scroll);', [], 'doc-mouse-scroll-delete')
            submit('CDoc *mouse_wide=DocNew("C:/MouseWide.HC",Fs);I64 mouse_wide_i;', [], 'doc-mouse-wide-new')
            submit("for(mouse_wide_i=0;mouse_wide_i<100;mouse_wide_i++)DocPutKey(mouse_wide,'a');", ['0'], 'doc-mouse-wide-fill')
            submit('DocPutKey(mouse_wide,0,0x47);', [], 'doc-mouse-wide-home')
            mouse_wide_start=['TempleOS i386','DolDoc editor','C:/MouseWide.HC','',
                              mouse_block+'a'*79]
            mouse_wide_right=['TempleOS i386','DolDoc editor','C:/MouseWide.HC','',
                              'a'*79+mouse_block]
            mouse_wide_colors={(4,column):15 for column in range(79)}
            mouse_wide_backgrounds={(4,column):0 for column in range(79)}
            submit('DocEd(mouse_wide);', ['1'], 'doc-mouse-autoscroll-right-editor',interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':mouse_wide_start,
              'events':[{'mouse_to':[4,36]},
                        {'mark_log':'DOC EDIT mouse cursor\n'},
                        {'mouse_button':'left','down':True},
                        {'wait_log_after':'DOC EDIT mouse cursor\n'},
                        {'mark_log':'DOC EDIT mouse autoscroll\n'},
                        {'mouse_to':[639,36]},
                        {'wait_log_after':'DOC EDIT mouse autoscroll\n'},
                        {'mark_log':'DOC EDIT mouse autoscroll\n'},
                        {'mouse_rel':[8,0]},
                        {'wait_log_after':'DOC EDIT mouse autoscroll\n'},
                        {'mouse_button':'left','down':False}],
              'final_rows':mouse_wide_right,
              'final_colors':mouse_wide_colors,
              'final_backgrounds':mouse_wide_backgrounds,
              'final_pointer':[639,36]})
            submit('I64 MouseWideRightCheck(){I64 n,i;U8 *s=DocSave(mouse_wide,&n);for(i=0;i<n&&s[i]!=5;i++);Free(s);return n*1000+i;}', [], 'doc-mouse-autoscroll-right-canonical-definition')
            submit('MouseWideRightCheck;', ['101081'], 'doc-mouse-autoscroll-right-canonical-check')
            mouse_wide_left=['TempleOS i386','DolDoc editor','C:/MouseWide.HC','',
                             mouse_block+'a'*79]
            mouse_wide_left_colors={(4,column):15 for column in range(80)}
            mouse_wide_left_backgrounds={(4,column):0 for column in range(80)}
            submit('DocEd(mouse_wide);', ['1'], 'doc-mouse-autoscroll-left-editor',interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':mouse_wide_right,
              'initial_colors':mouse_wide_colors,
              'initial_backgrounds':mouse_wide_backgrounds,
              'events':[{'mouse_to':[636,36]},
                        {'mark_log':'DOC EDIT mouse cursor\n'},
                        {'mouse_button':'left','down':True},
                        {'wait_log_after':'DOC EDIT mouse cursor\n'},
                        {'mark_log':'DOC EDIT mouse autoscroll\n'},
                        {'mouse_to':[500,36]},
                        {'mouse_to':[400,36]},
                        {'mouse_to':[300,36]},
                        {'mouse_to':[200,36]},
                        {'mouse_to':[100,36]},
                        {'mouse_to':[0,36]},
                        {'wait_log_after':'DOC EDIT mouse autoscroll\n'},
                        {'mark_log':'DOC EDIT mouse autoscroll\n'},
                        {'mouse_rel':[-8,0]},
                        {'wait_log_after':'DOC EDIT mouse autoscroll\n'},
                        {'mouse_button':'left','down':False}],
              'final_rows':mouse_wide_left,
              'final_colors':mouse_wide_left_colors,
              'final_backgrounds':mouse_wide_left_backgrounds,
              'final_pointer':[0,36]})
            submit('I64 MouseWideLeftCheck(){I64 n;U8 *s=DocSave(mouse_wide,&n);Free(s);return n;}', [], 'doc-mouse-autoscroll-left-canonical-definition')
            submit('MouseWideLeftCheck;', ['100'], 'doc-mouse-autoscroll-left-canonical-check')
            submit('DocDel(mouse_wide);', [], 'doc-mouse-wide-delete')
            submit('CDoc *mouse_drag=DocNew("C:/MouseDrag.HC",Fs);U8 *mouse_drag_source="abcdef";for(mouse_at=0;mouse_drag_source[mouse_at];mouse_at++)DocPutKey(mouse_drag,mouse_drag_source[mouse_at]);', ['0'], 'doc-mouse-drag-new')
            mouse_drag_initial=['TempleOS i386','DolDoc editor','C:/MouseDrag.HC','',
                                'abcdef'+mouse_block]
            mouse_drag_anchor=['TempleOS i386','DolDoc editor','C:/MouseDrag.HC','',
                               'a'+mouse_block+'bcdef']
            mouse_drag_selected=['TempleOS i386','DolDoc editor','C:/MouseDrag.HC','',
                                 'abc'+mouse_block+'def']
            mouse_drag_replaced=['TempleOS i386','DolDoc editor','C:/MouseDrag.HC','',
                                 'aX'+mouse_block+'def']
            submit('DocEd(mouse_drag);', ['1'], 'doc-mouse-drag-editor',interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':mouse_drag_initial,
              'events':[{'mouse_to':[12,36]},
                        {'mouse_button':'left','down':True},
                        {'expect_rows':mouse_drag_anchor,'label':'drag-anchor',
                         'pointer':[12,36]},
                        {'mark_log':'DOC EDIT mouse selection\n'},
                        {'mouse_to':[36,36]},
                        {'wait_log_after':'DOC EDIT mouse selection\n'},
                        {'expect_rows':mouse_drag_selected,'label':'drag-selected',
                         'colors':{(4,1):15,(4,2):15},
                         'backgrounds':{(4,1):0,(4,2):0},'pointer':[36,36]},
                        {'mouse_button':'left','down':False},
                        {'text':'X'}],
              'final_rows':mouse_drag_replaced,'final_pointer':[36,36]})
            submit('U8 *mouse_drag_saved=DocSave(mouse_drag,&mouse_size);mouse_size==6&&mouse_drag_saved[0]==97&&mouse_drag_saved[1]==88&&mouse_drag_saved[2]==5&&mouse_drag_saved[3]==100;', ['1'], 'doc-mouse-drag-canonical-check')
            submit('Free(mouse_drag_saved);DocDel(mouse_drag);', [], 'doc-mouse-drag-delete')
            submit('CDoc *mouse_reverse=DocNew("C:/MouseReverse.HC",Fs);for(mouse_at=0;mouse_drag_source[mouse_at];mouse_at++)DocPutKey(mouse_reverse,mouse_drag_source[mouse_at]);', ['0'], 'doc-mouse-reverse-new')
            mouse_reverse_initial=['TempleOS i386','DolDoc editor','C:/MouseReverse.HC','',
                                   'abcdef'+mouse_block]
            mouse_reverse_anchor=['TempleOS i386','DolDoc editor','C:/MouseReverse.HC','',
                                  'abcde'+mouse_block+'f']
            mouse_reverse_selected=['TempleOS i386','DolDoc editor','C:/MouseReverse.HC','',
                                    'ab'+mouse_block+'cdef']
            mouse_reverse_replaced=['TempleOS i386','DolDoc editor','C:/MouseReverse.HC','',
                                    'abX'+mouse_block+'f']
            submit('DocEd(mouse_reverse);', ['1'], 'doc-mouse-reverse-editor',interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':mouse_reverse_initial,
              'events':[{'mouse_to':[44,36]},
                        {'mouse_button':'left','down':True},
                        {'expect_rows':mouse_reverse_anchor,'label':'reverse-anchor',
                         'pointer':[44,36]},
                        {'mark_log':'DOC EDIT mouse selection\n'},
                        {'mouse_to':[20,36]},
                        {'wait_log_after':'DOC EDIT mouse selection\n'},
                        {'expect_rows':mouse_reverse_selected,'label':'reverse-selected',
                         'colors':{(4,2):15,(4,3):15,(4,4):15,(4,5):15},
                         'backgrounds':{(4,2):0,(4,3):0,(4,4):0,(4,5):0},
                         'pointer':[20,36]},
                        {'mouse_button':'left','down':False},
                        {'text':'X'}],
              'final_rows':mouse_reverse_replaced,'final_pointer':[20,36]})
            submit('U8 *mouse_reverse_saved=DocSave(mouse_reverse,&mouse_size);mouse_size==5&&mouse_reverse_saved[0]==97&&mouse_reverse_saved[1]==98&&mouse_reverse_saved[2]==88&&mouse_reverse_saved[3]==5&&mouse_reverse_saved[4]==102;', ['1'], 'doc-mouse-reverse-canonical-check')
            submit('Free(mouse_reverse_saved);DocDel(mouse_reverse);', [], 'doc-mouse-reverse-delete')
            submit('DirMk("C:/MouseBrowse");', ['1'], 'mouse-picker-directory')
            submit('CDoc *mouse_one=DocNew("C:/MouseBrowse/One.HC",Fs);DocPutKey(mouse_one,\'1\');DocWrite(mouse_one);', ['1'], 'mouse-picker-one')
            submit('CDoc *mouse_two=DocNew("C:/MouseBrowse/Two.HC",Fs);DocPutKey(mouse_two,\'2\');DocWrite(mouse_two);', ['1'], 'mouse-picker-two')
            mouse_picker_one=['TempleOS i386','File picker','C:/MouseBrowse','',
                              '> One.HC','  Two.HC']
            mouse_picker_two=['TempleOS i386','File picker','C:/MouseBrowse','',
                              '  One.HC','> Two.HC']
            submit('EdDir("C:/MouseBrowse");', ['1'], 'mouse-picker-select', interaction={
              'begin':'FILE PICK begin\n','end':'FILE PICK end\n',
              'initial_rows':mouse_picker_one,
              'events':[{'mouse_to':[12,44]},
                        {'mark_log':'FILE PICK mouse selection\n'},
                        {'mouse_button':'left','down':True},
                        {'wait_log_after':'FILE PICK mouse selection\n'},
                        {'mouse_button':'left','down':False},
                        {'expect_rows':mouse_picker_two,'label':'mouse-picker-selected',
                         'pointer':[12,44]},
                        {'delay':0.6},
                        {'mark_log':'FILE PICK mouse selection\n'},
                        {'mouse_button':'left','down':True},
                        {'mouse_button':'left','down':False},
                        {'wait_log_after':'FILE PICK mouse selection\n'},
                        {'mark_log':'FILE PICK mouse activate\n'},
                        {'mark_log':'DOC EDIT begin\n'},
                        {'mouse_button':'left','down':True},
                        {'mouse_button':'left','down':False},
                        {'wait_log_after':'FILE PICK mouse activate\n'},
                        {'wait_log_after':'DOC EDIT begin\n'},
                        {'expect_rows':['TempleOS i386','DolDoc editor','C:/MouseBrowse/Two.HC','',
                                        '2'+mouse_block],
                         'label':'mouse-picker-opened'},
                        {'mark_log':'DOC EDIT end\n'},{'key':'esc'},
                        {'wait_log_after':'DOC EDIT end\n'},
                        {'expect_rows':mouse_picker_two,'label':'mouse-picker-returned',
                         'pointer':[12,44]}],
              'final_rows':mouse_picker_two,'final_pointer':[12,44]})
            submit('DocDel(mouse_two);DocDel(mouse_one);', [], 'mouse-picker-release')
            active_group='file-navigation'
            submit('DirMk("C:/Browse");', ['1'], 'directory-browse-root')
            submit('DirMk("C:/Browse/Sub");', ['1'], 'directory-browse-sub')
            submit('CDoc *browse_doc=DocNew("C:/Browse/Main.HC",Fs);DocPutKey(browse_doc,\'4\');DocPutKey(browse_doc,\'2\');DocWrite(browse_doc);', ['1'], 'directory-browse-file')
            submit('CDoc *browse_other=DocNew("C:/Browse/Other.HC",Fs);DocPutKey(browse_other,\'7\');DocWrite(browse_other);', ['1'], 'directory-browse-other')
            submit('CDoc *browse_nested=DocNew("C:/Browse/Sub/Nested.HC",Fs);DocPutKey(browse_nested,\'9\');DocWrite(browse_nested);', ['1'], 'directory-browse-nested')
            submit('Dir("C:/Browse");', ['./','../','Sub/','Main.HC','Other.HC','5'], 'directory-browse-list')
            submit('Dir("Browse");', ['./','../','Sub/','Main.HC','Other.HC','5'], 'directory-browse-relative')
            submit('Dir("C:/Browse/Missing");', ['-1'], 'directory-browse-missing')
            picker_rows=['TempleOS i386','File picker','C:/Browse','', '> Sub/','  Main.HC','  Other.HC']
            picker_main=['TempleOS i386','File picker','C:/Browse','', '  Sub/','> Main.HC','  Other.HC']
            picker_sub=['TempleOS i386','File picker','C:/Browse/Sub','', '> Nested.HC']
            picker_new=['TempleOS i386','File picker - New file','C:/Browse','',
                        'Name: '+bytes([0xDB]).decode('cp437')]
            picker_new_name=['TempleOS i386','File picker - New file','C:/Browse','',
                             'Name: New.HC'+bytes([0xDB]).decode('cp437')]
            picker_created=['TempleOS i386','File picker','C:/Browse','',
                            '  Sub/','  Main.HC','  Other.HC','> New.HC']
            submit('EdDir("C:/Browse");', ['1'], 'directory-picker', interaction={
              'begin':'FILE PICK begin\n','end':'FILE PICK end\n',
              'initial_rows':picker_rows,
              'events':[{'key':'down'},
                        {'expect_rows':picker_main,'label':'move-down'},
                        {'key':'up'},
                        {'expect_rows':picker_rows,'label':'move-up'},
                        {'key':'ret'},
                        {'expect_rows':picker_sub,'label':'enter-directory'},
                        {'key':'backspace'},
                        {'expect_rows':picker_rows,'label':'parent-directory'},
                        {'key':'down'},
                        {'expect_rows':picker_main,'label':'select-main'},
                        {'key':'ret'},
                        {'expect_rows':['TempleOS i386','DolDoc editor','C:/Browse/Main.HC','',
                                        '42'+bytes([0xDB]).decode('cp437')],
                         'label':'selected-editor'},
                        {'key':'esc'},
                        {'expect_rows':picker_main,'label':'editor-return'},
                        {'key':'n'},
                        {'expect_rows':picker_new,'label':'new-file'},
                        {'text':'New.HC'},
                        {'expect_rows':picker_new_name,'label':'new-file-name'},
                        {'key':'ret'},
                        {'expect_rows':['TempleOS i386','DolDoc editor','C:/Browse/New.HC','',
                                        bytes([0xDB]).decode('cp437')],
                         'label':'new-file-editor'},
                        {'text':'6*7;'},
                        {'expect_rows':['TempleOS i386','DolDoc editor','C:/Browse/New.HC','',
                                        '6*7;'+bytes([0xDB]).decode('cp437')],
                         'label':'new-file-edited'},
                        {'key':'esc'},
                        {'expect_rows':picker_created,'label':'new-file-return'}],
              'final_rows':picker_created})
            submit('CDoc *browse_new=DocRead("C:/Browse/New.HC");I64 browse_new_size;U8 *browse_new_text=DocSave(browse_new,&browse_new_size);browse_new_size==5&&browse_new_text[0]==\'6\'&&browse_new_text[3]==\';\'&&browse_new_text[4]==5;', ['1'], 'directory-picker-new-check')
            submit('Free(browse_new_text);DocDel(browse_new);', [], 'directory-picker-new-release')
            picker_rename=['TempleOS i386','File picker - Rename','C:/Browse','',
                           'New name: '+bytes([0xDB]).decode('cp437')]
            picker_rename_name=['TempleOS i386','File picker - Rename','C:/Browse','',
                                'New name: Renamed.HC'+bytes([0xDB]).decode('cp437')]
            picker_renamed=['TempleOS i386','File picker','C:/Browse','',
                            '  Sub/','  Main.HC','  Other.HC','> Renamed.HC']
            picker_delete=['TempleOS i386','File picker - Delete','C:/Browse','',
                           'Delete Renamed.HC? Y/N']
            picker_after_delete=['TempleOS i386','File picker','C:/Browse','',
                                 '  Sub/','  Main.HC','> Other.HC']
            submit('EdDir("C:/Browse");', ['1'], 'directory-picker-rename', interaction={
              'begin':'FILE PICK begin\n','end':'FILE PICK end\n',
              'initial_rows':['TempleOS i386','File picker','C:/Browse','',
                              '> Sub/','  Main.HC','  Other.HC','  New.HC'],
              'events':[{'key':'down'},{'key':'down'},{'key':'down'},
                        {'expect_rows':picker_created,'label':'delete-select'},
                        {'key':'r'},
                        {'expect_rows':picker_rename,'label':'rename-begin'},
                        {'text':'Renamed.HC'},
                        {'expect_rows':picker_rename_name,'label':'rename-name'},
                        {'key':'ret'},
                        {'expect_rows':picker_renamed,'label':'rename-done'}],
              'final_rows':picker_renamed})
            submit('CDoc *browse_renamed=DocRead("C:/Browse/Renamed.HC");I64 browse_renamed_size;U8 *browse_renamed_text=DocSave(browse_renamed,&browse_renamed_size);', [], 'directory-picker-rename-read')
            submit('!DocRead("C:/Browse/New.HC")&&browse_renamed_size==5&&browse_renamed_text[0]==\'6\'&&browse_renamed_text[3]==\';\'&&browse_renamed_text[4]==5;', ['1'], 'directory-picker-rename-check')
            submit('!FileRename("C:/Browse/Missing.HC","C:/Browse/Other2.HC")&&!FileRename("C:/Browse/Other.HC","C:/Browse/Main.HC")&&!FileRename("C:/Browse/Sub","C:/Browse/Main.HC");', ['1'], 'directory-picker-rename-reject')
            submit('!FileRename("C:/Browse/Other.HC","C:/Browse/Sub/Moved.HC");', ['1'], 'directory-picker-rename-cross-directory')
            submit('Free(browse_renamed_text);DocDel(browse_renamed);', [], 'directory-picker-rename-release')
            submit('EdDir("C:/Browse");', ['0'], 'directory-picker-delete', interaction={
              'begin':'FILE PICK begin\n','end':'FILE PICK end\n',
              'initial_rows':['TempleOS i386','File picker','C:/Browse','',
                              '> Sub/','  Main.HC','  Other.HC','  Renamed.HC'],
              'events':[{'key':'down'},{'key':'down'},{'key':'down'},
                        {'expect_rows':picker_renamed,'label':'delete-select'},
                        {'key':'delete'},
                        {'expect_rows':picker_delete,'label':'delete-confirm'},
                        {'key':'y'},
                        {'expect_rows':picker_after_delete,'label':'delete-done'}],
              'final_rows':picker_after_delete})
            submit('DocRead("C:/Browse/New.HC")==0&&DocRead("C:/Browse/Renamed.HC")==0&&!FileDel("C:/Browse/Renamed.HC");', ['1'], 'directory-picker-delete-check')
            picker_dir_rename=['TempleOS i386','File picker - Rename','C:/Browse','',
                               'New name: '+bytes([0xDB]).decode('cp437')]
            picker_dir_name=['TempleOS i386','File picker - Rename','C:/Browse','',
                             'New name: Code'+bytes([0xDB]).decode('cp437')]
            picker_dir_done=['TempleOS i386','File picker','C:/Browse','',
                             '> Code/','  Main.HC','  Other.HC']
            picker_code=['TempleOS i386','File picker','C:/Browse/Code','',
                         '> Nested.HC']
            submit('EdDir("C:/Browse");', ['1'], 'directory-picker-directory-rename', interaction={
              'begin':'FILE PICK begin\n','end':'FILE PICK end\n',
              'initial_rows':['TempleOS i386','File picker','C:/Browse','',
                              '> Sub/','  Main.HC','  Other.HC'],
              'events':[{'key':'r'},
                        {'expect_rows':picker_dir_rename,'label':'directory-rename-begin'},
                        {'text':'Code'},
                        {'expect_rows':picker_dir_name,'label':'directory-rename-name'},
                        {'key':'ret'},
                        {'expect_rows':picker_dir_done,'label':'directory-rename-done'},
                        {'key':'ret'},
                        {'expect_rows':picker_code,'label':'renamed-directory-enter'},
                        {'key':'backspace'},
                        {'expect_rows':picker_dir_done,'label':'renamed-directory-parent'}],
              'final_rows':picker_dir_done})
            submit('Dir("C:/Browse/Sub");', ['-1'], 'directory-picker-old-directory-absent')
            submit('Dir("C:/Browse/Code");', ['./','../','Nested.HC','3'], 'directory-picker-renamed-directory-list')
            submit('!DirDel("C:/Browse/Code")&&DirMk("C:/Browse/Empty");', ['1'], 'directory-picker-empty-directory-create')
            picker_empty=['TempleOS i386','File picker','C:/Browse','',
                          '  Code/','  Main.HC','  Other.HC','> Empty/']
            picker_empty_delete=['TempleOS i386','File picker - Delete','C:/Browse','',
                                 'Delete empty Empty/? Y/N']
            picker_empty_done=['TempleOS i386','File picker','C:/Browse','',
                               '  Code/','  Main.HC','> Other.HC']
            submit('EdDir("C:/Browse");', ['0'], 'directory-picker-empty-directory-delete', interaction={
              'begin':'FILE PICK begin\n','end':'FILE PICK end\n',
              'initial_rows':['TempleOS i386','File picker','C:/Browse','',
                              '> Code/','  Main.HC','  Other.HC','  Empty/'],
              'events':[{'key':'down'},{'key':'down'},{'key':'down'},
                        {'expect_rows':picker_empty,'label':'empty-directory-select'},
                        {'key':'delete'},
                        {'expect_rows':picker_empty_delete,'label':'empty-directory-confirm'},
                        {'key':'y'},
                        {'expect_rows':picker_empty_done,'label':'empty-directory-deleted'}],
              'final_rows':picker_empty_done})
            submit('Dir("C:/Browse/Empty");', ['-1'], 'directory-picker-empty-directory-absent')
            submit('!DirDel("C:/Browse/Empty");', ['1'], 'directory-picker-empty-directory-repeat')
            submit('DirMk("C:/Browse/Archive")&&FileMove("C:/Browse/Other.HC","C:/Browse/Archive/Moved.HC");', ['1'], 'directory-file-move')
            submit('CDoc *moved_doc=DocRead("C:/Browse/Archive/Moved.HC");I64 moved_size;U8 *moved_text=DocSave(moved_doc,&moved_size);', [], 'directory-file-move-read')
            submit('!DocRead("C:/Browse/Other.HC")&&moved_size==2&&moved_text[0]==\'7\'&&moved_text[1]==5;', ['1'], 'directory-file-move-check')
            submit('!FileMove("C:/Browse/Missing.HC","C:/Browse/Archive/Missing.HC")&&!FileMove("C:/Browse/Main.HC","C:/Browse/Archive/Moved.HC");', ['1'], 'directory-file-move-reject')
            submit('!FileMove("C:/Browse/Code","C:/Browse/Archive/Code");', ['1'], 'directory-file-move-directory-reject')
            submit('Free(moved_text);DocDel(moved_doc);FileMove("C:/Browse/Archive/Moved.HC","C:/Browse/Other.HC");', ['1'], 'directory-file-move-return')
            submit('Dir("C:/Browse/Archive");', ['./','../','2'], 'directory-file-move-empty-destination')
            submit('DirDel("C:/Browse/Archive");', ['1'], 'directory-file-move-cleanup')
            editor_browse_rows=['TempleOS i386','DolDoc editor','C:/Browse/Main.HC','',
                                '42'+bytes([0xDB]).decode('cp437')]
            editor_browse_picker=['TempleOS i386','File picker','C:/Browse','',
                                  '> Code/','  Main.HC','  Other.HC']
            editor_browse_file_rows=['TempleOS i386','DolDoc editor','C:/Browse/Main.HC','',
                                     '42C:/Browse/Other.HC'+bytes([0xDB]).decode('cp437')]
            editor_browse_dir_rows=['TempleOS i386','DolDoc editor','C:/Browse/Main.HC','',
                                    '42C:/Browse/Code'+bytes([0xDB]).decode('cp437')]
            submit('DocEd(browse_doc);', ['1'], 'editor-project-browser', interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':editor_browse_rows,
              'events':[{'mark_log':'FILE PICK begin\n'},{'key':'f4'},
                        {'wait_log_after':'FILE PICK begin\n'},
                        {'expect_rows':editor_browse_picker,'label':'f4-picker'},
                        {'key':'down'},{'key':'down'},
                        {'mark_log':'FILE PICK end\n'},{'key':'ret'},
                        {'wait_log_after':'FILE PICK end\n'},
                        {'expect_rows':editor_browse_file_rows,'label':'f4-file-insert'},
                        {'alt_key':'backspace'},
                        {'expect_rows':editor_browse_rows,'label':'f4-file-undo'},
                        {'mark_log':'FILE PICK begin\n'},{'shift_key':'f4'},
                        {'wait_log_after':'FILE PICK begin\n'},
                        {'expect_rows':editor_browse_picker,'label':'shift-f4-picker'},
                        {'mark_log':'FILE PICK end\n'},{'key':'ret'},
                        {'wait_log_after':'FILE PICK end\n'},
                        {'expect_rows':editor_browse_dir_rows,'label':'shift-f4-directory-insert'},
                        {'alt_key':'backspace'},
                        {'expect_rows':editor_browse_rows,'label':'shift-f4-directory-undo'}],
              'final_rows':editor_browse_rows})
            submit('DocDel(browse_nested);DocDel(browse_other);DocDel(browse_doc);', [], 'directory-browse-delete')
            active_group='document-editing'
            submit('CDoc *wide_doc=DocNew("C:/Wide.DD",Fs);I64 wide_i;', [], 'doc-wide-new')
            submit("for(wide_i=0;wide_i<100;wide_i++)DocPutKey(wide_doc,'a');", ['0'], 'doc-wide-fill')
            submit('DocEd(wide_doc);', ['1'], 'doc-wide-editor',interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/Wide.DD','',
                              'a'*79+bytes([0xDB]).decode('cp437')],
              'events':[{'key':'home'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/Wide.DD','',
                            bytes([0xDB]).decode('cp437')+'a'*79],
            })
            submit('DocDel(wide_doc);', [], 'doc-wide-delete')
            submit('#include "/Kernel/I386/DocBinaryPersistenceCheck.HC"', [], 'doc-binary-persistence-definition')
            submit('DocBinaryPersistenceCheck;', ['8'], 'doc-binary-persistence-check')
            active_group='document-compatibility'
            submit('CDoc *original_compat=DocRead("C:/Probe/OriginalCompat.DD");', [], 'doc-original-cross-read')
            submit('I64 original_compat_size;U8 *original_compat_text=DocSave(original_compat,&original_compat_size);', [], 'doc-original-cross-save')
            submit('I64 original_compat_i,original_compat_hash=0;', [], 'doc-original-cross-hash-init')
            submit('for(original_compat_i=0;original_compat_i<original_compat_size;original_compat_i++)original_compat_hash=original_compat_hash*257+original_compat_text[original_compat_i];', ['0'], 'doc-original-cross-hash')
            submit('original_compat&&original_compat_size==48&&original_compat_text[0]==\'O\'&&original_compat_text[8]==10&&original_compat_text[9]==36&&original_compat_text[10]==\'S\'&&original_compat_text[14]==\'c\';', ['1'], 'doc-original-cross-text-check')
            submit('original_compat_text[26]==0&&original_compat_text[43]==1&&original_compat_text[47]==42;', ['1'], 'doc-original-cross-binary-check')
            submit('(original_compat_hash&0xFFFFFFFF)==0x4ABAF862;', ['1'], 'doc-original-cross-exact-check')
            submit('Free(original_compat_text);DocDel(original_compat);', [], 'doc-original-cross-delete')
            active_group='help'
            submit('I64 HelpHeap(U8 *name){I64 before=Fs->data_heap->used_u8s;Help(name);return Fs->data_heap->used_u8s-before;}', [], 'help-heap-function')
            help_rows=['TempleOS i386','Help: C:/Doc/CompilerOverview.DD','',
                       'Compiler Index','', '::/Doc/Asm.DD','',
                       '::/Doc/Directives.DD','', '::/Doc/Options.DD','',
                       '::/Doc/PreProcessor.DD','', '::/Doc/ScopingLinkage.DD','',
                       'See Hello World.']
            help_selected_colors={(5,index):15 for index in range(len('::/Doc/Asm.DD'))}
            help_selected_backgrounds={(5,index):1 for index in range(len('::/Doc/Asm.DD'))}
            asm_rows=['TempleOS i386','Help: C:/Doc/Asm.DD','','Assembler','',
                      "See ::/Compiler/OpCodes.DD for opcodes.  They're not standard.  Some invalid ins",
                      'ts are not flagged and some valid insts are not implemented. 16-bit asm support ',
                      'is limited.','','Here are example inst formats:',
                      '        ADD     RAX,I64 FS:DISP[RSI+RDI*8]',
                      '        ADD     RAX,I64 [DISP]','',
                      '$ Current compiler output pos (inst ptr).  Even works in HolyC expressions.','',
                      '$ works in classes.','  class MyFun','  {','    $=-16;',
                      '    I64 local1;','    I64 local2;','    $=$+256;','    I64 crazy;','  };','',
                      'LABEL::','  Defines an exported glbl label.','','LABEL:',
                      '  Defines an non-exported glbl label.','','@@LABEL:',
                      '  Defines a local label with scope valid between two global labels.','',
                      'DU8, DU16, DU32, DU64',
                      '  Define BYTE, WORD, DWORD or QWORD. Can be used with DUP() and ASCII strings.  ',
                      'For your convenience, the ASCII strings do not have terminating zeros.  Define c',
                      'mds must end with a semicolon.','','USE16, USE32, USE64','',
                      'IMPORT sym1name, sym2name;','','LIST, NOLIST','',
                      'ALIGN num, fill_byte','  Align to num boundary and fill with fill_byte.','',
                      'ORG num',
                      '  Set code addr for JIT or set module Load() addr -- has 16-byte CBinFile header',
                      ' and patch table trailing.','','BINFILE "FileName.BIN";','',
                      'See Assembly Language, ::/Demo/Asm/AsmAndC1.HC, ::/Demo/Asm/AsmAndC2.HC and ::/D',
                      'emo/Asm/AsmAndC3.HC.','']
            submit('HelpHeap("C:/Doc/CompilerOverview.DD");', ['0'], 'help-compiler-overview', interaction={
              'begin':'HELP VIEW begin\n','end':'HELP VIEW end\n',
              'initial_rows':help_rows,
              'events':[{'key':'right'},
                        {'expect_rows':help_rows,'colors':help_selected_colors,
                         'backgrounds':help_selected_backgrounds,'label':'link-selected'},
                        {'key':'ret'},{'expect_rows':asm_rows,'label':'link-opened'},
                        {'key':'esc'},
                        {'expect_rows':help_rows,'colors':help_selected_colors,
                         'backgrounds':help_selected_backgrounds,'label':'link-returned'},
                        {'key':'esc'}],
              'final_rows':help_rows,'final_colors':help_selected_colors,
              'final_backgrounds':help_selected_backgrounds})
            active_group='mouse'
            submit('Help("C:/Doc/CompilerOverview.DD");', ['1'], 'mouse-help-link', interaction={
              'begin':'HELP VIEW begin\n','end':'HELP VIEW end\n',
              'initial_rows':help_rows,
              'events':[{'mouse_to':[12,44]},
                        {'mark_log':'HELP mouse selection\n'},
                        {'mouse_button':'left','down':True},
                        {'wait_log_after':'HELP mouse selection\n'},
                        {'mouse_button':'left','down':False},
                        {'mouse_to':[120,44]},
                        {'expect_rows':help_rows,'colors':help_selected_colors,
                         'backgrounds':help_selected_backgrounds,
                         'pointer':[120,44],'label':'mouse-help-selected'},
                        {'mouse_to':[12,44]},
                        {'delay':0.6},
                        {'mark_log':'HELP mouse selection\n'},
                        {'mouse_button':'left','down':True},
                        {'mouse_button':'left','down':False},
                        {'wait_log_after':'HELP mouse selection\n'},
                        {'mark_log':'HELP mouse activate\n'},
                        {'mark_log':'HELP VIEW begin\n'},
                        {'mouse_button':'left','down':True},
                        {'mouse_button':'left','down':False},
                        {'wait_log_after':'HELP mouse activate\n'},
                        {'wait_log_after':'HELP VIEW begin\n'},
                        {'expect_rows':asm_rows,'label':'mouse-help-opened'},
                        {'mark_log':'HELP VIEW end\n'},{'key':'esc'},
                        {'wait_log_after':'HELP VIEW end\n'},
                        {'mouse_to':[120,44]},
                        {'expect_rows':help_rows,'colors':help_selected_colors,
                         'backgrounds':help_selected_backgrounds,
                         'pointer':[120,44],'label':'mouse-help-returned'}],
              'final_rows':help_rows,'final_colors':help_selected_colors,
              'final_backgrounds':help_selected_backgrounds,
              'final_pointer':[120,44]})
            active_group='help'
            cmd_rows=['TempleOS i386','Help: C:/Doc/CmdLineOverview.DD','','Command Line Overview','',
                      'The cmd line feeds into the HolyC compiler line-by-line as you type.  A stmt out',
                      'side a function executes immediately.  Remember to add a semicolon.','',
                      'Look-up the function headers with AutoComplete by hitting <CTRL-SHIFT-F1> after ',
                      'typing the first few letters.','','Click Here to see the directory cmd header.  It accepts default args from C++.','',
                      '>Dir("*.DD.Z");','',"If you don't have args, you don't need parenthesis.",'','>Dir;','',
                      'Directories are referenced with / not \\.  There is a current directory, but not ',
                      'a path.  To run a program, you typically #include it.  There are several shortcu',
                      'ts for #includeing files.  Right-click or hit <ENTER> on a directory listing or ',
                      'press <F5> while editing.','',
                      '>Ed("NewFile.HC.Z");    Invokes the editor. See Doc Link Type.','',
                      'Most filenames end in .Z because they are stored compressed.','',
                      "Drives are specified with a letter.  The boot drive is specified with a ':'.  Th",
                      "e home dir drive is specified with a '~'.",'',">Drv('B');      B drive",'',
                      'The drive can be specified in a Cd() command as in:','',
                      '>Cd("B:/Tmp");  B drive','>Cd("::/Demo"); Boot drive','',
                      "The home directory is specified with a '~'.",'',
                      '>Cd("~/Psalmody");      See ::/Home dir.','',
                      'If a file is not found, .Z is added or removed and a search is done, again.  If ',
                      'a file is still not found, all parent directories are searched.','',
                      'You can place macros in your PersonalMenu for Cd() commands.  <CTRL-m> to access',
                      ' your menu.','',
                      '>Find("needle","/Demo/*.HC.Z;*.DD.Z;"); See File Utils.','',
                      'Cmd Line Routines','','Take Tour','']
            cmd_selected_colors={(11,index):15 for index in range(10)}
            cmd_selected_backgrounds={(11,index):1 for index in range(10)}
            dir_source_rows=['TempleOS i386','Help: C:/Kernel/I386/PublicFiles.HH','',
                             'public _extern _DIR I64 Dir(U8 *filename=NULL);',
                             'public _extern _ED_DIR Bool EdDir(U8 *directory=NULL);',
                             'public _extern _FILE_DEL Bool FileDel(U8 *filename);',
                             'public _extern _FILE_RENAME Bool FileRename(U8 *old_filename,U8 *new_filename);',
                             'public _extern _DIR_DEL Bool DirDel(U8 *filename);',
                             'public _extern _FILE_MOVE Bool FileMove(U8 *old_filename,U8 *new_filename);',
                             '#endif','']
            submit('CHashSrcSym *help_mn_symbol=HashFind("Dir",Fs->hash_table,HTG_SRC_SYM);', [], 'help-man-page-symbol')
            submit('help_mn_symbol!=0;', ['1'], 'help-man-page-symbol-present')
            submit('help_mn_symbol->src_link!=0;', ['1'], 'help-man-page-source-present')
            submit('HelpHeap("C:/Doc/CmdLineOverview.DD");', ['0'], 'help-man-page-link', interaction={
              'begin':'HELP VIEW begin\n','end':'HELP VIEW end\n','initial_rows':cmd_rows,
              'events':[{'key':'right'},{'key':'right'},
                        {'expect_rows':cmd_rows,'colors':cmd_selected_colors,
                         'backgrounds':cmd_selected_backgrounds,'label':'mn-selected'},
                        {'mark_log':'HELP VIEW begin\n'},{'key':'ret'},
                        {'wait_log':'HELP OPEN C:/Kernel/I386/PublicFiles.HH\n'},
                        {'wait_log_after':'HELP VIEW begin\n'},
                        {'expect_rows':dir_source_rows,'label':'mn-source-line'},
                        {'key':'esc'},
                        {'expect_rows':cmd_rows,'colors':cmd_selected_colors,
                         'backgrounds':cmd_selected_backgrounds,'label':'mn-returned'},
                        {'key':'esc'}],
              'final_rows':cmd_rows,'final_colors':cmd_selected_colors,
              'final_backgrounds':cmd_selected_backgrounds})
            doldoc_rows=['TempleOS i386','Help: C:/Doc/DolDoc.DD','',
                         'A DolDoc in memory is a Circular Queue of cmds and graphics.  See CDocEntry for ',
                         'the entry structure.  See TipOfDay() for a nice example.','',
                         "DolDoc's are used for the editor, viewer, browser, and cmd line.",'']
            index_selected_colors={(3,index):15 for index in range(24,38)}
            index_selected_backgrounds={(3,index):1 for index in range(24,38)}
            category_rows=['TempleOS i386','Help: HI:Data Types/Circular Queue','',
                           'Data Types/Circular Queue','','C:/Doc/Que.DD.Z','',
                           'CCPU','CWinScroll','CQue','CTask','QueInit','QueInsRev',
                           'QueIns','QueRem','']
            category_selected_colors={(5,index):15 for index in range(len('C:/Doc/Que.DD.Z'))}
            category_selected_backgrounds={(5,index):1 for index in range(len('C:/Doc/Que.DD.Z'))}
            submit('HelpHeap("C:/Doc/DolDoc.DD");', ['0'], 'help-index-link', interaction={
              'begin':'HELP VIEW begin\n','end':'HELP VIEW end\n','initial_rows':doldoc_rows,
              'events':[{'key':'right'},{'key':'right'},
                        {'expect_rows':doldoc_rows,'colors':index_selected_colors,
                         'backgrounds':index_selected_backgrounds,'label':'hi-selected'},
                        {'mark_log':'HELP VIEW begin\n'},{'key':'ret'},
                        {'wait_log':'HELP OPEN HI:Data Types/Circular Queue\n'},
                        {'wait_log_after':'HELP VIEW begin\n'},
                        {'expect_rows':category_rows,'label':'hi-category'},
                        {'key':'right'},
                        {'expect_rows':category_rows,'colors':category_selected_colors,
                         'backgrounds':category_selected_backgrounds,'label':'hi-category-selected'},
                        {'mark_log':'HELP VIEW begin\n'},{'key':'ret'},
                        {'wait_log':'HELP OPEN C:/Doc/Que.DD.Z\n'},
                        {'wait_log_after':'HELP VIEW begin\n'},{'key':'esc'},
                        {'expect_rows':category_rows,'colors':category_selected_colors,
                         'backgrounds':category_selected_backgrounds,'label':'hi-category-returned'},
                        {'key':'esc'},
                        {'expect_rows':doldoc_rows,'colors':index_selected_colors,
                         'backgrounds':index_selected_backgrounds,'label':'hi-returned'},
                        {'key':'esc'}],
              'final_rows':doldoc_rows,'final_colors':index_selected_colors,
              'final_backgrounds':index_selected_backgrounds})
            search_rows=['TempleOS i386','Help: C:/Probe/HelpSearch.DD','',
                         'Find section','']
            search_selected_colors={(3,index):15 for index in range(len('Find section'))}
            search_selected_backgrounds={(3,index):1 for index in range(len('Find section'))}
            search_target_rows=['TempleOS i386','Help: C:/Probe/HelpSearchTarget.DD','',
                                'Needle heading','Second body','']
            submit('HelpHeap("C:/Probe/HelpSearch.DD");', ['0'], 'help-find-link', interaction={
              'begin':'HELP VIEW begin\n','end':'HELP VIEW end\n','initial_rows':search_rows,
              'events':[{'key':'right'},
                        {'expect_rows':search_rows,'colors':search_selected_colors,
                         'backgrounds':search_selected_backgrounds,'label':'ff-selected'},
                        {'mark_log':'HELP VIEW begin\n'},{'key':'ret'},
                        {'wait_log':'HELP OPEN C:/Probe/HelpSearchTarget.DD\n'},
                        {'wait_log_after':'HELP VIEW begin\n'},
                        {'expect_rows':search_target_rows,'label':'ff-target'},
                        {'key':'esc'},
                        {'expect_rows':search_rows,'colors':search_selected_colors,
                         'backgrounds':search_selected_backgrounds,'label':'ff-returned'},
                        {'key':'esc'}],
              'final_rows':search_rows,'final_colors':search_selected_colors,
              'final_backgrounds':search_selected_backgrounds})
            anchor_rows=['TempleOS i386','Help: C:/Probe/HelpAnchor.DD','',
                         'Anchor section','']
            anchor_selected_colors={(3,index):15 for index in range(len('Anchor section'))}
            anchor_selected_backgrounds={(3,index):1 for index in range(len('Anchor section'))}
            anchor_target_rows=['TempleOS i386','Help: C:/Probe/HelpAnchorTarget.DD','',
                                'Wanted heading','Anchor body','']
            submit('HelpHeap("C:/Probe/HelpAnchor.DD");', ['0'], 'help-anchor-link', interaction={
              'begin':'HELP VIEW begin\n','end':'HELP VIEW end\n','initial_rows':anchor_rows,
              'events':[{'key':'right'},
                        {'expect_rows':anchor_rows,'colors':anchor_selected_colors,
                         'backgrounds':anchor_selected_backgrounds,'label':'fa-selected'},
                        {'mark_log':'HELP VIEW begin\n'},{'key':'ret'},
                        {'wait_log':'HELP OPEN C:/Probe/HelpAnchorTarget.DD\n'},
                        {'wait_log_after':'HELP VIEW begin\n'},
                        {'expect_rows':anchor_target_rows,'label':'fa-target'},
                        {'key':'esc'},
                        {'expect_rows':anchor_rows,'colors':anchor_selected_colors,
                         'backgrounds':anchor_selected_backgrounds,'label':'fa-returned'},
                        {'key':'esc'}],
              'final_rows':anchor_rows,'final_colors':anchor_selected_colors,
              'final_backgrounds':anchor_selected_backgrounds})
            active_group='document-sprites'
            submit('#include "/Kernel/I386/DocSpriteRenderCheck.HC"', [], 'doc-sprite-render-definition')
            submit('DocSpriteRenderStart;', ['23'], 'doc-sprite-render-start')
            sprite_rows=['TempleOS i386','DolDoc editor','C:/SpriteRender.DD','']
            sprite_pixels={(x,y):4 for y in range(32,40) for x in range(16)}
            submit('DocEd(sprite_render_doc);', ['1'], 'doc-sprite-render-editor', interaction={
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':sprite_rows,'initial_pixels':sprite_pixels,
              'events':[],'final_rows':sprite_rows,'final_pixels':sprite_pixels})
            submit('DocDel(sprite_render_doc);sprite_render_doc=0;', ['0x0'], 'doc-sprite-render-delete')
            active_group='document-editing'
            submit('DocAllocationCheck;', ['12'], 'doc-allocation-check')
            active_group='documents'
            submit('#include "/Kernel/I386/DocReportCheck.HC"', [], 'doc-report-definition')
            submit('DocReportStateCheck;', ['Doc report', 'IRQ-off report', '1'], 'doc-report-check')
            for source,answer,label in [('DocEntryDel(0,0);42;', 'DocEntryDel42', 'doc-entry-error'),
                                        ('DocBinDel(0,0);42;', 'DocBinDel42', 'doc-bin-error')]:
                started=time.monotonic()
                submit(source, [answer], label)
                if (groups is None or 'documents' in groups) and time.monotonic()-started<3: raise ValueError('Document diagnostic pause missing')
            active_group='text'
            submit('#include "/Kernel/I386/TextBaseCheck.HC"', [], 'text-base-definition')
            submit('TextBaseCheck(i386_text_base,&TextChar,&TextLenStr,&TextLenAttrStr,&TextLenAttr);', ['12'], 'text-base-check')
            if 'INPUT RESET' in log.read_text(): raise ValueError('Unexpected keyboard queue loss')
            if groups is not None:
                result={'result':'pass','groups':list(groups),'native_commands':submitted,
                        'cpu':cpu,'ram_mib':8,'startup_seconds':startup_seconds,
                        'boot_mode':'diagnostic' if diagnostics else 'interactive',
                        'disk_sha256':hashlib.sha256(disk.read_bytes()).hexdigest(),
                        'vga':'all pixels matched at each checkpoint',
                        'interaction_latencies_seconds':interaction_latencies}
                (out/'result.json').write_text(json.dumps(result,indent=2)+'\n')
                return result
            result={'result':'pass','cpu':cpu,'ram_mib':8,
                    'boot_mode':'diagnostic' if diagnostics else 'interactive',
                        'startup_seconds':startup_seconds,
                    'vga_uploads':len(uploads()), 'vga_text_rows':sum(uploads()),
                    'vga_payload_bytes':sum(uploads())*2560,
                    'ordinary_edit_payload_bytes':2560,
                    'interaction_latencies_seconds':interaction_latencies,
                    'checks':['make/break','shift','backspace','cancel','wrap','tab','scroll','native compilation','multirow source input','public allocation API','persistent definitions','error recovery','integer and F64 answers','20 bounded document development cycles with exact task data/code heap recovery'],
                    'vga':'all pixels matched at each checkpoint',
                    'submitted_lines':sum(1 for line in log.read_text().splitlines() if line.startswith('INPUT LINE ')),
                    'native_commands':submitted, 'window_service_cases':14, 'window_visibility_cases':6, 'window_text_cases':10, 'graphics_frames':4, 'graphics_frame_cases':5, 'graphics_allocation_cases':2, 'graphics_context_cases':20, 'date_checks':1333, 'public_math_checks':4107, 'definition_lookup_cases':16, 'definition_missing_cases':4, 'text_frames':4, 'keyboard_break_cases':11, 'document_lock_cases':11, 'document_access_cases':8, 'document_lifecycle_cases':7, 'document_basic_edit_cases':5, 'document_basic_multiline_cases':7, 'document_basic_navigation_cases':8, 'document_basic_vertical_cases':8, 'document_basic_boundary_cases':13, 'document_basic_save_cases':5, 'document_allocation_cases':12, 'document_session_resource_cycles':20, 'document_session_exact_heap_recovery':'shared task heap', 'document_session_peak_tracking':'allocator high-water'}
            (out/'result.json').write_text(json.dumps(result,indent=2)+'\n')
            return result
        finally:
            if proc.poll() is None: proc.terminate()
            try: proc.wait(timeout=5)
            except subprocess.TimeoutExpired: proc.kill(); proc.wait()
            sock.close(); qmp.unlink(missing_ok=True)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path,nargs='?',default=ROOT/'build/i386-kernel/kernel.img')
    parser.add_argument('--out',type=Path,default=ROOT/'build/i386-focused')
    parser.add_argument('--group',action='append',choices=GROUPS,help='Repeat to select groups; omitted runs the full console suite')
    parser.add_argument('--list-groups',action='store_true')
    parser.add_argument('--diagnostics',action='store_true',help='Expect the diagnostic boot image')
    parser.add_argument('--cpu',default='486',help='QEMU CPU model (default: 486)')
    args=parser.parse_args()
    if args.list_groups:
        print('\n'.join(GROUPS)); return
    print(run_input(args.disk,args.out,diagnostics=args.diagnostics,groups=args.group,cpu=args.cpu))


if __name__=='__main__': main()
