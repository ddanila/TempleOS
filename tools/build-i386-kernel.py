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
DISK_MODULES = MODULES + ('Startup', 'CompilerRuntime', 'CompilerProbe', 'FileRuntime', 'ConsoleRuntime', 'MemoryRuntime')


def run(*args):
    subprocess.run(args, cwd=ROOT, check=True)


def verify_startup_rejection(disk, volume, out):
    """Prove startup reads and validates the disk module before invoking it."""
    #This module loads after the root diagnostics; allow the full boot deadline.
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
                '--i386-disk','--out',str(work),'--timeout','180'],cwd=ROOT,stdout=log,stderr=log)
        evidence=(work/'debug.log').read_text()
        if (result.returncode==0 or 'FAIL native kernel\n' not in evidence
                or 'SOURCE ' not in evidence or any(line.startswith('MODULE ') for line in evidence.splitlines())
                or any(marker in evidence for marker in
                    ('STARTUP disk module','READY native kernel','DONE native kernel'))):
            raise ValueError(f'Startup did not reject {label} before execution')
        if candidate.read_bytes()!=changed: raise ValueError('Rejected startup changed disk')
        results.append(label)
    return results


def verify_source_startup(disk, volume, out, console):
    """Change only disk source, then prove native execution, lifetime and recovery."""
    original=disk.read_bytes()
    entry=volume['files']['/Kernel/I386/StartOS.HC']
    offset=entry['block']*512
    record=struct.pack('<H38sqqQ',0x800,b'StartOS.HC',entry['block'],entry['size'],0)
    if original.count(record)!=1: raise ValueError('Ambiguous startup directory entry')
    cases=[
        ('custom',b'#define BOOT_VALUE 39\nI64 BootCount=BOOT_VALUE;\nI64 BootNext(){return ++BootCount;}\nBootNext;\n',
         {'status':'ok','answers':['40'],'commands':[
             ('BootNext;', ['41']), ('BootNext;', ['42']), ('BOOT_VALUE;', ['39'])]}),
        ('syntax-error',b'#define BOOT_SEEN 7\nI64 BootCount=39;\nUnknown bad;\n',
         {'status':'error','answers':['Error: Undefined identifier at '],'commands':[
             ('BootCount;', ['Error: Undefined identifier at ']),
             ('I64 BootCount=41;', []), ('++BootCount;', ['42']), ('BOOT_SEEN;', ['7']), ('Fs->gs==Gs;', ['1'])]}),
        ('missing',None,{'status':'error','answers':['Compilation failed'],'commands':[
            ('6*7;', ['42']), ('I64 recovered=9;', []), ('recovered;', ['9']), ('sizeof(CTask);', ['992'])]}),
    ]
    results={}
    for label,source,check in cases:
        work=out/f'source-{label}'; work.mkdir(parents=True,exist_ok=True)
        changed=bytearray(original)
        if source is None:
            changed[original.index(record)+2]=ord('X')
        else:
            if len(source)>entry['size']: raise ValueError('Startup fixture exceeds reserved source bytes')
            changed[offset:offset+entry['size']]=source.ljust(entry['size'],b' ')
        candidate=work/'kernel.img'; candidate.write_bytes(changed)
        results[label]=console['run_input'](candidate,work,check)
        if candidate.read_bytes()!=changed: raise ValueError('Source startup changed disk')
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
    if {name for name, _ in imports} != {'I386LexRawChar', 'I386LexSourceRead', 'char_bmp_hex_numeric', 'char_bmp_dec_numeric', 'char_bmp_non_eol', 'HashFind', 'StrCmp', 'I386HeapAlloc', 'I386HeapFree', 'I386HeapSize', 'I386IrqSave', 'I386IrqRestore', 'I386LexIncludeCopy', 'HashAdd', 'char_bmp_non_eol_white_space', 'I386LexFilePush', 'LexFileReleaseTop', 'I386HashTableNew', 'I386HashTableValid', 'I386HashTableDelete', 'throw', 'SysTry', 'SysUntry'}:
        raise ValueError('Unexpected compiler-runtime import contract')
    for name in ('Main', 'I386LexStringChunk', 'I386LexNumber', 'I386LexChar', 'I386RuntimePunct', 'I386LexIdentScan', 'I386LexIdentToken', 'I386LexStringToken', 'I386RuntimeLexNext', 'I386RuntimeLexIncludes', 'I386CmpCtrlNew', 'I386CmpCtrlDel', 'I386TaskSymbolsInit', 'I386CmpCtrlEnter', 'I386CmpCtrlLeave', 'I386CmpCtrlDrain', 'I386CmpCtrlUnwind', 'I386ICAdd', 'I386COCMiscNew', 'I386COCDiscard', 'I386COCSave', 'I386COCPush', 'I386COCPopNoFree', 'I386COCHeaderFree', 'I386COCAppend', 'I386ICRetire', 'I386OptBranch', 'I386OptPass012', 'I386OutNew', 'I386OutDel', 'I386BackendCompile', 'I386ParseExpression', 'I386ParseType', 'I386ParserAlloc', 'I386ParserFree', 'I386ParserToken', 'I386ParseDeclarations', 'I386COCInit', 'I386ParseClass', 'I386ParseFunJoin', 'I386PublishClasses', 'I386BootstrapScalars', 'I386LoadScalarTypes', 'I386ScalarTypesCheck', 'I386FrontendServices', 'I386FrontendStatement', 'I386FrontendCommand', 'I386FrontendPublish', 'I386CommandInput'):
        if name not in exports or exports[name][0] != 1:
            raise ValueError(f'Missing compiler-runtime function {name}')
    if exports.get('compiler_runtime_version', (0, 0))[0] != 3:
        raise ValueError('Missing compiler-runtime interface version')
    version_offset = 32+exports['compiler_runtime_version'][1]
    if version_offset+4 > 32+size or struct.unpack_from('<I', module, version_offset)[0] != 41:
        raise ValueError('Unexpected compiler-runtime interface version')
    return dict(image_bytes=size+8, string_offset=8+exports['I386LexStringChunk'][1],
                number_offset=8+exports['I386LexNumber'][1], char_offset=8+exports['I386LexChar'][1],
                punct_offset=8+exports['I386RuntimePunct'][1], ident_offset=8+exports['I386LexIdentScan'][1],
                ident_token_offset=8+exports['I386LexIdentToken'][1], string_token_offset=8+exports['I386LexStringToken'][1],
                next_offset=8+exports['I386RuntimeLexNext'][1], include_offset=8+exports['I386RuntimeLexIncludes'][1], control_new_offset=8+exports['I386CmpCtrlNew'][1], control_del_offset=8+exports['I386CmpCtrlDel'][1], symbols_init_offset=8+exports['I386TaskSymbolsInit'][1], control_enter_offset=8+exports['I386CmpCtrlEnter'][1], control_leave_offset=8+exports['I386CmpCtrlLeave'][1], control_drain_offset=8+exports['I386CmpCtrlDrain'][1], control_unwind_offset=8+exports['I386CmpCtrlUnwind'][1], code_add_offset=8+exports['I386ICAdd'][1], code_misc_offset=8+exports['I386COCMiscNew'][1], code_discard_offset=8+exports['I386COCDiscard'][1], code_save_offset=8+exports['I386COCSave'][1], code_push_offset=8+exports['I386COCPush'][1], code_pop_offset=8+exports['I386COCPopNoFree'][1], code_free_offset=8+exports['I386COCHeaderFree'][1], code_append_offset=8+exports['I386COCAppend'][1], code_retire_offset=8+exports['I386ICRetire'][1], code_branch_offset=8+exports['I386OptBranch'][1], code_optimize_offset=8+exports['I386OptPass012'][1], out_new_offset=8+exports['I386OutNew'][1], out_del_offset=8+exports['I386OutDel'][1], backend_offset=8+exports['I386BackendCompile'][1], expression_offset=8+exports['I386ParseExpression'][1], type_offset=8+exports['I386ParseType'][1], parser_alloc_offset=8+exports['I386ParserAlloc'][1], parser_free_offset=8+exports['I386ParserFree'][1], parser_token_offset=8+exports['I386ParserToken'][1], declarations_offset=8+exports['I386ParseDeclarations'][1], code_init_offset=8+exports['I386COCInit'][1], class_offset=8+exports['I386ParseClass'][1], fun_join_offset=8+exports['I386ParseFunJoin'][1], publish_classes_offset=8+exports['I386PublishClasses'][1], bootstrap_scalars_offset=8+exports['I386BootstrapScalars'][1], load_scalars_offset=8+exports['I386LoadScalarTypes'][1], scalar_check_offset=8+exports['I386ScalarTypesCheck'][1], frontend_offset=8+exports['I386FrontendServices'][1], statement_offset=8+exports['I386FrontendStatement'][1], command_offset=8+exports['I386FrontendCommand'][1], publish_offset=8+exports['I386FrontendPublish'][1], input_offset=8+exports['I386CommandInput'][1], version_offset=version_offset,
                import_offset=next(offset for name, offset in imports if name == 'I386LexRawChar'))


