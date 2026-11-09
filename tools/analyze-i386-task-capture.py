#!/usr/bin/env python3
"""Inspect public tasks and suspended callers in a stopped i386 RAM capture."""
import argparse
import bisect
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct

ROOT = Path(__file__).resolve().parents[1]
# Published layout assertions: CompilerTaskLayoutProbe.HC and Scheduler.HH.
FIELDS = dict(next_task=92,last_task=96,parent=88,put_doc=36,display_doc=40,task_flags=20,
              next_settings=804,hash_table=824,popup_task=908,esp=992,owner=1004,
              finished=1008,blocked=1012,cleanup=1032,finishing=1036,except_top=1044,
              io_locks=1048,file_state=1052,lifetime_refs=1064,symbol_state=1068,
              active_controls=1084,compiler_failed=1088,compiler_busy=1092,wait=1108)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def analyze(image, memory, registers, log):
    def u32(address):
        if not 0 <= address <= len(memory)-4:
            raise ValueError('Address outside captured memory: '+hex(address))
        return struct.unpack_from('<I',memory,address)[0]

    def u64(address):
        if not 0 <= address <= len(memory)-8:
            raise ValueError('Address outside captured memory: '+hex(address))
        return struct.unpack_from('<Q',memory,address)[0]

    def string(address,limit=150):
        if not 0 < address < len(memory):
            return ''
        return memory[address:address+limit].split(b'\0')[0].decode('ascii',errors='replace')

    tasks = []
    offset = 0
    while True:
        offset = memory.find(struct.pack('<I',0x536B7354),offset)
        if offset < 0:
            break
        address = offset-4
        offset += 4
        if address < 0 or address+1112 > len(memory) or u32(address) != address:
            continue
        task = {name:u32(address+field) for name,field in FIELDS.items()}
        task.update(address=address,name=string(address+520,48),title=string(address+376,144),
                    task_num=u64(address+884),stack=u32(address+704))
        tasks.append(task)
    if not tasks:
        raise ValueError('No self-identifying public tasks in capture')
    symbols, tables, task_layouts = {}, set(), set()
    for task in tasks:
        table = task['hash_table']
        while table and table not in tables:
            tables.add(table)
            mask,body = u64(table+4),u32(table+20)
            if mask > 0xffff or not 0 < body <= len(memory)-4*(mask+1):
                raise ValueError('Invalid public hash table')
            for slot in range(mask+1):
                node,chain = u32(body+4*slot),set()
                while node:
                    if node in chain:
                        raise ValueError('Cyclic public hash chain')
                    chain.add(node)
                    kind,name = u32(node+8),string(u32(node+4))
                    if kind&16 and name=='CTask' and memory[node+56]==0:
                        task_layouts.add(u64(node+36))
                    if kind&64 and not struct.unpack_from('<H',memory,node+58)[0]&(1<<12):
                        # Ff_INTERNAL entries store builtin IDs, not executable pointers.
                        entry = u32(node+100)
                        if 0 < entry < len(memory) and name:
                            symbols[entry] = name
                    node = u32(node)
            table = u32(table)
    if task_layouts != {992}:
        raise ValueError('Captured CTask metadata differs from the published layout')
    files = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['snapshot'](image)[1]
    globals_ = {}
    kernel_base = struct.unpack_from('<I',image,540)[0]+8
    for module,marker in [('Kernel',None),('CompilerRuntime','RUNTIME'),('MemoryRuntime','MEMORY'),
                          ('FileRuntime','FILES'),('ConsoleRuntime','CONSOLE')]:
        match = re.search('^'+marker+r' ([0-9A-Fa-f]+)',log,re.M) if marker else None
        if marker and not match:
            continue
        base = int(match[1],16)+8 if marker else kernel_base
        data = files['/Modules/I386/'+module+'.t32m'][2]
        _,count,records = struct.unpack_from('<III',data,16)
        for index in range(count):
            kind,relative,name,length = struct.unpack_from('<4I',data,records+16*index)
            label = data[name:name+length].decode('ascii')
            if kind==1:
                symbols[base+relative] = module+':'+label
            elif kind==3:
                globals_[module+':'+label] = base+relative
    ordered = sorted(symbols)

    def describe(address):
        index = bisect.bisect_right(ordered,address)-1
        result = dict(address=address)
        if index >= 0:
            base = ordered[index]
            result.update(nearest_symbol=symbols[base],offset=address-base)
        return result

    active_match = re.search(r'^FS\s*=[0-9A-Fa-f]+\s+([0-9A-Fa-f]+)',registers,re.M)
    active = int(active_match[1],16) if active_match else 0
    ebp_match = re.search(r'\bEBP=([0-9A-Fa-f]+)',registers)
    eip_match = re.search(r'\bEIP=([0-9A-Fa-f]+)',registers)
    for task in tasks:
        stack = task['stack']
        if stack:
            low,high = stack+20,stack+20+u64(stack+4)
            if not 0 < low < high <= len(memory):
                raise ValueError('Invalid public task stack bounds')
        elif task['owner'] and u32(task['owner'])==task['address']:
            # The immortal boot root has no public CTaskStk record.
            low,high = 0,0
        else:
            raise ValueError('Non-root task has no public stack bounds')
        task['stack_bounds'] = [low,high] if stack else None
        esp = task['esp']
        ebp = u32(esp+24)
        task['active_cpu'] = task['address']==active
        if task['active_cpu'] and ebp_match:
            ebp = int(ebp_match[1],16)
            if eip_match:
                task['cpu_entry'] = describe(int(eip_match[1],16))
        task['suspended_entry'] = describe(u32(esp+52))
        task['frames'] = []
        for depth in range(32):
            if not low <= ebp <= high-8 or ebp&3:
                break
            parent,entry = u32(ebp),u32(ebp+4)
            task['frames'].append(dict(frame=ebp,return_address=describe(entry)))
            if parent <= ebp:
                break
            ebp = parent
    scopes,seen = [],set()
    head = globals_.get('ConsoleRuntime:native_render_scopes')
    cursor = u32(head) if head else 0
    while cursor:
        if cursor in seen or len(seen)>1024:
            raise ValueError('Invalid render-scope chain')
        seen.add(cursor)
        fields = struct.unpack_from('<8I',memory,cursor)
        scopes.append(dict(address=cursor,task=fields[1],release=describe(fields[3]),
                           resource_owner=fields[5],window_owner=fields[6],resource=fields[7],
                           retiring=bool(memory[cursor+32]),legacy_view=bool(memory[cursor+33])))
        cursor = fields[0]
    return dict(tasks=tasks,render_scopes=scopes,active_task=active,
                winmgr_updates=u64(globals_['ConsoleRuntime:winmgr']) if 'ConsoleRuntime:winmgr' in globals_ else None,
                symbol_count=len(symbols),task_layout=992)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('capture',type=Path)
    parser.add_argument('--image',type=Path,required=True)
    parser.add_argument('--boot-log',type=Path,required=True)
    parser.add_argument('--out',type=Path,required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output path')
    folder = args.capture
    memory,registers = folder/'failure-memory.bin',folder/'failure-registers.txt'
    inputs = [memory,registers,args.image,args.boot_log,Path(__file__).resolve(),
              ROOT/'tools/package-i386-native-image.py',ROOT/'Kernel/I386/CompilerTaskLayoutProbe.HC',
              ROOT/'Kernel/I386/Scheduler.HH',ROOT/'Kernel/SymbolTypes.HH']
    pins = {str(p.resolve()):sha(p) for p in inputs}
    result = analyze(args.image.read_bytes(),memory.read_bytes(),registers.read_text(),args.boot_log.read_text(errors='replace'))
    result.update(result='analyzed',input_sha256=pins,
                  scope='Stopped public task/context/render-scope state; nearest symbols are hints, not proof of a stall cause')
    result['inputs_unchanged'] = all(sha(Path(p))==h for p,h in pins.items())
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(dict(result=result['result'],tasks=len(result['tasks']),render_scopes=len(result['render_scopes']))))


if __name__=='__main__':
    main()
