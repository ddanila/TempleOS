#!/usr/bin/env python3
"""Run failed Cmp/CmpBuf ownership against rebuilt original x64 binaries."""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bootstrap', type=Path, default=ROOT/'build/rebuild-test')
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--observe-baseline', action='store_true')
    args = parser.parse_args()
    bootstrap, out = args.bootstrap.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture = ROOT/'tests/guest/buffer-error-original/Contract.HC'
    paths = [Path(__file__).resolve(), fixture, bootstrap/'result.json',
             bootstrap/'overlay/Compiler/Compiler.BIN', bootstrap/'overlay/0000Boot/0000Kernel.BIN.C',
             ROOT/'tools/build-iso.py', ROOT/'tools/guest-run.py']
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins,
                  scope='Ten actual normal Cmp failures through its internal CmpBuf on generated original x64 compiler/kernel; unchanged source files, queue, error counts, exact caller heap counters and subsequent successful file compilation. Not native backing, OOM, cancellation or arbitrary exception qualification.')
    try:
        manifest = json.loads((bootstrap/'result.json').read_text())
        if manifest['result'] != 'pass':
            raise ValueError('Bootstrap is not qualified')
        for name, path in [('Compiler.BIN', paths[3]), ('Kernel.BIN', paths[4])]:
            if sha(path) != manifest['generations'][-1][name]:
                raise ValueError('Bootstrap binary differs: '+name)
        if not args.observe_baseline:
            for name, digest in manifest['source_sha256'].items():
                if name.startswith(('Kernel/', 'Compiler/')):
                    paths.append(ROOT/name)
                    pins[str(ROOT/name)] = sha(ROOT/name)
                    if pins[str(ROOT/name)] != digest:
                        raise ValueError('Bootstrap source differs: '+name)
        report['bootstrap_source_sha256'] = manifest['source_sha256']
        overlay = out/'overlay'
        (overlay/'Probe').mkdir(parents=True)
        (overlay/'Probe/Contract.HC').write_bytes(fixture.read_bytes())
        (overlay/'Once.HC').write_text('''U0 BOReport(U8 *text){while(*text)OutU8(0xE9,*text++);}
BOReport("START original buffer errors\\n");
while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
try { ExeFile("::/Probe/Contract.HC"); }
catch {
  I64 size;U8 *data=DocSave(DocPut,&size),*line=MStrPrint("EXPORT original-errors.DD %X %X\\n",data,size);
  BOReport(line);Free(line);Fs->catch_except=TRUE;BOReport("FAIL original buffer errors\\n");
}
''')
        (out/'fixture.HC').write_bytes(fixture.read_bytes())
        (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
        subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(bootstrap/'overlay'),
                        '--overlay', str(overlay), '--output', str(out/'original.iso')], cwd=ROOT, check=True)
        subprocess.run(['python3', 'tools/guest-run.py', str(out/'original.iso'), '--out', str(out/'guest'),
                        '--qmp-stdio', '--timeout', '300'], cwd=ROOT, check=True)
        data = (out/'guest/buffer-errors.bin').read_bytes()
        report['records'] = list(struct.unpack('<70q', data))
        if args.observe_baseline:
            report['result'] = 'observed'
        else:
            if any(report['records'][i*7:i*7+6] != [1, 1, 1, 0, 0, 1] for i in range(10)):
                raise ValueError('Original failed-buffer ownership differs: '+str(report['records']))
            report['result'] = 'pass'
    except BaseException as error:
        report.update(result='fail', error=str(error) or type(error).__name__)
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == h for p, h in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] == 'fail':
        raise ValueError(report['error'])
    print(report['result'].upper(), 'original failed Cmp/CmpBuf ownership')


if __name__ == '__main__':
    main()