def console_runtime_layout(module):
    size, count, records = struct.unpack_from('<III', module, 16)
    exports, imports = {}, {}
    for index in range(count):
        kind, offset, name, length = struct.unpack_from('<4I', module, records+16*index)
        if kind in (1, 2, 3, 5):
            symbol = module[name:name+length].decode('ascii')
            if kind in (1, 3): exports[symbol] = (kind, offset)
            else: imports[symbol] = name
    if set(imports) != {'KernelLog', 'KernelHex', 'KernelStop', 'I386HeapAlloc', 'SysTry', 'SysUntry'}:
        raise ValueError('Unexpected console import contract')
    for name in ('Main', 'ConsoleInit', 'ConsoleDisplay', 'ConsoleKeys'):
        if exports.get(name, (0, 0))[0] != 1: raise ValueError(f'Missing console entry {name}')
    if exports.get('console_version', (0, 0))[0] != 3:
        raise ValueError('Missing console version')
    version_offset = 32+exports['console_version'][1]
    if struct.unpack_from('<I', module, version_offset)[0] != 7:
        raise ValueError('Unexpected console version')
    return dict(image_bytes=size+8, version_offset=version_offset, import_offset=imports['KernelLog'],
                entries=[8+exports[name][1] for name in ('ConsoleInit', 'ConsoleDisplay', 'ConsoleKeys')])


def memory_runtime_layout(module):
    size, count, records = struct.unpack_from('<III', module, 16)
    exports, imports = {}, {}
    for index in range(count):
        kind, offset, name, length = struct.unpack_from('<4I', module, records+16*index)
        if kind in (1, 2, 3, 5):
            symbol = module[name:name+length].decode('ascii')
            if kind in (1, 3): exports[symbol] = (kind, offset)
            else: imports[symbol] = name
    if set(imports) != {'I386HeapAlloc', 'I386HeapFree', 'I386HeapSize', 'I386HeapValid',
                       'I386IrqSave', 'I386IrqRestore', 'KernelLog', 'KernelHex', 'KernelStop', 'HashAdd', 'throw'}:
        raise ValueError('Unexpected memory-runtime import contract')
    for name in ('Main', 'MemoryBind', 'MemoryProbe'):
        if exports.get(name, (0, 0))[0] != 1:
            raise ValueError(f'Missing memory service {name}')
    if exports.get('memory_runtime_version', (0, 0))[0] != 3:
        raise ValueError('Missing memory-runtime version')
    version_offset = 32+exports['memory_runtime_version'][1]
    if struct.unpack_from('<I', module, version_offset)[0] != 3:
        raise ValueError('Unexpected memory-runtime version')
    return dict(image_bytes=size+8, version_offset=version_offset,
                import_offset=imports['I386HeapAlloc'],
                entries=[8+exports[name][1] for name in ('MemoryBind', 'MemoryProbe')])


