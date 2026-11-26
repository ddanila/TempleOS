#!/usr/bin/env python3
"""Validate complete DolDoc output for noninteractive demos."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import runpy
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = r'''
U0 DemoBatchLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 DemoBatchRun(U8 *path,U8 *name,I64 seed=0)
{
  CDoc *put=DocPut,*doc=DocNew;
  I64 size,previous_seed=Fs->rand_seed;
  U8 *data,*line;
  Bool raw=Raw(OFF),previous_fixed=Bt(&Fs->task_flags,TASKf_NONTIMER_RAND);
  if(seed)Seed(seed);
  Fs->put_doc=doc;
  ExeFile(path);
  if(seed) {
    Fs->rand_seed=previous_seed;
    if(previous_fixed)LBts(&Fs->task_flags,TASKf_NONTIMER_RAND);
    else LBtr(&Fs->task_flags,TASKf_NONTIMER_RAND);
  }
  if(Fs->put_doc!=doc)throw('Batch',TRUE);
  Fs->put_doc=put;
  data=DocSave(doc,&size);
  line=MStrPrint("EXPORT %s %X %X\n",name,data,size);
  DemoBatchLog(line);
  Sleep(1000);
  Free(line);Free(data);DocDel(doc);Raw(raw);
}
'''


def sha(data):
    return hashlib.sha256(data).hexdigest()


def demo_path(value):
    path = PurePosixPath(value)
    if (len(path.parts) < 2 or path.parts[0] != 'Demo' or path.suffix != '.HC'
            or '..' in path.parts or any(c in value for c in '"\\\r\n')):
        raise argparse.ArgumentTypeError('Expected a HolyC path under Demo/')
    return path.as_posix()


def calendar_matches(doc, started, finished):
    """Compare the full DateTime document against the guest's UTC run window."""
    weekdays = ('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')
    months = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')
    for second in range(started - 1, finished + 2):
        # The demo calls Now three times. A read can straddle a second boundary.
        date = datetime.fromtimestamp(second, timezone.utc)
        for clock_tick in (second, second + 1):
            clock = datetime.fromtimestamp(clock_tick, timezone.utc)
            for fields_tick in (clock_tick, clock_tick + 1):
                fields = datetime.fromtimestamp(fields_tick, timezone.utc)
                expected = (f"\n\n{date:%m/%d/%y} {clock:%H:%M:%S}\n\n\n"
                            f"Hour:{fields.hour:02d} Minute:{fields.minute:02d} "
                            f"Second:{fields.second:02d}\n\n\n"
                            f"Day Name:{weekdays[fields.weekday()]}\n\n\n"
                            f"Month Name:{months[fields.month - 1]}\n\n\n\x05")
                if doc == expected.encode('ascii'):
                    return True
    return False


def optimization_times(doc, native):
    """Require the exact benchmark transcript apart from measured times and CPU frequency."""
    header = rb'001 Cores ([1-9][0-9]*) Hz counter\n' if native else rb'001 Cores +[0-9]+\.[0-9]+[kMGT]Hz\n'
    total = 80_000_000 * 80_000_001 // 2
    result = rb'\nRes:' + str(total).encode() + rb' Time: *([0-9]+\.[0-9]{6})\n'
    pattern = header + result.join((b'Bad Code', b'Good Code #1',
                                    b'Good Code #2', b'Good Code #3')) + result + b'\x05'
    match = re.fullmatch(pattern, doc)
    if not match:
        return []
    times = [float(value) for value in match.groups()[-4:]]
    return times if all(value > 0 for value in times) else []


