#!/usr/bin/env python3
"""Exercise configured normal HomeSys startup, retirement and physical reaping."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct
import time

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def symbols(module):
    count, records = struct.unpack_from('<II', module, 20)
    result = {}
    for i in range(count):
        kind, offset, name, length = struct.unpack_from('<4I', module, records+16*i)
        if kind == 3:
            result[module[name:name+length].decode()] = offset
    return result


def physical_state(memory, files, log, bootstrap):
    """Decode loaded task records and actual heap blocks independently of guest APIs."""
    match = re.search(r'^MEMORY ([0-9A-F]+)', log, re.M)
    if not match:
        raise ValueError('Missing loaded memory-provider address')
    provider = files['/Modules/I386/MemoryRuntime.t32m'][2]
    address = int(match[1], 16)+8+symbols(provider)['memory_tasks']
    pointer = struct.unpack_from('<I', memory, address)[0]
    records, seen = [], set()
    while pointer:
        if pointer in seen or not 0 < pointer < len(memory)-20 or len(records) >= 1024:
            raise ValueError('Invalid task-record chain')
        seen.add(pointer)
        following, owned = struct.unpack_from('<II', memory, pointer)
        records.append(dict(record=pointer, owned=owned))
        pointer = following
    if any(record['owned'] == bootstrap for record in records):
        raise ValueError('Bootstrap still has a managed task record')
    kernel = files['/Modules/I386/Kernel.t32m'][2]
    heap_address = 0x100008+symbols(kernel)['kernel_heap']
    start, size, used, peak, allocations, signature = struct.unpack_from('<6I', memory, heap_address)
    if signature != 0x48323349 or start+size > len(memory):
        raise ValueError('Invalid kernel heap descriptor')
    offset, containing = 0, []
    while offset < size:
        span, requested, tag, reserved = struct.unpack_from('<4I', memory, start+offset)
        if span < 16 or span % 8 or offset+span > size or tag not in (0x46523349, 0x55523349):
            raise ValueError('Invalid kernel heap block')
        if start+offset+16 <= bootstrap < start+offset+span:
            containing.append(dict(block=start+offset, span=span, requested=requested, tag=tag))
        offset += span
    if offset != size or len(containing) != 1 or containing[0]['tag'] != 0x46523349:
        raise ValueError('Former bootstrap address is not in a free heap block')
    return dict(result='pass', task_record_count=len(records), bootstrap_records=[],
                containing_free_block=containing[0], memory_tasks_address=address,
                kernel_heap_address=heap_address, heap_used=used, heap_peak=peak,
                heap_allocations=allocations,
                scope='Post-handoff record absence and free containing block; not total heap recovery')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('image', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    source, out = args.image.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    once = ROOT/'tests/guest/i386-desktop-layout-reference/Once.HC'
    profile = ROOT/'tests/guest/i386-desktop-startup-profile/DesktopStart.HC'
    paths = [source, once, profile, Path(__file__).resolve(), ROOT/'Kernel/FontStd.HC',
             ROOT/'tools/test-i386-autocomplete-interaction.py',
             ROOT/'tools/test-i386-original-desktop-layout.py',
             ROOT/'tools/package-i386-native-image.py']
    report = dict(result='running', ram_mib=64, cpu='486,-fpu', accel='kvm',
                  input_sha256={str(p): sha(p) for p in paths},
                  scope='Configured normal boot invokes whole HomeSys without host startup commands. Original geometry, retirement, fresh42 and physical record/free-block state. Configured Once at root and Home; not default Once, full prompt/input/raster or resource qualification.')
    guest = None
    try:
        pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
        snapshot, package = pack['snapshot'], pack['package']
        original_files = snapshot(source.read_bytes())[1]
        replacements = {p: once.read_bytes() for p in ('/Once.HC', '/Home/Once.HC') if p in original_files}
        additions = {'/Home/DesktopStart.HC': profile.read_bytes()}
        if '/Home/Once.HC' not in original_files:
            additions['/Home/Once.HC'] = once.read_bytes()

        def configured(raw):
            tree, files, directories = snapshot(raw)
            for path, data in replacements.items():
                parts = path.strip('/').split('/')
                node = tree
                for part in parts[:-1]:
                    node = node[part][2]
                attr, date, _ = node[parts[-1]]
                node[parts[-1]] = (attr, date, data)
                files[path] = (attr, date, data)
            return tree, files, directories

        package.__globals__['snapshot'] = configured
        try:
            report['packaging'] = package(source, out/'working.img', additions=additions)
        finally:
            package.__globals__['snapshot'] = snapshot
        files = snapshot((out/'working.img').read_bytes())[1]
        for path, entry in original_files.items():
            if path not in replacements and files[path] != entry:
                raise ValueError('Profile changed unrelated file: '+path)
        if set(files) != set(original_files) | set(additions):
            raise ValueError('Unexpected profile file set')
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        started = time.monotonic()
        guest = Guest(out/'working.img', out/'guest', True)
        guest.wait('DONE native desktop startup\n', 900)
        report['observed_startup_seconds'] = time.monotonic()-started
        guest.wait('DONE original desktop layout\n', 120)
        guest.collect()
        match = re.search(r'DESKTOP BOOTSTRAP retire ([0-9A-Fa-f]+)\n', guest.collect())
        if not match:
            raise ValueError('Missing bootstrap retirement marker')
        bootstrap = report['bootstrap_pointer'] = int(match[1], 16)
        expected = runpy.run_path(str(ROOT/'tools/test-i386-original-desktop-layout.py'))['EXPECTED']
        observed = list(struct.unpack('<83q', (guest.out/'desktop-layout.bin').read_bytes()))
        report['geometry'] = observed
        if observed != expected:
            raise ValueError('Configured desktop geometry differs from original')
        guest.screenshot('desktop-before-host-commands')
        guest.command('U0 BRLog(U8*s){while(*s)OutU8(0xE9,*s++);}')
        start = len(guest.collect())
        guest.command(f'if(TaskValidate(0x{bootstrap:X}))BRLog("BR STILL LIVE\\n");else BRLog("BR RETIRED\\n");')
        if 'BR RETIRED\n' not in guest.collect()[start:]:
            raise ValueError('Bootstrap remains live')
        report['bootstrap_retired'] = True
        guest.command('6*7;')
        report['fresh_result'] = guest.result_pixels()
        guest.call('stop')
        guest.call('pmemsave', val=0, size=64*1024*1024, filename=str(out/'after-physical.bin'))
        report['physical'] = physical_state((out/'after-physical.bin').read_bytes(), files, guest.collect(), bootstrap)
        report['physical_sha256'] = sha(out/'after-physical.bin')
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        if guest:
            guest.close()
        report['inputs_unchanged'] = all(sha(Path(p)) == h for p, h in report['input_sha256'].items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Input changed during run')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