def verify_memory_rejection(disk, volume, out, layout):
    original = disk.read_bytes()
    offset = volume['files']['/Modules/I386/MemoryRuntime.t32m']['block']*512
    results = []
    for label, position, replacement, reason in (
            ('wrong-target', 6, b'\x04', 'load'),
            ('missing-import', layout['import_offset'], b'X', 'load'),
            ('wrong-api', layout['version_offset'], struct.pack('<I', 2), 'api')):
        work = out/f'reject-memory-{label}'
        work.mkdir(parents=True, exist_ok=True)
        changed = bytearray(original)
        changed[offset+position:offset+position+len(replacement)] = replacement
        candidate = work/'kernel.img'; candidate.write_bytes(changed)
        with (work/'runner.log').open('w') as log:
            result = subprocess.run([sys.executable, str(ROOT/'tools/guest-run.py'), str(candidate),
                '--i386-disk', '--out', str(work), '--timeout', '90'], cwd=ROOT, stdout=log, stderr=log)
        evidence = (work/'debug.log').read_text()
        if (result.returncode == 0 or f'MEMORY REJECT {reason} reclaimed\n' not in evidence or
                'FAIL native kernel\n' not in evidence or
                any(marker in evidence for marker in ('MEMORY PROBE ', 'RUNTIME PROBE ',
                    'STARTUP disk module', 'READY native kernel', 'DONE native kernel'))):
            raise ValueError(f'Memory runtime failed rejection/reclamation: {label}')
        if candidate.read_bytes() != changed:
            raise ValueError('Rejected memory module changed disk')
        results.append(label)
    return results


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
    for name in ('Main', 'I386LexTaskFileInclude', 'I386TaskFileRead', 'I386FileRuntimeBind', 'I386TaskFilesInit', 'I386FileRuntimeCompiler', 'I386FileRuntimeControl'):
        if exports.get(name, (0, 0))[0] != 1: raise ValueError(f'Missing file service {name}')
    if exports.get('file_runtime_version', (0, 0))[0] != 3:
        raise ValueError('Missing file-runtime version')
    version_offset = 32+exports['file_runtime_version'][1]
    if version_offset+4 > 32+size or struct.unpack_from('<I', module, version_offset)[0] != 19:
        raise ValueError('Unexpected file-runtime version')
    return dict(image_bytes=size+8, version_offset=version_offset,
        include_offset=8+exports['I386LexTaskFileInclude'][1], read_offset=8+exports['I386TaskFileRead'][1],
        bind_offset=8+exports['I386FileRuntimeBind'][1], init_offset=8+exports['I386TaskFilesInit'][1], compiler_init_offset=8+exports['I386FileRuntimeCompiler'][1], control_new_offset=8+exports['I386FileRuntimeControl'][1], import_offset=imports['I386RedSeaReadAll'])


def verify_file_rejection(disk, volume, out, layout):
    original = disk.read_bytes()
    offset = volume['files']['/Modules/I386/FileRuntime.t32m']['block']*512
    results = []
    for label, position, replacement, reason in (
            ('wrong-target', 6, b'\x04', 'load'),
            ('missing-import', layout['import_offset'], b'X', 'load'),
            ('wrong-api', layout['version_offset'], struct.pack('<I', 18), 'api')):
        work = out/f'reject-files-{label}'
        work.mkdir(parents=True, exist_ok=True)
        changed = bytearray(original)
        changed[offset+position:offset+position+len(replacement)] = replacement
        candidate = work/'kernel.img'; candidate.write_bytes(changed)
        with (work/'runner.log').open('w') as log:
            result = subprocess.run([sys.executable, str(ROOT/'tools/guest-run.py'), str(candidate),
                '--i386-disk', '--out', str(work), '--timeout', '90'], cwd=ROOT, stdout=log, stderr=log)
        evidence = (work/'debug.log').read_text()
        if (result.returncode == 0 or f'FILES REJECT {reason} reclaimed\n' not in evidence or
                'FAIL native kernel\n' not in evidence or
                any(marker in evidence for marker in ('RUNTIME PROBE ', 'INCLUDE PROBE ', 'DISK INCLUDE ',
                    'STARTUP disk module', 'READY native kernel', 'DONE native kernel'))):
            raise ValueError(f'File runtime failed rejection/reclamation: {label}')
        if candidate.read_bytes() != changed: raise ValueError('Rejected file module changed disk')
        results.append(label)
    return results


