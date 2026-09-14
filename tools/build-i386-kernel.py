#!/usr/bin/env python3
"""Cross-build a standalone native kernel foundation and optionally boot-check it."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
MODULES = ('Kernel', 'SysTry', 'TaskContext', 'ExceptContext', 'IrqEntry', 'ExceptionEntry')
DISK_MODULES = MODULES + ('Startup', 'CompilerRuntime', 'CompilerProbe', 'FileRuntime')


def run(*args):
    subprocess.run(args, cwd=ROOT, check=True)


def verify_startup_rejection(disk, volume, out):
    """Prove startup reads and validates the disk module before invoking it."""
    original=disk.read_bytes()
    entry=volume['files']['/Modules/I386/Startup.t32m']
    offset=entry['block']*512
    module=original[offset:offset+entry['size']]
    count,records=struct.unpack_from('<II',module,20)
    imported=[]
    for i in range(count):
        kind,_,name,length=struct.unpack_from('<4I',module,records+16*i)
        if kind==5 and module[name:name+length]==b'kernel_startup_count':
            imported.append(name)
    if not imported: raise ValueError('Missing startup resident-data import')
    results=[]
    for label,position,value in [('wrong-target',6,4),('missing-import',imported[0],ord('X'))]:
        work=out/f'reject-{label}'
        work.mkdir(parents=True,exist_ok=True)
        changed=bytearray(original)
        changed[offset+position]=value
        candidate=work/'kernel.img'
        candidate.write_bytes(changed)
        with (work/'runner.log').open('w') as log:
            result=subprocess.run([sys.executable,str(ROOT/'tools/guest-run.py'),str(candidate),
                '--i386-disk','--out',str(work),'--timeout','60'],cwd=ROOT,stdout=log,stderr=log)
        evidence=(work/'debug.log').read_text()
        if (result.returncode==0 or 'FAIL native kernel\n' not in evidence
                or 'SOURCE ' not in evidence or any(line.startswith('MODULE ') for line in evidence.splitlines())
                or any(marker in evidence for marker in
                    ('STARTUP disk module','READY native kernel','DONE native kernel'))):
            raise ValueError(f'Startup did not reject {label} before execution')
        if candidate.read_bytes()!=changed: raise ValueError('Rejected startup changed disk')
        results.append(label)
    return results


def compiler_runtime_layout(module):
    size, count, records = struct.unpack_from('<III', module, 16)
    exports, imports = {}, []
    for index in range(count):
        kind, offset, name, length = struct.unpack_from('<4I', module, records+16*index)
        if kind in (1, 2, 3, 5):
            symbol = module[name:name+length].decode('ascii')
            if kind in (1, 3):
                exports[symbol] = (kind, offset)
            else:
                imports.append((symbol, name))
    if {name for name, _ in imports} != {'I386LexRawChar', 'I386LexSourceRead', 'char_bmp_hex_numeric', 'char_bmp_dec_numeric', 'char_bmp_non_eol', 'HashFind', 'StrCmp', 'I386HeapAlloc', 'I386HeapFree', 'I386HeapSize', 'I386IrqSave', 'I386IrqRestore', 'I386LexIncludeCopy', 'HashAdd', 'char_bmp_non_eol_white_space', 'I386LexFilePush', 'LexFileReleaseTop'}:
        raise ValueError('Unexpected compiler-runtime import contract')
    for name in ('Main', 'I386LexStringChunk', 'I386LexNumber', 'I386LexChar', 'I386RuntimePunct', 'I386LexIdentScan', 'I386LexIdentToken', 'I386LexStringToken', 'I386RuntimeLexNext', 'I386RuntimeLexIncludes', 'I386CmpCtrlNew', 'I386CmpCtrlDel'):
        if name not in exports or exports[name][0] != 1:
            raise ValueError(f'Missing compiler-runtime function {name}')
    if exports.get('compiler_runtime_version', (0, 0))[0] != 3:
        raise ValueError('Missing compiler-runtime interface version')
    version_offset = 32+exports['compiler_runtime_version'][1]
    if version_offset+4 > 32+size or struct.unpack_from('<I', module, version_offset)[0] != 11:
        raise ValueError('Unexpected compiler-runtime interface version')
    return dict(image_bytes=size+8, string_offset=8+exports['I386LexStringChunk'][1],
                number_offset=8+exports['I386LexNumber'][1], char_offset=8+exports['I386LexChar'][1],
                punct_offset=8+exports['I386RuntimePunct'][1], ident_offset=8+exports['I386LexIdentScan'][1],
                ident_token_offset=8+exports['I386LexIdentToken'][1], string_token_offset=8+exports['I386LexStringToken'][1],
                next_offset=8+exports['I386RuntimeLexNext'][1], include_offset=8+exports['I386RuntimeLexIncludes'][1], control_new_offset=8+exports['I386CmpCtrlNew'][1], control_del_offset=8+exports['I386CmpCtrlDel'][1], version_offset=version_offset,
                import_offset=next(offset for name, offset in imports if name == 'I386LexRawChar'))


def file_runtime_layout(module):
    size, count, records = struct.unpack_from('<III', module, 16)
    exports, imports = {}, {}
    for index in range(count):
        kind, offset, name, length = struct.unpack_from('<4I', module, records+16*index)
        if kind in (1, 2, 3, 5):
            symbol = module[name:name+length].decode('ascii')
            if kind in (1, 3): exports[symbol] = (kind, offset)
            else: imports[symbol] = name
    if set(imports) != {'I386HeapAlloc', 'I386HeapFree', 'I386HeapSize', 'I386IrqSave',
            'I386IrqRestore', 'I386RedSeaFind', 'I386RedSeaResolve', 'I386RedSeaReadAll', 'I386LexIncludeTake', 'I386RedSeaBegin', 'I386RedSeaEnd', 'I386RedSeaValid', 'I386AtaIdentifyPolled', 'I386AtaTransfer', 'I386AtaFlushPolled', 'I386SchedBlock', 'I386SchedWake', 'I386SchedYield'}:
        raise ValueError('Unexpected file-runtime import contract')
    for name in ('Main', 'I386LexTaskFileInclude', 'I386TaskFileRead', 'I386FileRuntimeBind', 'I386TaskFilesInit'):
        if exports.get(name, (0, 0))[0] != 1: raise ValueError(f'Missing file service {name}')
    if exports.get('file_runtime_version', (0, 0))[0] != 3:
        raise ValueError('Missing file-runtime version')
    version_offset = 32+exports['file_runtime_version'][1]
    if version_offset+4 > 32+size or struct.unpack_from('<I', module, version_offset)[0] != 3:
        raise ValueError('Unexpected file-runtime version')
    return dict(image_bytes=size+8, version_offset=version_offset,
        include_offset=8+exports['I386LexTaskFileInclude'][1], read_offset=8+exports['I386TaskFileRead'][1],
        bind_offset=8+exports['I386FileRuntimeBind'][1], init_offset=8+exports['I386TaskFilesInit'][1], import_offset=imports['I386RedSeaReadAll'])


def verify_file_rejection(disk, volume, out, layout):
    original = disk.read_bytes()
    offset = volume['files']['/Modules/I386/FileRuntime.t32m']['block']*512
    results = []
    for label, position, replacement, reason in (
            ('wrong-target', 6, b'\x04', 'load'),
            ('missing-import', layout['import_offset'], b'X', 'load'),
            ('wrong-api', layout['version_offset'], struct.pack('<I', 0), 'api')):
        work = out/f'reject-files-{label}'
        work.mkdir(parents=True, exist_ok=True)
        changed = bytearray(original)
        changed[offset+position:offset+position+len(replacement)] = replacement
        candidate = work/'kernel.img'; candidate.write_bytes(changed)
        with (work/'runner.log').open('w') as log:
            result = subprocess.run([sys.executable, str(ROOT/'tools/guest-run.py'), str(candidate),
                '--i386-disk', '--out', str(work), '--timeout', '60'], cwd=ROOT, stdout=log, stderr=log)
        evidence = (work/'debug.log').read_text()
        if (result.returncode == 0 or f'FILES REJECT {reason} reclaimed\n' not in evidence or
                'FAIL native kernel\n' not in evidence or
                any(marker in evidence for marker in ('RUNTIME PROBE ', 'INCLUDE PROBE ', 'DISK INCLUDE ',
                    'STARTUP disk module', 'READY native kernel', 'DONE native kernel'))):
            raise ValueError(f'File runtime failed rejection/reclamation: {label}')
        if candidate.read_bytes() != changed: raise ValueError('Rejected file module changed disk')
        results.append(label)
    return results


def compiler_probe_layout(module):
    size, count, records = struct.unpack_from('<III', module, 16)
    exports, imports = {}, []
    for index in range(count):
        kind, offset, name, length = struct.unpack_from('<4I', module, records+16*index)
        if kind in (1, 2, 3, 5):
            symbol = module[name:name+length].decode('ascii')
            if kind in (1, 3):
                exports[symbol] = (kind, offset)
            else:
                imports.append((symbol, name))
    expected = {'KernelLog', 'KernelHex', 'KernelStop', 'I386HeapSize', 'I386HeapFree',
                'I386HeapValid', 'I386IrqSave', 'I386IrqRestore', 'I386LexRawChar',
                'I386LexIncludeCopy', 'HashAdd', 'StrCmp', 'char_bmp_alpha_numeric'}
    if {name for name, _ in imports} != expected:
        raise ValueError('Unexpected compiler-probe import contract')
    for name in ('Main', 'ProbeTokens', 'ProbeIdent', 'ProbeDefine', 'ProbeConditional', 'ProbeIncludes', 'ProbeIncludePush', 'ProbeDiskIncludes'):
        if exports.get(name, (0, 0))[0] != 1:
            raise ValueError(f'Missing compiler-probe function {name}')
    if exports.get('compiler_probe_version', (0, 0))[0] != 3:
        raise ValueError('Missing compiler-probe version')
    version_offset = 32+exports['compiler_probe_version'][1]
    if version_offset+4 > 32+size or struct.unpack_from('<I', module, version_offset)[0] != 3:
        raise ValueError('Unexpected compiler-probe version')
    return dict(image_bytes=size+8, version_offset=version_offset,
                import_offset=next(offset for name, offset in imports if name == 'KernelLog'))


def verify_probe_rejection(disk, volume, out, layout):
    original = disk.read_bytes()
    offset = volume['files']['/Modules/I386/CompilerProbe.t32m']['block']*512
    results = []
    for label, position, replacement, reason in (
            ('wrong-target', 6, b'\x04', 'load'),
            ('missing-import', layout['import_offset'], b'X', 'load'),
            ('wrong-api', layout['version_offset'], struct.pack('<I', 0), 'api')):
        work = out/f'reject-probe-{label}'
        work.mkdir(parents=True, exist_ok=True)
        changed = bytearray(original)
        changed[offset+position:offset+position+len(replacement)] = replacement
        candidate = work/'kernel.img'
        candidate.write_bytes(changed)
        with (work/'runner.log').open('w') as log:
            result = subprocess.run([sys.executable, str(ROOT/'tools/guest-run.py'), str(candidate),
                '--i386-disk', '--out', str(work), '--timeout', '60'], cwd=ROOT, stdout=log, stderr=log)
        evidence = (work/'debug.log').read_text()
        if (result.returncode == 0 or 'FAIL native kernel\n' not in evidence or
                f'PROBE REJECT {reason} reclaimed\n' not in evidence or
                any(marker in evidence for marker in ('RUNTIME PROBE ', 'IDENT PROBE ',
                    'STRING PROBE ', 'LEX PROBE ', 'DEFINE PROBE ', 'CONDITIONAL PROBE ', 'INCLUDE PROBE ', 'DISK INCLUDE ', 'PROBE MODULE ',
                    'STARTUP disk module', 'READY native kernel', 'DONE native kernel'))):
            raise ValueError(f'Compiler probe did not reject/reclaim {label} before use')
        if candidate.read_bytes() != changed:
            raise ValueError('Rejected compiler probe changed the disk')
        results.append(label)
    return results


def verify_compiler_rejection(disk, volume, out, layout):
    original = disk.read_bytes()
    entry = volume['files']['/Modules/I386/CompilerRuntime.t32m']
    offset = entry['block']*512
    results = []
    for label, position, replacement, reason in (
            ('wrong-target', 6, b'\x04', 'load'),
            ('missing-import', layout['import_offset'], b'X', 'load'),
            ('wrong-api', layout['version_offset'], struct.pack('<I', 9), 'api')):
        work = out/f'reject-runtime-{label}'
        work.mkdir(parents=True, exist_ok=True)
        changed = bytearray(original)
        changed[offset+position:offset+position+len(replacement)] = replacement
        candidate = work/'kernel.img'
        candidate.write_bytes(changed)
        with (work/'runner.log').open('w') as log:
            result = subprocess.run([sys.executable, str(ROOT/'tools/guest-run.py'), str(candidate),
                '--i386-disk', '--out', str(work), '--timeout', '60'], cwd=ROOT, stdout=log, stderr=log)
        evidence = (work/'debug.log').read_text()
        if (result.returncode == 0 or 'FAIL native kernel\n' not in evidence or
                f'RUNTIME REJECT {reason} reclaimed\n' not in evidence or
                any(marker in evidence for marker in ('RUNTIME PROBE ', 'IDENT PROBE ', 'STRING PROBE ', 'LEX PROBE ', 'DEFINE PROBE ', 'CONDITIONAL PROBE ', 'INCLUDE PROBE ', 'STARTUP disk module',
                    'MODULE ', 'READY native kernel', 'DONE native kernel'))):
            raise ValueError(f'Compiler runtime did not reject/reclaim {label} before publication')
        if candidate.read_bytes() != changed:
            raise ValueError('Rejected compiler runtime changed the disk')
        results.append(label)
    return results


def audit(exports, out):
    disassemble = runpy.run_path(str(ROOT/'tools/test-i386.py'))['disassemble_i386']
    allowed = set(('bt bts btr btc bsf bsr push pop pushf popf mov lea add adc sub sbb and or xor mul imul neg not ret '
                   'movsx movzx cdq jmp cmp jz jnz setz setnz setl setnl setg setng setc setnc '
                   'seta setna test shl shr in out sar shld shrd rcl div call dec jns jc jnc ja jna '
                   'cli sti hlt cld pusha popa iret lgdt sgdt lidt sidt').split())
    image = (exports/'Kernel32.BIN').read_bytes()
    if len(image)<8 or image[0]!=0xE9 or any(image[5:8]):
        raise ValueError('Invalid native entry trampoline')
    base = 8
    listing = []
    for index, name in enumerate(DISK_MODULES):
        module = (exports/f'{name}.t32m').read_bytes()
        magic, version, cpu, pointer, abi, total, size, count, records, strings = struct.unpack_from('<IHBB6I', module)
        if (magic,version,cpu,pointer,abi,total,records,strings) != (
                0x4D323354,2,3,4,1,len(module),32+size,32+size+16*count):
            raise ValueError(f'Invalid {name} module header')
        resident = index < len(MODULES)
        code = image[base:base+size] if resident else module[32:32+size]
        if len(code)!=size:
            raise ValueError('Truncated kernel')
        if index==0 or not resident:
            starts, data = [], []
            for i in range(count):
                kind, offset, name_offset, length = struct.unpack_from('<4I',module,records+16*i)
                if kind==1:
                    starts.append(offset)
                elif kind==4:
                    data.append((offset,name_offset))
            starts.sort()
            if not starts or starts[-1]>=size or len(set(starts))!=len(starts):
                raise ValueError('Invalid kernel function boundaries')
            if resident and 5+struct.unpack_from('<i',image,1)[0] not in [base+x for x in starts]:
                raise ValueError('Entry is not a kernel function')
            coverage = bytearray(size)
            for begin,length in data:
                if length<=0 or begin+length>size or any(coverage[begin:begin+length]):
                    raise ValueError('Invalid kernel data range')
                coverage[begin:begin+length]=b'D'*length
            boundaries=sorted(set(starts+[begin for begin,_ in data]+[size]))
            spans=[(start,next(end for end in boundaries if end>start)) for start in starts]
            for start,end in spans:
                if any(coverage[start:end]):
                    raise ValueError('Kernel code/data overlap')
                coverage[start:end]=b'C'*(end-start)
            gap=0
            for i,marker in enumerate(coverage):
                if marker: gap=0
                else:
                    gap+=1
                    if code[i] or gap>7: raise ValueError('Unclassified kernel bytes')
        else:
            spans=[(0,size)]
        terminal='iret' if name in ('IrqEntry','ExceptionEntry') else 'ret'
        for start,end in spans:
            lines=disassemble(code[start:end]).splitlines()
            returns=[i for i,line in enumerate(lines) if len(line.split())>=3 and line.split()[2]==terminal]
            if not returns: raise ValueError(f'Missing {name} {terminal}')
            last=returns[-1]
            parts=lines[last].split()
            used=int(parts[0],16)+len(parts[1])//2
            if end-start-used>7 or any(code[start+used:end]):
                raise ValueError(f'Invalid {name} code tail')
            for line in lines[:last+1]:
                parts = line.split()
                locked_bit = parts[2:] in (["lock", op, "[eax],esi"] for op in ("bts", "btr", "btc"))
                if parts[2] not in allowed and not locked_bit:
                    raise ValueError(f'Unexpected instruction: {line}')
            listing.append(f'; {name} offset {start:X}\n'+'\n'.join(lines[:last+1]))
        if resident: base+=size
    if base!=len(image): raise ValueError('Unclassified trailing kernel bytes')
    (out/'kernel-assembly.txt').write_text('\n'.join(listing)+'\n')
    return image


def package_volume(disk, exports):
    """Write a RedSea volume after the reserved boot area; keep source bytes exact."""
    start, sectors = 2048, 32768-2048
    bitmap_blocks=(sectors+4095)//4096
    first=start+bitmap_blocks+1
    cursor=first
    image=bytearray(disk.read_bytes())
    tree={}
    for directory in ('Kernel','Compiler'):
        for path in sorted((ROOT/directory).rglob('*')):
            if path.is_file() and path.suffix.upper() in ('.HC','.HH','.DD','.PRJ'):
                node=tree
                parts=path.relative_to(ROOT).parts
                for part in parts[:-1]: node=node.setdefault(part,{})
                node[parts[-1]]=path.read_bytes()
    packed = (exports/'IncludeInner.HC.Z').read_bytes()
    inner = (ROOT/'tools/guest/i386-kernel/IncludeInner.HC').read_bytes()
    if len(packed)<17 or struct.unpack_from('<qqB', packed) != (len(packed), len(inner), 2):
        raise ValueError('Invalid original-compressor include fixture')
    tree['Probe'] = {'Outer.HC': (ROOT/'tools/guest/i386-kernel/IncludeOuter.HC').read_bytes(),
                     'Inner.HC.Z': packed, 'Bad.HC.Z': struct.pack('<qqB', 18, 1, 2), 'Bad.HC': b'99\n'}
    tree['Modules']={'I386':{f'{name}.t32m':(exports/f'{name}.t32m').read_bytes() for name in DISK_MODULES}}
    files={}
    def entry(name,attr,block,size):
        raw=name.encode('ascii')
        if not raw or len(raw)>=38: raise ValueError(f'Invalid RedSea name: {name}')
        return struct.pack('<H38sqqQ',attr,raw,block,size,0)
    def emit(node,path='',parent=None):
        nonlocal cursor
        if isinstance(node,bytes):
            if not node:
                block=0
            else:
                block=cursor
                cursor+=(len(node)+511)//512
                if cursor>start+sectors: raise ValueError('RedSea image full')
                image[block*512:block*512+len(node)]=node
            files[path]={'block':block,'size':len(node),'sha256':hashlib.sha256(node).hexdigest()}
            return block,len(node),0x800
        block=cursor
        size=((len(node)+3)*64+511)//512*512
        cursor+=size//512
        if cursor>start+sectors: raise ValueError('RedSea directory image full')
        entries=[entry('.',0x810,block,size),entry('..',0x810,parent or block,0)]
        for name,child in sorted(node.items()):
            child_block,child_size,attr=emit(child,path+'/'+name,block)
            entries.append(entry(name,attr,child_block,child_size))
        raw=b''.join(entries)
        image[block*512:block*512+len(raw)]=raw
        return block,size,0x810
    root,_,_=emit(tree)
    header=bytearray(512)
    header[3]=0x88
    struct.pack_into('<5q',header,8,start,sectors,root,bitmap_blocks,1)
    struct.pack_into('<H',header,510,0xAA55)
    image[start*512:(start+1)*512]=header
    allocated=cursor-(first-1)
    bitmap=bytearray(((1<<allocated)-1).to_bytes(bitmap_blocks*512,'little'))
    valid_bits=start+sectors-(first-1)
    for index in range(valid_bits,len(bitmap)*8): bitmap[index//8]|=1<<(index&7)
    image[(start+1)*512:(start+1+bitmap_blocks)*512]=bitmap
    disk.write_bytes(image)
    return {'start':start,'sectors':sectors,'root':root,'bitmap_sectors':bitmap_blocks,
            'first_free':cursor,'files':files}


def verify_volume(disk, volume):
    """Independently walk serialized directories and verify allocation ownership."""
    image=disk.read_bytes()
    start=volume['start']; end=start+volume['sectors']
    first=start+volume['bitmap_sectors']+1
    header=image[start*512:(start+1)*512]
    if header[3]!=0x88 or header[510:]!=b'\x55\xaa' or struct.unpack_from('<5q',header,8)!=(
            start,volume['sectors'],volume['root'],volume['bitmap_sectors'],1):
        raise ValueError('Invalid packaged RedSea header')
    owned=set(); found={}
    def claim(block,size):
        if not size and not block: return
        if size<0 or block<first or block+(size+511)//512>end:
            raise ValueError('Invalid packaged extent')
        for sector in range(block,block+(size+511)//512):
            if sector in owned: raise ValueError('Overlapping packaged extents')
            owned.add(sector)
    def record(raw):
        attr,name,block,size,date=struct.unpack('<H38sqqQ',raw)
        name=name.split(b'\0',1)[0].decode('ascii')
        if not name or '/' in name or date: raise ValueError('Invalid packaged directory entry')
        return attr,name,block,size
    def directory(block,parent,path):
        attr,name,self_block,size=record(image[block*512:block*512+64])
        if (attr,name,self_block)!=(0x810,'.',block) or size<512 or size%512:
            raise ValueError('Invalid packaged self entry')
        claim(block,size)
        if record(image[block*512+64:block*512+128])!=(0x810,'..',parent,0):
            raise ValueError('Invalid packaged parent entry')
        names=set()
        for offset in range(128,size,64):
            raw=image[block*512+offset:block*512+offset+64]
            if not raw[2]:
                if any(image[block*512+offset:block*512+size]):
                    raise ValueError('Nonzero bytes after directory terminator')
                return
            attr,name,child,length=record(raw)
            if name in names or name in ('.','..'): raise ValueError('Duplicate packaged name')
            names.add(name)
            child_path=path+'/'+name
            if attr==0x810:
                if child<first or child>=end: raise ValueError('Invalid child directory')
                directory(child,block,child_path)
                if struct.unpack_from('<q',image,child*512+48)[0]!=length:
                    raise ValueError('Directory extent sizes disagree')
            elif attr==0x800:
                claim(child,length)
                content=image[child*512:child*512+length] if length else b''
                found[child_path]={'block':child,'size':length,'sha256':hashlib.sha256(content).hexdigest()}
            else: raise ValueError('Invalid packaged attributes')
        raise ValueError('Missing packaged directory terminator')
    directory(volume['root'],volume['root'],'')
    if found!=volume['files']: raise ValueError('Packaged files differ from source manifest')
    bitmap=image[(start+1)*512:first*512]
    for index in range(len(bitmap)*8):
        block=first-1+index
        expected=block<first or block>=end or block in owned
        if bool(bitmap[index//8]&(1<<(index&7)))!=expected:
            raise ValueError('Packaged allocation bitmap disagrees with extents')
    return len(found)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--test',action='store_true',help='Boot with 8 MiB and verify startup, keyboard and VGA')
    args=parser.parse_args()
    out=ROOT/'build/i386-kernel'
    out.mkdir(parents=True,exist_ok=True)
    (out/'result.json').unlink(missing_ok=True)
    run(sys.executable,'tools/gen-compiler-keywords.py','--check')
    bootstrap=json.loads((ROOT/'build/rebuild-test/result.json').read_text())
    for name,digest in bootstrap['source_sha256'].items():
        if name.startswith(('Kernel/','Compiler/')) and hashlib.sha256((ROOT/name).read_bytes()).hexdigest()!=digest:
            raise ValueError(f'Rerun tools/test-rebuild.py: changed {name}')
    for name,path in [('Compiler.BIN','Compiler/Compiler.BIN'),('Kernel.BIN','0000Boot/0000Kernel.BIN.C')]:
        if hashlib.sha256((ROOT/'build/rebuild-test/overlay'/path).read_bytes()).hexdigest()!=bootstrap['generations'][-1][name]:
            raise ValueError('Stale bootstrap binary')
    iso=out/'compiler.iso'
    run(sys.executable,'tools/build-iso.py','--overlay','build/rebuild-test/overlay',
        '--overlay','tools/guest/i386-kernel','--output',str(iso))
    exports=out/'exports'
    run(sys.executable,'tools/guest-run.py',str(iso),'--out',str(exports),'--timeout','90')
    image=audit(exports,out)
    runtime_layout=compiler_runtime_layout((exports/'CompilerRuntime.t32m').read_bytes())
    probe_layout=compiler_probe_layout((exports/'CompilerProbe.t32m').read_bytes())
    files_layout=file_runtime_layout((exports/'FileRuntime.t32m').read_bytes())
    disk=out/'kernel.img'
    run('nasm','-f','bin',f'-DKERNEL_FILE="{exports / "Kernel32.BIN"}"',
        'tools/i386-kernel-stage.asm','-o',str(disk))
    if disk.stat().st_size>(768+1)*512:
        raise ValueError('Kernel stage exceeds its reserved 384 KiB load area')
    with disk.open('r+b') as stream: stream.truncate(16*1024*1024)
    volume=package_volume(disk,exports)
    volume['verified_files']=verify_volume(disk,volume)
    result={'revision':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
            'source_sha256':bootstrap['source_sha256'],
            'bootstrap':bootstrap['generations'][-1],
            'worktree_dirty':bool(subprocess.check_output(['git','status','--porcelain'],cwd=ROOT)),
            'build_inputs_sha256':{name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in (
                'tools/build-i386-kernel.py','tools/i386-bios.inc','tools/i386-kernel-stage.asm',
                'tools/guest/i386-kernel/Once.HC','tools/test-i386.py','tools/build-iso.py','tools/guest-run.py',
                'tools/i386-kernel-input.py')},
            'tools':{'python':sys.version,
                     'qemu':subprocess.check_output(['qemu-system-i386','--version'],text=True).splitlines()[0],
                     'nasm':subprocess.check_output(['nasm','-v'],text=True).strip()},
            'kernel_bytes':len(image),
            'kernel_sha256':hashlib.sha256(image).hexdigest(),
            'disk_sha256':hashlib.sha256(disk.read_bytes()).hexdigest(),
            'modules':{name:hashlib.sha256((exports/f'{name}.t32m').read_bytes()).hexdigest() for name in DISK_MODULES},
            'bootstrap_modules':list(MODULES),
            'resident_modules':list(MODULES)+['CompilerRuntime', 'FileRuntime'],
            'temporary_modules':['Startup', 'CompilerProbe'],
            'volume':volume,
            'scope':'Native kernel with retained extended-memory lexer/numerical runtime and AOT startup; shell/JIT and self-hosting unfinished',
            'boot_test':None}
    if args.test:
        guest=out/'boot'
        run(sys.executable,'tools/guest-run.py',str(disk),'--i386-disk','--out',str(guest),'--timeout','60')
        log=(guest/'debug.log').read_text()
        if 'READY native kernel foundation\n' not in log or log.count('TICK ')!=2:
            raise ValueError('Missing native kernel startup/timer evidence')
        types=[line.split() for line in log.splitlines() if line.startswith('TYPES ')]
        if len(types)!=1 or [int(x,16) for x in types[0][1:]]!=[17,7672]:
            raise ValueError('Missing resident built-in types or unexpected allocation footprint')
        result['internal_types']={'names':17,'heap_bytes':7672}
        keyword_names = re.findall(rb'^(?:KEYWORD|ASM_KEYWORD)\s+(\w+)\s+\d+\s*;',
                                   (ROOT/'Compiler/OpCodes.DD').read_bytes(), re.M)
        #Native table owner/buckets: 48+272. Each CHashGeneric: 40+16; names own an aligned block.
        keyword_bytes = 320+sum(56+16+((len(name)+8)&~7) for name in keyword_names)
        keywords=[line.split() for line in log.splitlines() if line.startswith('KEYWORDS ')]
        if len(keywords)!=1 or [int(value,16) for value in keywords[0][1:]]!=[73,keyword_bytes]:
            raise ValueError('Missing native keyword registry/footprint evidence')
        result['keywords']={'language':48,'assembler':25,'heap_bytes':keyword_bytes,
                            'allocations':148,'lifetime':'kernel lifetime'}

        mounted=[line.split() for line in log.splitlines() if line.startswith('REDSEA ')]
        if len(mounted)!=1 or [int(x,16) for x in mounted[0][1:]]!=[volume['start'],volume['sectors']]:
            raise ValueError('Wrong boot volume mounted')
        source=(ROOT/'Kernel/I386/Kernel.HC').read_bytes()
        checksum=2166136261
        for byte in source: checksum=((checksum^byte)*16777619)&0xFFFFFFFF
        reads=[line.split() for line in log.splitlines() if line.startswith('SOURCE ')]
        if len(reads)!=1 or [int(x,16) for x in reads[0][1:]]!=[len(source),checksum]:
            raise ValueError('Native RedSea source read differs from packaged source')
        normalized=bytes(32 if byte==31 else byte for byte in source if byte!=5)
        lexical_hash=2166136261
        for byte in normalized: lexical_hash=((lexical_hash^byte)*16777619)&0xFFFFFFFF
        lexical=[line.split() for line in log.splitlines() if line.startswith('LEX_SOURCE ')]
        transient=((len(source)+1+7)&~7)+576
        expected_lexical=[len(normalized),source.count(b'\n'),lexical_hash,transient]
        if b'\0' in source or len(lexical)!=1 or [int(x,16) for x in lexical[0][1:]]!=expected_lexical:
            raise ValueError('Native lexical source consumption/reclamation mismatch')
        result['lexical_source']={'characters':len(normalized),'lines':source.count(b'\n'),
                                  'fnv32':lexical_hash,'reclaimed_heap_bytes':transient}
        loaded=[line.split() for line in log.splitlines() if line.startswith('MODULE ')]
        if (log.count('STARTUP disk module\n')!=1 or len(loaded)!=1 or len(loaded[0])!=3
                or int(loaded[0][1],16)!=1 or int(loaded[0][2],16)<=0):
            raise ValueError('Missing disk module execution/reclamation evidence')
        startup_reclaimed=int(loaded[0][2],16)
        if hashlib.sha256(disk.read_bytes()).hexdigest()!=result['disk_sha256']:
            raise ValueError('Read-only kernel startup changed the disk')
        ticks=[int(line.split()[1],16) for line in log.splitlines() if line.startswith('TICK ')]
        if ticks[0]<25 or ticks[1]-ticks[0]<25:
            raise ValueError('Kernel task woke before its requested tick delay')
        arena=[line.split() for line in log.splitlines() if line.startswith('ARENA ')]
        if len(arena)!=1: raise ValueError('Missing selected memory arena')
        begin,length=(int(value,16) for value in arena[0][1:])
        if begin<0x110000 or begin+length>8*1024*1024:
            raise ValueError('Unexpected 8 MiB memory arena')
        runtime = [line.split() for line in log.splitlines()
                   if line.startswith('RUNTIME ') and not line.startswith('RUNTIME PROBE ')]
        if len(runtime) != 1 or len(runtime[0]) != 15:
            raise ValueError('Missing retained compiler-runtime image')
        address, size, span, string_address, number_address, char_address, punct_address, ident_address, ident_token_address, string_token_address, next_address, include_address, control_new_address, control_del_address = (int(x, 16) for x in runtime[0][1:])
        if (size != runtime_layout['image_bytes'] or span != ((size+7)&~7)+16 or
                address < begin or address+size > begin+length or
                string_address != address+runtime_layout['string_offset'] or
                number_address != address+runtime_layout['number_offset'] or
                char_address != address+runtime_layout['char_offset'] or
                punct_address != address+runtime_layout['punct_offset'] or
                ident_address != address+runtime_layout['ident_offset'] or
                ident_token_address != address+runtime_layout['ident_token_offset'] or
                string_token_address != address+runtime_layout['string_token_offset'] or
                next_address != address+runtime_layout['next_offset'] or
                include_address != address+runtime_layout['include_offset'] or
                control_new_address != address+runtime_layout['control_new_offset'] or
                control_del_address != address+runtime_layout['control_del_offset']):
            raise ValueError('Compiler-runtime placement, ownership or service address mismatch')
        file_rows = [line.split() for line in log.splitlines() if line.startswith('FILES ')]
        if len(file_rows)!=1 or len(file_rows[0])!=8: raise ValueError('Missing file-runtime ownership evidence')
        file_address, file_size, file_span, file_include, file_read, file_bind, file_init = (int(x,16) for x in file_rows[0][1:])
        if (file_size!=files_layout['image_bytes'] or file_span!=((file_size+7)&~7)+16 or
                file_address<begin or file_address+file_size>begin+length or
                file_include!=file_address+files_layout['include_offset'] or
                file_read!=file_address+files_layout['read_offset'] or
                file_bind!=file_address+files_layout['bind_offset'] or
                file_init!=file_address+files_layout['init_offset']):
            raise ValueError('File-runtime placement or service mismatch')
        disk_includes = [line.split() for line in log.splitlines() if line.startswith('DISK INCLUDE ')]
        if ([list(map(lambda x:int(x,16),row[2:])) for row in disk_includes]!=[[0,68],[1,136]] or
                log.index('DISK INCLUDE ')>log.index('STARTUP disk module') or
                log.rindex('DISK INCLUDE ')<log.rindex('TICK ') or
                log.count('DISK READ 0000000000000000\n')!=1 or
                log.count('DISK READ 0000000000000001\n')!=1 or
                log.count('DISK IF PRESERVED\n')!=1 or log.count('STORAGE TASK BOUND\n')!=1 or
                not log.index('STARTUP disk module')<log.index('STORAGE TASK BOUND\n')<log.rindex('DISK INCLUDE ')):
            raise ValueError('Retained disk include execution/rejection failed')
        result['file_runtime'] = dict(version=3, image_address=file_address, image_bytes=file_size,
            retained_heap_bytes=file_span, include_address=file_include, read_address=file_read, bind_address=file_bind, init_address=file_init,
            task_volume_bound=True, task_context_inherited=True,
            decoded_read_phases=[0,1], read_failure_outputs_preserved=True,
            disk_include_lines=[68,136], enabled_if_preserved=True, lifetime='kernel lifetime')
        probes = [line.split() for line in log.splitlines() if line.startswith('RUNTIME PROBE ')]
        if ([list(map(lambda x: int(x, 16), row[2:])) for row in probes] !=
                [[0, 0x3F1A36E2EB1C432D, 65, 0x4241, 0x112, 8], [1, 0x3F1A36E2EB1C432D, 65, 0x4241, 0x112, 8]] or
                log.index('RUNTIME PROBE ') > log.index('STARTUP disk module') or
                log.rindex('RUNTIME PROBE ') < log.rindex('TICK ')):
            raise ValueError('Compiler runtime did not survive startup/task activity')
        ident_probes = [line.split() for line in log.splitlines() if line.startswith('IDENT PROBE ')]
        if ([list(map(lambda x: int(x, 16), row[2:])) for row in ident_probes] !=
                [[0, 0x100, 8], [1, 0x100, 8]] or
                log.index('IDENT PROBE ') > log.index('STARTUP disk module') or
                log.rindex('IDENT PROBE ') < log.rindex('TICK ')):
            raise ValueError('Native identifier token/macro probes failed')
        string_probes = [line.split() for line in log.splitlines() if line.startswith('STRING PROBE ')]
        if ([list(map(lambda x: int(x, 16), row[2:])) for row in string_probes] !=
                [[0, 0x101, 0x620061], [1, 0x101, 0x620061]] or
                log.index('STRING PROBE ') > log.index('STARTUP disk module') or
                log.rindex('STRING PROBE ') < log.rindex('TICK ')):
            raise ValueError('Native owned string token probes failed')
        lex_probes = [line.split() for line in log.splitlines() if line.startswith('LEX PROBE ')]
        if ([list(map(lambda x: int(x, 16), row[2:])) for row in lex_probes] !=
                [[0, 0x4000000000000000], [1, 0x4000000000000000]] or
                log.index('LEX PROBE ') > log.index('STARTUP disk module') or
                log.rindex('LEX PROBE ') < log.rindex('TICK ')):
            raise ValueError('Native mixed-token dispatch probes failed')
        define_probes = [line.split() for line in log.splitlines() if line.startswith('DEFINE PROBE ')]
        if ([list(map(lambda x: int(x, 16), row[2:])) for row in define_probes] !=
                [[0, 0x4008000000000000], [1, 0x4008000000000000]] or
                log.index('DEFINE PROBE ') > log.index('STARTUP disk module') or
                log.rindex('DEFINE PROBE ') < log.rindex('TICK ')):
            raise ValueError('Native define publication/expansion probes failed')
        conditional_probes = [line.split() for line in log.splitlines() if line.startswith('CONDITIONAL PROBE ')]
        if ([list(map(lambda x: int(x, 16), row[2:])) for row in conditional_probes] !=
                [[0, 0x4008000000000000], [1, 0x4008000000000000]] or
                log.index('CONDITIONAL PROBE ') > log.index('STARTUP disk module') or
                log.rindex('CONDITIONAL PROBE ') < log.rindex('TICK ')):
            raise ValueError('Native nested conditional probes failed')
        include_probes = [line.split() for line in log.splitlines() if line.startswith('INCLUDE PROBE ')]
        if ([list(map(lambda x: int(x, 16), row[2:])) for row in include_probes] !=
                [[0, 3, 44], [1, 3, 44]] or
                log.index('INCLUDE PROBE ') > log.index('STARTUP disk module') or
                log.rindex('INCLUDE PROBE ') < log.rindex('TICK ')):
            raise ValueError('Retained include callbacks failed before/after task activity')
        probe_modules = [line.split() for line in log.splitlines() if line.startswith('PROBE MODULE ')]
        releases = [line.split() for line in log.splitlines() if line.startswith('PROBE RELEASE ')]
        if len(probe_modules)!=1 or len(probe_modules[0])!=5 or len(releases)!=1 or len(releases[0])!=4:
            raise ValueError('Missing compiler-probe lifetime evidence')
        probe_address, probe_size, probe_span = (int(value, 16) for value in probe_modules[0][2:])
        if (probe_size!=probe_layout['image_bytes'] or probe_span!=((probe_size+7)&~7)+16 or
                probe_address<begin or probe_address+probe_size>begin+length or
                [int(value, 16) for value in releases[0][2:]]!=[probe_size, probe_span] or
                not (log.index('DEFINE PROBE ') < log.index('PROBE MODULE ') < log.index('STARTUP disk module')) or
                not (log.rindex('DEFINE PROBE ') < log.index('PROBE RELEASE ') < log.index('DONE native kernel'))):
            raise ValueError('Compiler-probe placement, lifetime or reclamation mismatch')
        result['compiler_probe'] = dict(module='CompilerProbe', version=3, image_address=probe_address,
            image_bytes=probe_size, temporary_heap_bytes=probe_span, reclaimed_heap_bytes=probe_span,
            phases=['boot', 'task'], lifetime='released after task probe')
        result['compiler_runtime'] = dict(module='CompilerRuntime', version=11, image_address=address,
            image_bytes=size, retained_heap_bytes=span, string_address=string_address,
            number_address=number_address, char_address=char_address, punct_address=punct_address, ident_address=ident_address, ident_token_address=ident_token_address, string_token_address=string_token_address, next_address=next_address, include_address=include_address, control_new_address=control_new_address, control_del_address=control_del_address, owned_control_phases=['boot','task'], include_phases=['boot', 'task'], conditional_phases=['boot', 'task'], definition_phases=['boot', 'task'], token_stream_phases=['boot', 'task'], probe_phases=['boot', 'task'], identifier_token_phases=['boot', 'task'], string_token_phases=['boot', 'task'], lifetime='kernel lifetime')
        from PIL import Image
        screen=Image.open(guest/'screen.ppm').convert('RGB')
        if screen.size!=(640,480): raise ValueError('Unexpected VGA resolution')
        console=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))
        expected=console['console_pixels'](['TempleOS i386','Keyboard console','','> '])
        if screen.tobytes()!=expected:
            raise ValueError('VGA console mismatch')
        screen.save(guest/'screen.png')
        rejected=verify_startup_rejection(disk,volume,out)
        result['file_runtime']['rejected']=verify_file_rejection(disk,volume,out,files_layout)
        result['compiler_runtime']['rejected']=verify_compiler_rejection(disk,volume,out,runtime_layout)
        result['compiler_probe']['rejected']=verify_probe_rejection(disk,volume,out,probe_layout)
        keyboard=console['run_input'](disk,out/'input')
        if hashlib.sha256(disk.read_bytes()).hexdigest()!=result['disk_sha256']:
            raise ValueError('Keyboard console changed the disk')
        result['boot_test']={'cpu':'486','ram_mib':8,'arena_base':begin,'arena_size':length,
                             'startup_module':'Startup','startup_reclaimed_bytes':startup_reclaimed,
                             'startup_rejected':rejected,
                             'keyboard':keyboard,
                             'source_bytes':len(source),'source_fnv32':checksum,'timer_wakeups':ticks,'vga':'640x480, all pixels matched','result':'pass'}
    result['disk_sha256']=hashlib.sha256(disk.read_bytes()).hexdigest()
    (out/'result.json').write_text(json.dumps(result,indent=2)+'\n')
    print(f'Built {disk} ({len(image)} native kernel bytes); boot test: {bool(args.test)}')


if __name__=='__main__':
    main()
