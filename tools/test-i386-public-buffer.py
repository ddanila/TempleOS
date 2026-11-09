#!/usr/bin/env python3
"""Exercise the normal cold CmpBuf API and consume its AOT packets."""
from pathlib import Path
import argparse
import hashlib
import json
import runpy
import struct

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture = ROOT/'tests/guest/i386-public-buffer/Contract.HC'
    paths = [Path(__file__).resolve(), source, fixture, ROOT/'Compiler/OpCodes.DD']
    paths += [ROOT/'tools'/name for name in (
        'test-i386-autocomplete-interaction.py', 'package-i386-native-image.py',
        'build-i386-kernel.py', 'test-i386-timeclock-welcome.py',
        'test-i386-public-task-accounting.py')]
    paths += sorted(p for directory in ('Compiler', 'Kernel')
                    for p in (ROOT/directory).rglob('*')
                    if p.is_file() and p.suffix in ('.HC', '.HH'))
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins,
                  scope='Cold normal CmpBuf, borrowed source, control queue restoration, AOT packet execution through production CmpFixUpJITAsm, exports/imports/globals/defaults/loops/streaming/map output, caller cleanup and literal-owner task reclamation. Not complete Cmp/module/release or error/OOM/cancellation qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    guest = None
    try:
        pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
        before = pack['snapshot'](source.read_bytes())[1]
        for path in paths:
            if path.is_relative_to(ROOT) and path.suffix in ('.HC', '.HH', '.DD'):
                name = '/'+str(path.relative_to(ROOT))
                if name in before and path.read_bytes() != before[name][2]:
                    raise ValueError('Delivered source differs: '+name)
        layouts, layout_hashes = runpy.run_path(str(ROOT/'tools/test-i386-public-task-accounting.py'))['accounting_layouts'](source)
        report['accounting_layout_sha256'] = layout_hashes
        prelude = '\n'.join(text for text, _ in layouts).encode()+b'\n'
        additions = {'/Probe/Buffer.HC': prelude+fixture.read_bytes()}
        report['packaging'] = pack['package'](source, out/'working.img', additions=additions)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        guest = Guest(out/'working.img', out/'guest', True)
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Probe/Buffer.HC"', timeout=900)
        guest.wait('PUBLIC BUFFER DONE\n')
        def words(name, count):
            data = (guest.out/name).read_bytes()
            (out/name).write_bytes(data)
            return list(struct.unpack('<'+str(count)+'q', data))
        report['summary'] = words('buffer-summary.bin', 9)
        flat = words('buffer-records.bin', 140)
        report['records'] = rows = [flat[i:i+10] for i in range(0, 140, 10)]
        report['sizes'] = words('buffer-sizes.bin', 14)
        report['entries'] = words('buffer-entries.bin', 14)
        report['metadata'] = words('buffer-metadata.bin', 14*128)
        (out/'buffer-code.bin').write_bytes((guest.out/'buffer-code.bin').read_bytes())
        if report['summary'] != [1,1,1,42,1,1,1,1,1]:
            raise ValueError('Buffer summary differs: '+str(report['summary']))
        values = [42,0x123456789ABCDEF,42,26,26,98,42,45,16,42,0,0,0,98]
        failures = []
        for i, row in enumerate(rows):
            mains = int(i not in (10,11,12))
            if row[:6] != [1,0,0,1,1,mains] or row[7] != values[i] or row[6]&96:
                failures.append([i,row])
            # The literal #exe follows the original retained-code policy. Its
            # owner task must reclaim everything on exit (summary[6:9]). All
            # other warm calls release their complete caller-owned storage.
            if i != 6 and row[8:] != [0,0]:
                failures.append([i,'heap',row[8:]])
            if not 0 <= report['sizes'][i] <= 4096:
                failures.append([i,'size'])
        code = (out/'buffer-code.bin').read_bytes()
        if len(code) != 14*4096:
            failures.append(['code buffer length',len(code)])
        report['packet_metadata'] = []
        for i in range(14):
            meta = report['metadata'][i*128:(i+1)*128]
            count = meta[127]
            if not 0 <= count <= 31:
                failures.append([i,'metadata count',count])
                continue
            records = [meta[j*4:j*4+3] for j in range(count)]
            report['packet_metadata'].append(records)
            for kind, offset, flags in records:
                if kind in (8,9) and not 0 <= offset <= report['sizes'][i]-4:
                    failures.append([i,'import bounds',offset])
                elif kind in (16,25) and not 0 <= offset < report['sizes'][i]:
                    failures.append([i,'entry bounds',offset])
                elif kind==26 and not 0 <= offset <= offset+flags <= report['sizes'][i]:
                    failures.append([i,'data range bounds',offset,flags])
                elif kind not in (8,9,16,17,25,26):
                    failures.append([i,'unknown record',kind])
            mains = [offset for kind,offset,_ in records if kind==25]
            if mains != ([] if i in (10,11,12) else [report['entries'][i]]):
                failures.append([i,'MAIN metadata',mains])
        for i in (3,4,5,9,13):
            if not rows[i][6]&2:
                failures.append([i,'missing export'])
        for i in (7,8):
            if not rows[i][6]&4:
                failures.append([i,'missing import'])
        if not rows[13][6]&8:
            failures.append([13,'missing literal data range'])
        if failures:
            raise ValueError('Buffer cases differ: '+str(failures))
        log = guest.collect()
        report['publications'] = {name: log.count('PUBLIC '+name+' loaded\n')
                                  for name in ('LEX', 'OPT', 'PARSER', 'BACKEND', 'JIT', 'ASM')}
        if any(count != 1 for count in report['publications'].values()):
            raise ValueError('Unexpected publication count: '+str(report['publications']))
        guest.command('6*7;')
        report['arithmetic_pixels'] = guest.result_pixels()
        guest.close()
        guest = None
        after = pack['snapshot']((out/'working.img').read_bytes())[1]
        changed = {n for n in set(before)|set(after) if before.get(n) != after.get(n)}
        report['changed_files'] = sorted(changed)
        if changed != set(additions)|{'/Probe/Buffer.MAP'}:
            raise ValueError('Unexpected filesystem changes')
        map_data = after['/Probe/Buffer.MAP'][2]
        (out/'Buffer.MAP').write_bytes(map_data)
        text, binary = map_data.split(b'\0',1)
        if text != b'$LK,"BCMap",A="FL:D/Tmp.DD.Z,1",BI=1$\n':
            raise ValueError('Map link or drive rewrite differs: '+repr(text))
        if len(binary)!=32 or struct.unpack('<4I',binary[:16]) != (1,0,16,1):
            raise ValueError('Map debug bin differs')
        line_min,line_max,start,end = struct.unpack('<4I',binary[16:])
        report['map_debug'] = [line_min,line_max,start,end]
        if (line_min,line_max)!=(1,1) or not 0 <= start < end <= report['entries'][9]:
            raise ValueError('Map debug code range differs')
        report['filesystem'] = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](out/'working.img')
        report['result'] = 'pass'
    except BaseException as error:
        report.update(result='fail', error=str(error) or type(error).__name__)
        raise
    finally:
        if guest:
            guest.close()
        report['inputs_unchanged'] = all(sha(Path(name)) == digest for name, digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise ValueError(report.get('error', 'Buffer contract failed'))
    print('PASS normal public CmpBuf contract')


if __name__ == '__main__':
    main()
