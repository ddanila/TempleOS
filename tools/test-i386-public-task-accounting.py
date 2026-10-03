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


def behavior_commands(disk):
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
    contract = runpy.run_path(str(CONTRACT))['behavior_commands']()
    definitions = [(source, []) for source, _ in contract
                   if source.startswith(('class ', 'I64 ', 'Bool ', 'U0 ', 'CTaskLifeProbe *'))]
    commands = layout_commands + definitions + [
        ('CBootHeap *BootHeap(){CBootBacking *p=Fs->data_heap->bp;return p->heap;}', []),
        ("Bool BootHeader(){CBootBacking *p=Fs->data_heap->bp;return p->backing_signature=='B32S'&&p->heap->signature==0x48323349&&I386HeapValid(p->heap);}", []),
        ('BootHeader;', ['1']),
        ('Bool BootSame(CBootHeap *h,I64 used,I64 count){return h->used==used&&h->allocations==count&&I386HeapValid(h);}', []),
        ('Bool BootLive(){CBootHeap *h=BootHeap;I64 i,u=h->used,n=h->allocations;for(i=0;i<20;i++)if(!LifeStart(i&1)||!LifeFinish||!BootSame(h,u,n))return FALSE;return TRUE;}', []),
        ('BootLive;', ['1']),
        ('Bool BootPending(){CBootHeap *h=BootHeap;I64 i,u=h->used,n=h->allocations;for(i=0;i<20;i++)if(!LifePendingRun||!BootSame(h,u,n))return FALSE;return TRUE;}', []),
        ('BootPending;', ['1']),
        ('Bool BootBad(I64 cpu,I64 size,I64 ch,Bool empty=FALSE){CBootHeap *h=BootHeap;I64 u=h->used,n=h->allocations;return LifeRejected(cpu,size,ch,empty)&&BootSame(h,u,n);}', []),
        ("BootBad(1,8192,'Task');", ['1']),
        ("BootBad(-2,8192,'Task');", ['1']),
        ("BootBad(-1,8192,'Task',TRUE);", ['1']),
        ("BootBad(-1,128,'OutMem');", ['1']),
        ("BootBad(-1,8193,'OutMem');", ['1']),
        ("BootBad(-1,0x800000,'OutMem');", ['1']),
        ('Free(LifeState);', []),
        ('6*7;', ['42']),
    ]
    if any(len(source.encode('ascii')) > 255 for source, _ in commands):
        raise ValueError('Accounting contract exceeds the interactive line limit')
    return commands, {path: hashlib.sha256(data).hexdigest() for path, data in headers.items()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    (out / 'result.json').unlink(missing_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    disk_hash, checker_hash, contract_hash = sha(args.disk), sha(Path(__file__)), sha(CONTRACT)
    commands, header_hashes = behavior_commands(args.disk)
    runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    behavior = runner(args.disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True,
                      startup_check={'status': 'ok', 'answers': [], 'commands': commands})
    if sha(args.disk) != disk_hash or sha(Path(__file__)) != checker_hash or sha(CONTRACT) != contract_hash:
        raise ValueError('Accounting disk or checker changed during execution')
    report = {'result': 'pass', 'behavior': behavior,
              'disk_sha256': disk_hash, 'checker_sha256': checker_hash,
              'public_contract_sha256': contract_hash, 'source_disk_unchanged': True,
              'layout_headers_sha256': header_hashes,
              'normal_and_exit_cycles': 20, 'deferred_activation_cycles': 20,
              'creation_rejections': 6,
              'scope': 'Bootstrap used bytes, allocation count and heap validity through public calls; not descendant or dormant-disposal accounting'}
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