def verify_console_rejection(disk, volume, out, layout):
    #Console loading follows the expanded root diagnostics, as startup loading does.
    original = disk.read_bytes()
    offset = volume['files']['/Modules/I386/ConsoleRuntime.t32m']['block']*512
    results = []
    for label, position, replacement, reason in (
            ('wrong-target', 6, b'\x04', 'load'),
            ('missing-import', layout['import_offset'], b'X', 'load'),
            ('wrong-api', layout['version_offset'], struct.pack('<I', 6), 'api')):
        work = out/f'reject-console-{label}'
        work.mkdir(parents=True, exist_ok=True)
        changed = bytearray(original)
        changed[offset+position:offset+position+len(replacement)] = replacement
        candidate = work/'kernel.img'; candidate.write_bytes(changed)
        with (work/'runner.log').open('w') as log:
            result = subprocess.run([sys.executable, str(ROOT/'tools/guest-run.py'), str(candidate),
                '--i386-disk', '--out', str(work), '--timeout', '180'], cwd=ROOT, stdout=log, stderr=log)
        evidence = (work/'debug.log').read_text()
        if (result.returncode == 0 or f'CONSOLE REJECT {reason} reclaimed\n' not in evidence or
                'FAIL native kernel\n' not in evidence or
                any(marker in evidence for marker in ('STARTUP disk module', 'READY native kernel', 'DONE native kernel'))):
            raise ValueError(f'Console failed rejection/reclamation: {label}')
        if candidate.read_bytes() != changed: raise ValueError('Rejected console module changed disk')
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
    expected = {'KernelLog', 'KernelHex', 'KernelStop', 'I386HeapSize', 'I386HeapAlloc', 'I386HeapFree',
                'I386HeapValid', 'I386IrqSave', 'I386IrqRestore', 'I386LexRawChar',
                'I386LexIncludeCopy', 'HashAdd', 'StrCmp', 'char_bmp_alpha_numeric', 'SysTry', 'SysUntry', 'throw', 'I386TaskSpawn', 'I386TaskDestroy', 'I386SchedYield'}
    if {name for name, _ in imports} != expected:
        raise ValueError('Unexpected compiler-probe import contract')
    for name in ('Main', 'ProbeTokens', 'ProbeIdent', 'ProbeDefine', 'ProbeConditional', 'ProbeIncludes', 'ProbeIncludePush', 'ProbeDiskIncludes', 'ProbeCompilerUnwind', 'ProbeBranches', 'ProbeOptimize', 'ProbeEmit', 'ProbeBackend'):
        if exports.get(name, (0, 0))[0] != 1:
            raise ValueError(f'Missing compiler-probe function {name}')
    if exports.get('compiler_probe_version', (0, 0))[0] != 3:
        raise ValueError('Missing compiler-probe version')
    version_offset = 32+exports['compiler_probe_version'][1]
    if version_offset+4 > 32+size or struct.unpack_from('<I', module, version_offset)[0] != 11:
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
            ('wrong-api', layout['version_offset'], struct.pack('<I', 10), 'api')):
        work = out/f'reject-probe-{label}'
        work.mkdir(parents=True, exist_ok=True)
        changed = bytearray(original)
        changed[offset+position:offset+position+len(replacement)] = replacement
        candidate = work/'kernel.img'
        candidate.write_bytes(changed)
        with (work/'runner.log').open('w') as log:
            result = subprocess.run([sys.executable, str(ROOT/'tools/guest-run.py'), str(candidate),
                '--i386-disk', '--out', str(work), '--timeout', '90'], cwd=ROOT, stdout=log, stderr=log)
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
            ('wrong-api', layout['version_offset'], struct.pack('<I', 40), 'api')):
        work = out/f'reject-runtime-{label}'
        work.mkdir(parents=True, exist_ok=True)
        changed = bytearray(original)
        changed[offset+position:offset+position+len(replacement)] = replacement
        candidate = work/'kernel.img'
        candidate.write_bytes(changed)
        with (work/'runner.log').open('w') as log:
            result = subprocess.run([sys.executable, str(ROOT/'tools/guest-run.py'), str(candidate),
                '--i386-disk', '--out', str(work), '--timeout', '90'], cwd=ROOT, stdout=log, stderr=log)
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