def run(image, out, native, outputs, reference_at_prompt=False):
    Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
    guest = Guest(image, out, native, reference_cpus=1)
    try:
        if native:
            guest.wait('DONE native kernel startup\n')
            guest.command('#include "C:/Probe/DemoBatch.HC"')
        elif reference_at_prompt:
            guest.wait('DEMO BATCH READY\n')
            guest.type('ExeFile("T:/Probe/DemoBatch.HC");')
            guest.press('ret')
        guest.wait('DEMO BATCH DONE\n')
        observed = [(out/name).read_bytes() for name in outputs]
        guest.screenshot('after-batch')
        if native:
            guest.command('6*7;')
            guest.result_pixels()
        return observed
    finally:
        guest.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--demo', type=demo_path, action='append', required=True)
    parser.add_argument('--native-port', type=demo_path, action='append', default=[],
                        help='Require the bundled native source to match the checked-out port')
    parser.add_argument('--seed', type=int, help='Reset the task RNG to this seed before each demo')
    parser.add_argument('--reference-at-prompt', action='store_true',
                        help='Launch the original fixture through the keyboard after Once.HC')
    args = parser.parse_args()
    if len(set(args.demo)) != len(args.demo):
        parser.error('Each demo may be selected once')
    if not set(args.native_port) <= set(args.demo):
        parser.error('Every native port must also be selected as a demo')
    if args.seed is not None and not 1 <= args.seed < 1 << 63:
        parser.error('Use a positive signed 64-bit seed')
    disk, out = args.disk.resolve(), args.out.resolve()
    input_hash = sha(disk.read_bytes())
    port_hashes = {path: sha((ROOT/path).read_bytes()) for path in args.native_port}
    out.mkdir()
    report = dict(result='running', input_sha256=input_hash, entries={}, seed=args.seed,
                  scope='Complete DolDoc validation, document cleanup and return to native command input for a batch of noninteractive demos')
    try:
        overlay = out/'original-source'
        runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
        pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
        _, delivered, _ = pack['snapshot'](disk.read_bytes())
        outputs = []
        calls = []
        for index, path in enumerate(args.demo):
            original = (overlay/path).read_bytes()
            native = delivered['/'+path][2]
            expected_hash = port_hashes.get(path, sha(original))
            if sha(native) != expected_hash:
                raise ValueError(f'Delivered source differs from the expected source: {path}')
            name = f'demo-{index}.DD'
            outputs.append(name)
            calls.append(f'DemoBatchRun("::/{path}","{name}",{args.seed or 0});')
            report['entries'][path] = {'source_sha256': sha(original), 'output_file': name}
            if path in port_hashes:
                report['entries'][path]['native_source_sha256'] = expected_hash
        body = (FIXTURE+'\n'.join(calls)+'\nDemoBatchLog("DEMO BATCH DONE\\n");\n').encode()
        (out/'fixture.HC').write_bytes(body)
        if args.reference_at_prompt:
            report['reference_at_prompt'] = True
            (overlay/'Probe').mkdir(exist_ok=True)
            (overlay/'Probe/DemoBatch.HC').write_bytes(body)
            (overlay/'Once.HC').write_text(
                'U0 DemoBatchReferenceReady()\n'
                '{\n'
                '  U8 *s="DEMO BATCH READY\\n";\n'
                '  while(*s)OutU8(0xE9,*s++);\n'
                '}\n'
                'DemoBatchReferenceReady;\n')
        else:
            (overlay/'Once.HC').write_bytes(body)
        original_image = out/'original.iso'
        subprocess.run(['python3', str(ROOT/'tools/build-iso.py'), '--overlay', str(overlay),
                        '--output', str(original_image)], cwd=ROOT, check=True)
        native_image = out/'native.img'
        pack['package'](disk, native_image, additions={'/Probe/DemoBatch.HC': body})
        original_start = int(time.time())
        original_outputs = run(original_image, out/'original', False, outputs,
                               args.reference_at_prompt)
        original_end = int(time.time())
        for path, original in zip(args.demo, original_outputs):
            report['entries'][path].update(original_sha256=sha(original), bytes=len(original))
        native_start = int(time.time())
        native_outputs = run(native_image, out/'native', True, outputs)
        native_end = int(time.time())
        for path, original, native in zip(args.demo, original_outputs, native_outputs):
            entry = report['entries'][path]
            if path == 'Demo/DateTime.HC':
                entry['utc_windows'] = {'original': [original_start, original_end],
                                        'native': [native_start, native_end]}
                matches = (calendar_matches(original, original_start, original_end)
                           and calendar_matches(native, native_start, native_end))
            elif path == 'Demo/Lectures/Optimization.HC':
                times = {'original': optimization_times(original, False),
                         'native': optimization_times(native, True)}
                entry['elapsed_seconds'] = times
                matches = all(times.values())
            else:
                matches = original == native
            result = 'pass' if matches else 'fail'
            entry.update(result=result, native_sha256=sha(native))
        report['result'] = 'pass' if all(e['result'] == 'pass' for e in report['entries'].values()) else 'fail'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        report['inputs_unchanged'] = (sha(disk.read_bytes()) == input_hash
                                      and all(sha((ROOT/path).read_bytes()) == digest
                                              for path, digest in port_hashes.items()))
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass' or not report['inputs_unchanged']:
        raise SystemExit('Demo batch failed; see result.json')


if __name__ == '__main__':
    main()
