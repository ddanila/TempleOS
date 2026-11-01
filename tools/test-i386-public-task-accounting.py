#!/usr/bin/env python3
"""Independently check bootstrap allocation recovery through public task calls."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = ROOT / 'tools/test-i386-public-tasks.py'
DESCENDANTS = ROOT / 'tools/test-i386-public-task-descendants.py'
EXCEPTIONS = ROOT / 'tools/test-i386-public-task-exceptions.py'
END_CALLBACKS = ROOT / 'tools/test-i386-public-task-end-callbacks.py'


def accounting_layouts(disk):
    build = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))
    paths = {'/Kernel/I386/Memory.HH', '/Kernel/I386/MemoryBacking.HH', '/Kernel/I386/Heap.HH'}
    headers = build['mutated_file_contents'](disk, paths)
    if set(headers) != paths:
        raise ValueError('Missing accounting layout headers on the tested disk')
    names = {'CI386Heap': 'CBootHeap', 'CI386PoolRegion': 'CBootRegion',
             'CI386PublicPool': 'CBootPool', 'CI386BackingRegion': 'CBootOwned',
             'CI386BackingPool': 'CBootBacking'}
    layouts = {}
    for data in headers.values():
        for match in re.finditer(r'class\s+(\w+)(?::\w+)?\s*\{.*?\};', data.decode('latin1'), re.S):
            if match[1] in names:
                source = re.sub(r'//[^\n]*', '', match[0])
                source = re.sub(r'\b(?:' + '|'.join(names) + r')\b', lambda m: names[m[0]], source)
                layouts[match[1]] = re.sub(r'\s+', ' ', source)
    if set(layouts) != set(names):
        raise ValueError('Missing or changed accounting class layouts')
    #Only layout declarations: internal header imports are not public app APIs.
    layout_commands = [('extern class CBootPool;', [])] + [
        (layouts[name], []) for name in names]
    layout_commands.append(('public extern Bool I386HeapValid(CBootHeap *heap);', []))
    return layout_commands, {path: hashlib.sha256(data).hexdigest() for path, data in headers.items()}


def behavior_commands(disk, ram_mib=8):
    layout_commands, header_hashes = accounting_layouts(disk)
    contract = runpy.run_path(str(CONTRACT))['behavior_commands']()
    definitions = [(source, []) for source, _ in contract
                   if source.startswith(('class ', 'I64 ', 'Bool ', 'U0 ', 'CTaskLifeProbe *'))]
    descendants = runpy.run_path(str(DESCENDANTS))['behavior_commands']()
    descendant_definitions = [(source, []) for source, _ in descendants
                              if source.startswith(('class ', 'CDescProbe *', 'CTask *', 'Bool ', 'U0 '))]
    exceptions = runpy.run_path(str(EXCEPTIONS))['behavior_commands']()
    exception_definitions = [(source, []) for source, _ in exceptions
                            if source.startswith(('class ', 'CTryProbe *', 'CTask *', 'Bool ', 'U0 '))]
    callbacks = runpy.run_path(str(END_CALLBACKS))['behavior_commands']()
    callback_definitions = [(source, []) for source, _ in callbacks
                           if source.startswith(('class ', 'CEndProbe *', 'CTask *', 'Bool ', 'U0 '))]
    commands = layout_commands + definitions + descendant_definitions + exception_definitions + callback_definitions + [
        ('CBootHeap *BootHeap(){CBootBacking *p=Fs->data_heap->bp;return p->heap;}', []),
        ('CBootHeap *BootFallback(){CBootBacking *p=Fs->data_heap->bp;return p->fallback;}', []),
        ("Bool BootHeader(){CBootBacking *p=Fs->data_heap->bp;return p->backing_signature=='B32S'&&p->heap->signature==0x48323349&&I386HeapValid(p->heap)&&(!p->fallback||I386HeapValid(p->fallback));}", []),
        ('BootHeader;', ['1']),
        ('CBootHeap *boot_h;CBootHeap *boot_f;I64 boot_u,boot_n,boot_fu,boot_fn;', []),
        ('U0 BootMark(){boot_h=BootHeap;boot_f=BootFallback;boot_u=boot_h->used;boot_n=boot_h->allocations;boot_fu=boot_fn=0;if(boot_f){boot_fu=boot_f->used;boot_fn=boot_f->allocations;}}', []),
        ('Bool BootSame(){return boot_h->used==boot_u&&boot_h->allocations==boot_n&&I386HeapValid(boot_h)&&(!boot_f||boot_f->used==boot_fu&&boot_f->allocations==boot_fn&&I386HeapValid(boot_f));}', []),
        ('Bool BootLive(){I64 i;BootMark;for(i=0;i<20;i++)if(!LifeStart(i&1)||!LifeFinish||!BootSame)return FALSE;return TRUE;}', []),
        ('BootLive;', ['1']),
        ('Bool BootPending(){I64 i;BootMark;for(i=0;i<20;i++)if(!LifePendingRun||!BootSame)return FALSE;return TRUE;}', []),
        ('BootPending;', ['1']),
        ('Bool BootTreeCase(I64 j){return DescStart(j>0,j==2||j==4,j==4,j>=3)&&DescDone&&DescStill;}', []),
        ('Bool BootTree(){I64 i;BootMark;for(i=0;i<20;i++)if(!BootTreeCase(i%5)||!BootSame)return FALSE;return TRUE;}', []),
        ('BootTree;', ['1']),
        ('Bool BootTry(){I64 i;BootMark;for(i=0;i<20;i++)if(!TryStart(i%4)||!TryDone||!BootSame)return FALSE;return TRUE;}', []),
        ('BootTry;', ['1']),
        ('Bool BootEnd(){I64 i;BootMark;for(i=0;i<20;i++)if(!EndStart(i%5)||!EndDone||!BootSame)return FALSE;return TRUE;}', []),
        ('BootEnd;', ['1']),
        ('Bool BootBad(I64 cpu,I64 size,I64 ch,Bool empty=FALSE){BootMark;return LifeRejected(cpu,size,ch,empty)&&BootSame;}', []),
        ("BootBad(1,8192,'Task');", ['1']),
        ("BootBad(-2,8192,'Task');", ['1']),
        ("BootBad(-1,8192,'Task',TRUE);", ['1']),
        ("BootBad(-1,128,'OutMem');", ['1']),
        ("BootBad(-1,8193,'OutMem');", ['1']),
        (f"BootBad(-1,{ram_mib*1024*1024},'OutMem');", ['1']),
        ('Free(LifeState);', []),
        ('Free(DescState);', []),
        ('Free(TryState);', []),
        ('Free(EndState);', []),
        ('6*7;', ['42']),
    ]
    if any(len(source.encode('ascii')) > 255 for source, _ in commands):
        raise ValueError('Accounting contract exceeds the interactive line limit')
    return commands, header_hashes


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--ram-mib', type=int, choices=(8, 64), default=8,
                        help='Native guest RAM; 64 MiB is the full desktop test profile')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    (out / 'result.json').unlink(missing_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    disk_hash, checker_hash, contract_hash = sha(args.disk), sha(Path(__file__)), sha(CONTRACT)
    descendant_hash = sha(DESCENDANTS)
    exception_hash = sha(EXCEPTIONS)
    callback_hash = sha(END_CALLBACKS)
    commands, header_hashes = behavior_commands(args.disk, args.ram_mib)
    runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    behavior = runner(args.disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True, ram_mib=args.ram_mib, welcome=True,
                      startup_check={'status': 'ok', 'answers': [], 'commands': commands})
    if sha(args.disk) != disk_hash or sha(Path(__file__)) != checker_hash or sha(CONTRACT) != contract_hash or sha(DESCENDANTS) != descendant_hash or sha(EXCEPTIONS) != exception_hash or sha(END_CALLBACKS) != callback_hash:
        raise ValueError('Accounting disk or checker changed during execution')
    report = {'result': 'pass', 'behavior': behavior, 'ram_mib': args.ram_mib,
              'disk_sha256': disk_hash, 'checker_sha256': checker_hash,
              'public_contract_sha256': contract_hash, 'source_disk_unchanged': True,
              'descendant_checker_sha256': descendant_hash,
              'exception_checker_sha256': exception_hash,
              'end_callback_checker_sha256': callback_hash,
              'layout_headers_sha256': header_hashes,
              'normal_and_exit_cycles': 20, 'deferred_activation_cycles': 20,
              'descendant_cycles': 20, 'descendant_variants': 5,
              'exception_cycles': 20, 'exception_variants': 4,
              'end_callback_cycles': 20, 'end_callback_variants': 5,
              'creation_rejections': 6, 'oversized_stack_bytes': args.ram_mib*1024*1024,
              'scope': 'Recovery of both bootstrap arenas through public calls, including queued descendants; not late clone-hook failures or dormant disposal'}
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
