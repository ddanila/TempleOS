#!/usr/bin/env python3
"""Compare complete DolDoc output for deterministic, noninteractive demos."""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import runpy
import subprocess

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = r'''
U0 DemoBatchLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 DemoBatchRun(U8 *path,U8 *name)
{
  CDoc *put=DocPut,*doc=DocNew;
  I64 size;
  U8 *data,*line;
  Bool raw=Raw(OFF);
  Fs->put_doc=doc;
  ExeFile(path);
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


def run(image, out, native, outputs):
    Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
    guest = Guest(image, out, native, reference_cpus=1)
    try:
        if native:
            guest.wait('DONE native kernel startup\n')
            guest.command('#include "C:/Probe/DemoBatch.HC"')
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
    args = parser.parse_args()
    if len(set(args.demo)) != len(args.demo):
        parser.error('Each demo may be selected once')
    disk, out = args.disk.resolve(), args.out.resolve()
    input_hash = sha(disk.read_bytes())
    out.mkdir()
    report = dict(result='running', input_sha256=input_hash, entries={},
                  scope='Exact DolDoc output, document cleanup and return to native command input for a batch of noninteractive demos')
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
            if original != native:
                raise ValueError(f'Delivered source differs from the reference: {path}')
            name = f'demo-{index}.DD'
            outputs.append(name)
            calls.append(f'DemoBatchRun("::/{path}","{name}");')
            report['entries'][path] = {'source_sha256': sha(original), 'output_file': name}
        body = (FIXTURE+'\n'.join(calls)+'\nDemoBatchLog("DEMO BATCH DONE\\n");\n').encode()
        (out/'fixture.HC').write_bytes(body)
        (overlay/'Once.HC').write_bytes(body)
        original_image = out/'original.iso'
        subprocess.run(['python3', str(ROOT/'tools/build-iso.py'), '--overlay', str(overlay),
                        '--output', str(original_image)], cwd=ROOT, check=True)
        native_image = out/'native.img'
        pack['package'](disk, native_image, additions={'/Probe/DemoBatch.HC': body})
        original_outputs = run(original_image, out/'original', False, outputs)
        native_outputs = run(native_image, out/'native', True, outputs)
        for path, original, native in zip(args.demo, original_outputs, native_outputs):
            result = 'pass' if original == native else 'fail'
            report['entries'][path].update(result=result, original_sha256=sha(original),
                                           native_sha256=sha(native), bytes=len(original))
        report['result'] = 'pass' if all(e['result'] == 'pass' for e in report['entries'].values()) else 'fail'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        report['inputs_unchanged'] = sha(disk.read_bytes()) == input_hash
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass' or not report['inputs_unchanged']:
        raise SystemExit('Demo batch failed; see result.json')


if __name__ == '__main__':
    main()