def division_template_lines(code, disassemble):
    """Audit the named inline template as fall-through code, not a callable function."""
    if len(code) != 185 or code[:6] != bytes.fromhex('55 8b ec 83 ec 10') or code[-3:] != bytes.fromhex('8b e5 5d'):
        raise ValueError('Unexpected division template boundaries/prologue/epilogue')
    lines = disassemble(code).splitlines()
    rows = [line.split() for line in lines]
    offsets = {int(row[0], 16) for row in rows}
    cursor = 0
    for row in rows:
        if len(row) < 3 or int(row[0], 16) != cursor:
            raise ValueError('Noncontiguous division template instructions')
        cursor += len(row[1])//2
        if row[2] in ('call', 'ret', 'iret'):
            raise ValueError('Division template must fall through')
        if row[2].startswith('j'):
            if len(row) != 4 or not row[3].startswith('0x') or int(row[3], 16) not in offsets:
                raise ValueError('Division template branch escapes its instruction boundaries')
    if cursor != len(code):
        raise ValueError('Unclassified division template bytes')
    return lines


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
        if version not in (2,3) or (magic,cpu,pointer,abi,total,records,strings) != (
                0x4D323354,3,4,1,len(module),32+size,32+size+16*count):
            raise ValueError(f'Invalid {name} module header')
        resident = index < len(MODULES)
        code = image[base:base+size] if resident else module[32:32+size]
        if len(code)!=size:
            raise ValueError('Truncated kernel')
        if index==0 or not resident:
            starts, data = [], []
            template_markers = {}
            for i in range(count):
                kind, offset, name_offset, length = struct.unpack_from('<4I',module,records+16*i)
                if kind==1:
                    symbol = module[name_offset:name_offset+length].decode('ascii')
                    if name == 'CompilerRuntime' and symbol in ('_I386_DIV_BEGIN', '_I386_DIV_END'):
                        template_markers[symbol] = offset
                    if name != 'CompilerRuntime' or symbol != '_I386_DIV_END':
                        starts.append(offset)
                elif kind==4:
                    data.append((offset,name_offset))
                elif kind==6:
                    if version!=3 or length or offset>size-4 or name_offset>=size or struct.unpack_from('<I',module,32+offset)[0]:
                        raise ValueError(f'Invalid {name} stored pointer')
                    if resident and struct.unpack_from('<I',code,offset)[0]!=0x11000+base+name_offset:
                        raise ValueError('Flat kernel pointer uses the wrong load address')
            template = None
            if name == 'CompilerRuntime':
                if set(template_markers) != {'_I386_DIV_BEGIN', '_I386_DIV_END'}:
                    raise ValueError('Missing native backend division template markers')
                template = (template_markers['_I386_DIV_BEGIN'], template_markers['_I386_DIV_END'])
                if template[1]-template[0] != 185:
                    raise ValueError('Unexpected native division template size')
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
            boundaries=sorted(set(starts+[begin for begin,_ in data]+[size]+([template[1]] if template else [])))
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
            template=None
        terminal='iret' if name in ('IrqEntry','ExceptionEntry') else 'ret'
        for start,end in spans:
            if template == (start,end):
                lines=division_template_lines(code[start:end],disassemble)
                last=len(lines)-1
            else:
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
    console_layout=console_runtime_layout((exports/'ConsoleRuntime.t32m').read_bytes())
    memory_layout=memory_runtime_layout((exports/'MemoryRuntime.t32m').read_bytes())
    disk=out/'kernel.img'
    run('nasm','-f','bin',f'-DKERNEL_FILE="{exports / "Kernel32.BIN"}"',
        'tools/i386-kernel-stage.asm','-o',str(disk))
    if disk.stat().st_size!=512+4096+len(image) or disk.read_bytes()[512+4096:]!=image:
        raise ValueError('Kernel stage and flat-image load address disagree')
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
            'kernel_bytes':len(image),'kernel_load_address':0x11000,'early_stage_bytes':4096,
            'kernel_sha256':hashlib.sha256(image).hexdigest(),
            'disk_sha256':hashlib.sha256(disk.read_bytes()).hexdigest(),
            'modules':{name:hashlib.sha256((exports/f'{name}.t32m').read_bytes()).hexdigest() for name in DISK_MODULES},
            'bootstrap_modules':list(MODULES),
            'resident_modules':list(MODULES)+['CompilerRuntime', 'FileRuntime', 'ConsoleRuntime', 'MemoryRuntime'],
            'temporary_modules':['Startup', 'CompilerProbe'],
            'volume':volume,
            'scope':'Native kernel with a retained HolyC console and disk source startup; full runtime, DolDoc and self-hosting unfinished',
            'boot_test':None}
    if args.test:
        guest=out/'boot'
        run(sys.executable,'tools/guest-run.py',str(disk),'--i386-disk','--out',str(guest),'--timeout','180')
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
        if len(runtime) != 1 or len(runtime[0]) != 52:
            raise ValueError('Missing retained compiler-runtime image')
        address, size, span, string_address, number_address, char_address, punct_address, ident_address, ident_token_address, string_token_address, next_address, include_address, control_new_address, control_del_address, symbols_init_address, control_enter_address, control_leave_address, control_drain_address, control_unwind_address, code_add_address, code_misc_address, code_discard_address, code_save_address, code_push_address, code_pop_address, code_free_address, code_append_address, code_retire_address, code_branch_address, code_optimize_address, out_new_address, out_del_address, backend_address, expression_address, type_address, parser_alloc_address, parser_free_address, parser_token_address, declarations_address, code_init_address, class_address, fun_join_address, publish_classes_address, bootstrap_scalars_address, load_scalars_address, scalar_check_address, frontend_address, statement_address, command_address, publish_address, input_address = (int(x, 16) for x in runtime[0][1:])
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
                control_del_address != address+runtime_layout['control_del_offset'] or
                symbols_init_address != address+runtime_layout['symbols_init_offset'] or
                control_enter_address != address+runtime_layout['control_enter_offset'] or
                control_leave_address != address+runtime_layout['control_leave_offset'] or
                control_drain_address != address+runtime_layout['control_drain_offset'] or
                control_unwind_address != address+runtime_layout['control_unwind_offset'] or
                code_add_address != address+runtime_layout['code_add_offset'] or
                code_misc_address != address+runtime_layout['code_misc_offset'] or
                code_discard_address != address+runtime_layout['code_discard_offset'] or
                any(value != address+runtime_layout[key] for value,key in (
                    (code_save_address,'code_save_offset'), (code_push_address,'code_push_offset'),
                    (code_pop_address,'code_pop_offset'), (code_free_address,'code_free_offset'),
                    (code_append_address,'code_append_offset'), (code_retire_address,'code_retire_offset'), (code_branch_address,'code_branch_offset'), (code_optimize_address,'code_optimize_offset'), (out_new_address,'out_new_offset'), (out_del_address,'out_del_offset'), (backend_address,'backend_offset'), (expression_address,'expression_offset'), (type_address,'type_offset'), (parser_alloc_address,'parser_alloc_offset'), (parser_free_address,'parser_free_offset'), (parser_token_address,'parser_token_offset'), (declarations_address,'declarations_offset'), (code_init_address,'code_init_offset'), (class_address,'class_offset'), (fun_join_address,'fun_join_offset'), (publish_classes_address,'publish_classes_offset'), (bootstrap_scalars_address,'bootstrap_scalars_offset'), (load_scalars_address,'load_scalars_offset'), (scalar_check_address,'scalar_check_offset'), (frontend_address,'frontend_offset'), (statement_address,'statement_offset'), (command_address,'command_offset'), (publish_address,'publish_offset'), (input_address,'input_offset')))):
            raise ValueError('Compiler-runtime placement, ownership or service address mismatch')
        file_rows = [line.split() for line in log.splitlines() if line.startswith('FILES ')]
        if len(file_rows)!=1 or len(file_rows[0])!=10: raise ValueError('Missing file-runtime ownership evidence')
        file_address, file_size, file_span, file_include, file_read, file_bind, file_init, file_compiler_init, file_control_new = (int(x,16) for x in file_rows[0][1:])
        if (file_size!=files_layout['image_bytes'] or file_span!=((file_size+7)&~7)+16 or
                file_address<begin or file_address+file_size>begin+length or
                file_include!=file_address+files_layout['include_offset'] or
                file_read!=file_address+files_layout['read_offset'] or
                file_bind!=file_address+files_layout['bind_offset'] or
                file_init!=file_address+files_layout['init_offset'] or
                file_compiler_init!=file_address+files_layout['compiler_init_offset'] or
                file_control_new!=file_address+files_layout['control_new_offset']):
            raise ValueError('File-runtime placement or service mismatch')
        disk_includes = [line.split() for line in log.splitlines() if line.startswith('DISK INCLUDE ')]
        if ([list(map(lambda x:int(x,16),row[2:])) for row in disk_includes]!=[[0,68],[1,136]] or
                log.index('DISK INCLUDE ')>log.index('STARTUP disk module') or
                log.rindex('DISK INCLUDE ')<log.rindex('TICK ') or
                log.count('DISK READ 0000000000000000\n')!=1 or
                log.count('DISK READ 0000000000000001\n')!=1 or
                log.count('COMPILER RECOVERY 0000000000000000\n')!=1 or
                log.count('COMPILER RECOVERY 0000000000000001\n')!=1 or
                log.count('DISK IF PRESERVED\n')!=1 or log.count('STORAGE TASK BOUND\n')!=1 or
                not log.index('STARTUP disk module')<log.index('STORAGE TASK BOUND\n')<log.rindex('DISK INCLUDE ')):
            raise ValueError('Retained disk include execution/rejection failed')
        result['file_runtime'] = dict(version=19, image_address=file_address, image_bytes=file_size,
            retained_heap_bytes=file_span, include_address=file_include, read_address=file_read, bind_address=file_bind, init_address=file_init, compiler_init_address=file_compiler_init, control_new_address=file_control_new,
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
        result['compiler_probe'] = dict(module='CompilerProbe', version=11, image_address=probe_address,
            image_bytes=probe_size, temporary_heap_bytes=probe_span, reclaimed_heap_bytes=probe_span,
            phases=['boot', 'task'], lifetime='released after task probe')
        branch_recovery = [line.split() for line in log.splitlines() if line.startswith('BRANCH RECOVERY ')]
        if [int(row[2], 16) for row in branch_recovery] != [0, 1]:
            raise ValueError('Native branch optimizer allocation recovery failed')
        if [int(line.split()[2], 16) for line in log.splitlines() if line.startswith('OPTIMIZER PROBE ')] != [0, 1]:
            raise ValueError('Native shared optimizer probes failed')
        if [int(line.split()[2], 16) for line in log.splitlines() if line.startswith('EMITTER PROBE ')] != [0, 1]:
            raise ValueError('Native owned code emitter probes failed')
        if [int(line.split()[2], 16) for line in log.splitlines() if line.startswith('BACKEND PROBE ')] != [0, 1]:
            raise ValueError('Native shared backend probes failed')
        expression_cases = [tuple(int(value,16) for value in line.split()[2:]) for line in log.splitlines() if line.startswith('EXPRESSION CASE ')]
        if expression_cases != [(phase, case) for phase in (0,1) for case in range(22)]:
            raise ValueError('Native expression execution/recovery cases failed')
        if [int(line.split()[2], 16) for line in log.splitlines() if line.startswith('EXPRESSION PROBE ')] != [0, 1]:
            raise ValueError('Native shared expression parser probes failed')
        if [int(line.split()[3],16) for line in log.splitlines() if line.startswith('PARSER MEMORY PROBE ')] != [0,1]:
            raise ValueError('Native parser allocation ownership/recovery failed')
        if [int(line.split()[3],16) for line in log.splitlines() if line.startswith('PARSER TOKEN PROBE ')] != [0,1]:
            raise ValueError('Native parser token ownership/recovery failed')
        declaration_cases = [tuple(int(value,16) for value in line.split()[2:]) for line in log.splitlines() if line.startswith('DECLARATION CASE ')]
        if declaration_cases != [(phase, case) for phase in (0,1) for case in range(9)]:
            raise ValueError('Native declaration construction/recovery failed')
        scalar_results = [tuple(int(value,16) for value in line.split()[2:]) for line in log.splitlines() if line.startswith('SCALAR RESULT ')]
        scalar_expected = [13, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 1, 24, 1, 0x7FFFFFFFFFFFFFFF, 0]
        if scalar_results != [(phase, case, expected) for phase in (0,1) for case, expected in enumerate(scalar_expected)]:
            raise ValueError('Native parsed scalar union execution failed')
        symbol_cases = [tuple(int(value,16) for value in line.split()[2:]) for line in log.splitlines() if line.startswith('SYMBOL CASE ')]
        if symbol_cases != [(phase, case) for phase in (0,1) for case in range(10)]:
            raise ValueError('Native scalar union/class/function parsing or recovery failed')
        publication_cases = [tuple(int(value,16) for value in line.split()[2:]) for line in log.splitlines() if line.startswith('PUBLICATION CASE ')]
        if publication_cases != [(phase, case) for phase in (0,1) for case in range(10)]:
            raise ValueError('Native class publication lifetime/recovery failed')
        bootstrap_cases = [tuple(int(value,16) for value in line.split()[2:]) for line in log.splitlines() if line.startswith('BOOTSTRAP CASE ')]
        if bootstrap_cases != [(phase, case) for phase in (0,1) for case in range(7)]:
            raise ValueError('Retained scalar bootstrap/recovery failed')
        frontend_cases = [tuple(int(value,16) for value in line.split()[2:]) for line in log.splitlines() if line.startswith('FRONTEND CASE ')]
        if frontend_cases != [(phase, case) for phase in (0,1) for case in range(17)]:
            raise ValueError('Retained frontend expression/default ownership or recovery failed')
        intrinsic_cases = [tuple(int(value,16) for value in line.split()[2:]) for line in log.splitlines() if line.startswith('INTRINSIC CASE ')]
        intrinsic_rejections = [tuple(int(value,16) for value in line.split()[2:]) for line in log.splitlines() if line.startswith('INTRINSIC REJECT ')]
        if intrinsic_cases != [(0,34),(1,34)] or intrinsic_rejections != [(phase,case) for phase in (0,1) for case in range(12)]:
            raise ValueError('Native intrinsic publication or execution failed')
        resident_cases = [tuple(int(value,16) for value in line.split()[2:]) for line in log.splitlines() if line.startswith('RESIDENT CASE ')]
        opaque_cases = [tuple(int(value,16) for value in line.split()[2:]) for line in log.splitlines() if line.startswith('OPAQUE CASE ')]
        task_layouts = [tuple(int(value,16) for value in line.split()[2:]) for line in log.splitlines() if line.startswith('TASK LAYOUT ')]
        if task_layouts != [(phase,992,232) for phase in (0,1)]:
            raise ValueError('Shared public task/CPU layout or native access failed')
        completion_cases = [tuple(int(value,16) for value in line.split()[2:]) for line in log.splitlines() if line.startswith('COMPLETION CASE ')]
        if completion_cases != [(phase,case) for phase in (0,1) for case in range(14)]:
            raise ValueError('Native class completion transaction, identity or recovery failed')
        if opaque_cases != [(phase,case) for phase in (0,1) for case in range(7)]:
            raise ValueError('Native opaque class publication or lifetime failed')
        if resident_cases != [(phase, case) for phase in (0,1) for case in range(7)]:
            raise ValueError('Native resident declaration binding/publication failed')
        statement_cases = [tuple(int(value,16) for value in line.split()[2:]) for line in log.splitlines() if line.startswith('STATEMENT CASE ')]
        if statement_cases != [(phase, case) for phase in (0,1) for case in range(34)]:
            raise ValueError('Native statement/function compilation or recovery failed')
        command_cases = [tuple(int(value,16) for value in line.split()[2:]) for line in log.splitlines() if line.startswith('COMMAND CASE ')]
        if command_cases != [(phase, case) for phase in (0,1) for case in range(16)]:
            raise ValueError('Native command compilation, execution or recovery failed')
        program_cases = [tuple(int(value,16) for value in line.split()[2:]) for line in log.splitlines() if line.startswith('PROGRAM CASE ')]
        if program_cases != [(phase, case) for phase in (0,1) for case in range(12)]:
            raise ValueError('Native program publication/lifetime/recovery failed')
        bootstrap_sources = [line.split()[2:] for line in log.splitlines() if line.startswith('BOOTSTRAP SOURCE ')]
        source_lines = [i for i, line in enumerate((ROOT/'Kernel/Types.HH').read_text().splitlines(), 1) if re.match(r'^[IU](16|32|64)i union [IU](16|32|64)$', line.strip())]
        if bootstrap_sources != [[f'{phase:016X}', f'{case:016X}', f'FL:C:/Kernel/Types.HH,{line}'] for phase in (0,1) for case, line in enumerate(source_lines)]:
            raise ValueError('Native scalar source attribution differs from original file')
        scalar_live = [int(line.split()[2],16) for line in log.splitlines() if line.startswith('SCALAR LIVE ')]
        if scalar_live != [1] or log.index('SCALAR LIVE ') < log.index('PROBE RELEASE '):
            raise ValueError('Permanent scalar bootstrap lifetime evidence missing')
        result['public_scalars'] = dict(source='Kernel/Types.HH', lifetime='root symbol table', validated_phases=scalar_live)
        if sorted([[int(x,16) for x in line.split()[3:]] for line in log.splitlines() if line.startswith('INPUT RUN CASE ')]) != [[phase,kind] for phase in range(2) for kind in range(22)]:
            raise ValueError('Incomplete native input run checks')
        result['compiler_runtime'] = dict(module='CompilerRuntime', version=41, image_address=address,
            image_bytes=size, retained_heap_bytes=span, string_address=string_address,
            number_address=number_address, char_address=char_address, punct_address=punct_address, ident_address=ident_address, ident_token_address=ident_token_address, string_token_address=string_token_address, next_address=next_address, include_address=include_address, control_new_address=control_new_address, control_del_address=control_del_address, symbols_init_address=symbols_init_address, active_control_queue=True, code_retire_address=code_retire_address, code_branch_address=code_branch_address, code_optimize_address=code_optimize_address, out_new_address=out_new_address, out_del_address=out_del_address, backend_address=backend_address, expression_address=expression_address, type_address=type_address, parser_alloc_address=parser_alloc_address, parser_free_address=parser_free_address, parser_token_address=parser_token_address, declarations_address=declarations_address, native_declaration_phases=[0,1], code_init_address=code_init_address, class_address=class_address, fun_join_address=fun_join_address, publish_classes_address=publish_classes_address, bootstrap_scalars_address=bootstrap_scalars_address, load_scalars_address=load_scalars_address, scalar_check_address=scalar_check_address, frontend_address=frontend_address, statement_address=statement_address, command_address=command_address, publish_address=publish_address, input_address=input_address, native_input_phases=[0,1], native_program_phases=[0,1], native_command_phases=[0,1], native_statement_phases=[0,1], native_frontend_phases=[0,1], native_publication_phases=[0,1], native_symbol_phases=[0,1], parser_token_phases=[0,1], parser_memory_phases=[0,1], native_expression_phases=[0,1], native_backend_phases=[0,1], native_emitter_phases=[0,1], code_save_address=code_save_address, code_push_address=code_push_address, code_pop_address=code_pop_address, code_free_address=code_free_address, code_append_address=code_append_address, code_add_address=code_add_address, code_misc_address=code_misc_address, code_discard_address=code_discard_address, compiler_exception_recovery_phases=[0,1], branch_optimizer_recovery_phases=[0,1], shared_optimizer_phases=[0,1], control_unwind_address=control_unwind_address, control_enter_address=control_enter_address, control_leave_address=control_leave_address, control_drain_address=control_drain_address, task_owned_symbols=True, owned_control_phases=['boot','task'], include_phases=['boot', 'task'], conditional_phases=['boot', 'task'], definition_phases=['boot', 'task'], token_stream_phases=['boot', 'task'], probe_phases=['boot', 'task'], identifier_token_phases=['boot', 'task'], string_token_phases=['boot', 'task'], lifetime='kernel lifetime')
        from PIL import Image
        screen=Image.open(guest/'screen.ppm').convert('RGB')
        if screen.size!=(640,480): raise ValueError('Unexpected VGA resolution')
        console=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))
        expected=console['console_pixels'](['TempleOS i386','HolyC console','','> '])
        if screen.tobytes()!=expected:
            raise ValueError('VGA console mismatch')
        screen.save(guest/'screen.png')
        keyboard=console['run_input'](disk,out/'input')
        if hashlib.sha256(disk.read_bytes()).hexdigest()!=result['disk_sha256']:
            raise ValueError('Keyboard console changed the disk')
        result['source_startup']=verify_source_startup(disk,volume,out,console)
        rejected=verify_startup_rejection(disk,volume,out)
        rows=[line.split() for line in log.splitlines()
              if line.startswith('MEMORY ') and not line.startswith('MEMORY PROBE ')]
        if len(rows)!=1 or len(rows[0])!=6:
            raise ValueError('Missing retained public-memory provider')
        mbase,msize,mspan,*entries=[int(x,16) for x in rows[0][1:]]
        if (msize!=memory_layout['image_bytes'] or mspan!=((msize+23)//8)*8 or
                mbase<begin or mbase+msize>begin+length or
                entries!=[mbase+x for x in memory_layout['entries']]):
            raise ValueError('Memory interface/image accounting mismatch')
        phases=[int(line.split()[2],16) for line in log.splitlines() if line.startswith('MEMORY PROBE ')]
        if phases!=[0,1] or log.index('MEMORY PROBE ')>log.index('RUNTIME PROBE '):
            raise ValueError('Root/worker public heap growth and reclamation failed')
        public_memory=[tuple(int(value,16) for value in line.split()[3:])
                       for line in log.splitlines() if line.startswith('PUBLIC MEMORY CASE ')]
        if public_memory!=[(0,12),(1,12)]:
            raise ValueError('Native public allocation/lifetime/OutMem checks failed')
        result['memory_runtime']=dict(version=3,image_address=mbase,image_bytes=msize,
            retained_heap_bytes=mspan,validated_phases=phases,public_api_cases=public_memory,
            rejected=verify_memory_rejection(disk,volume,out,memory_layout))
        result['file_runtime']['rejected']=verify_file_rejection(disk,volume,out,files_layout)
        result['compiler_runtime']['rejected']=verify_compiler_rejection(disk,volume,out,runtime_layout)
        result['compiler_probe']['rejected']=verify_probe_rejection(disk,volume,out,probe_layout)
        rows=[line.split() for line in log.splitlines() if line.startswith('CONSOLE ') and line!='CONSOLE TASK SPAWNED']
        if len(rows)!=1 or len(rows[0])!=7: raise ValueError('Missing retained console')
        cbase,csize,cspan,*entries=[int(x,16) for x in rows[0][1:]]
        if csize!=console_layout['image_bytes'] or cspan!=((csize+23)//8)*8 or entries!=[cbase+x for x in console_layout['entries']]:
            raise ValueError('Console interface/image accounting mismatch')
        result['console_runtime']=dict(version=7,image_bytes=csize,retained_heap_bytes=cspan,
            rejected=verify_console_rejection(disk,volume,out,console_layout))
        for marker in ('PROGRAM PARENT REJECT ', 'PUBLIC HEADER ROLLBACK ', 'PUBLIC HEADER CASE '):
            if sorted(int(line.split()[-1],16) for line in log.splitlines() if line.startswith(marker)) != [0,1]:
                raise ValueError(f'Missing public-header probe: {marker}')
        if sorted([[int(x,16) for x in line.split()[3:]] for line in log.splitlines() if line.startswith('PUBLIC HEADER LAYOUT ')]) != [[0,108],[1,108]]:
            raise ValueError('Missing native public-header layout checks')
        if log.count('PUBLIC HEADERS ok\n')!=1: raise ValueError('Public headers did not load')
        memory=[int(line.split()[-1],16) for line in log.splitlines() if line.startswith('PUBLIC HEADERS MEMORY ')]
        if len(memory)!=1 or memory[0]<=0: raise ValueError('Missing public-header memory accounting')
        lifetimes=[int(line.split()[-1],16) for line in log.splitlines() if line.startswith('CODE HEAP LIFETIME ')]
        released=[int(line.split()[-1],16) for line in log.splitlines() if line.startswith('PROBE TASK RELEASE ')]
        if lifetimes!=[0,1] or len(released)!=1 or released[0]<262144+8192 or not (
                log.index('PROBE RELEASE ') < log.index('PROBE TASK RELEASE ') < log.index('CONSOLE TASK SPAWNED')):
            raise ValueError('Missing public code-heap/task reclamation evidence')
        result['code_heap']={'task_phases':lifetimes,'probe_task_reclaimed_bytes':released[0],
                            'locked_heap_reap':'deferred before symbol teardown'}
        result['public_headers']={'result':'pass','layout_checks_per_phase':108,
                                 'task_phases':[0,1],'retained_heap_bytes':memory[0]}
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
