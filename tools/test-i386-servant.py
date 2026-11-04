#!/usr/bin/env python3
"""Check actual servant startup, dispatch, idle state and title restoration."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / 'tests/guest/i386-servant/Contract.HC'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path, nargs='?')
    parser.add_argument('--original', action='store_true')
    parser.add_argument('--ram-mib',type=int,choices=(8,64),default=8)
    parser.add_argument('--accel',choices=('tcg','kvm'),default='tcg')
    parser.add_argument('--preload-fixture',action='store_true',help='Package the exact fixture instead of transferring it as keyboard text')
    parser.add_argument('--startup-hook', action='store_true', help='Interpose startup while calling the real default hook')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.original == bool(args.disk):
        parser.error('Choose --original or a native disk')
    fixture = FIXTURE.with_name('StartupHook.HC') if args.startup_hook else FIXTURE
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    files = [Path(__file__).resolve(), fixture,ROOT/'Kernel/SymbolTypes.HH',ROOT/'HomeSys.HC',ROOT/'Adam/SrvStartUpCore.HC']
    for path,name in [(Path(__file__).resolve(),'runner-source.py'),(fixture,'fixture.HC')]:
        copy=out/name;copy.write_bytes(path.read_bytes());files.append(copy)
    if args.original:
        files += [ROOT / p for p in ('Kernel/KTask.HC', 'Kernel/SrvTaskContCore.HC', 'tools/build-iso.py', 'tools/guest-run.py', 'build/rebuild-test/overlay/0000Boot/0000Kernel.BIN.C', 'build/rebuild-test/overlay/Compiler/Compiler.BIN')]
    else:
        files += [args.disk.resolve(), ROOT / 'tools/i386-kernel-input.py', ROOT / 'tools/build-i386-kernel.py', ROOT/'tools/package-i386-native-image.py']
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in files}
    report = dict(result='running', source_setup='original-once' if args.original else ('preloaded' if args.preload_fixture else 'keyboard-transfer'), ram_mib=None if args.original else args.ram_mib, accel='tcg' if args.original else args.accel, startup_hook=args.startup_hook, input_sha256=pins, scope='Actual SrvCmdLine child startup document/window inhibit, idle/awaiting flags, ten wake-master results42, completion metadata, restored title and empty rings; exact fixture bytes; no exact heaps or popup UI coverage')
    if args.startup_hook:report['scope']+='; actual default startup body interposed, called exactly once after inhibit initialization, then hook restored'
    (out / 'result.json').write_text(json.dumps(report, indent=2)+'\n')
    try:
        if args.original:
            overlay = out / 'overlay'
            overlay.mkdir()
            source = fixture.read_text() + '\nU0 DPReport(U8 *s){while(*s)OutU8(0xE9,*s++);}\n'
            source += 'I64 dp_mask=JRContract;U8 *dp_line=MStrPrint("OBS servant mask %d\\n",dp_mask);DPReport(dp_line);Free(dp_line);\n'
            source += 'if(dp_mask==63)DPReport("PASS original servant\\n");else DPReport("FAIL original servant\\n");\nDPReport("DONE servant\\n");\n'
            (overlay / 'Once.HC').write_text(source)
            iso = out / 'original.iso'
            subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay', 'build/rebuild-test/overlay', '--overlay', str(overlay), '--output', str(iso)], cwd=ROOT, check=True)
            subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out', str(out / 'behavior'), '--timeout', '90', '--qmp-stdio'], cwd=ROOT, check=True)
            log = (out / 'behavior/debug.log').read_text()
            if 'OBS servant mask 63\n' not in log or 'PASS original servant\n' not in log:
                raise ValueError('Original servant contract did not pass all six checks')
        else:
            disk = out / 'working.img'
            if args.preload_fixture:
                report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk,disk,additions={'/DollarContract.HC':fixture.read_bytes()})
            else:shutil.copyfile(args.disk, disk)
            commands = [('HashFind("SrvCmdLine",Fs->hash_table,~0)!=NULL;', ['1']), ('HashFind("JobResScan",Fs->hash_table,~0)!=NULL;', ['1'])]
            commands.insert(1, ('HashFind(\"TaskExe\",Fs->hash_table,~0)!=NULL;', ['1']))
            if not args.preload_fixture:
                source = fixture.read_text()
                commands += [(f'U8 *dp_source=CAlloc({len(source)+1});', []),
                             ('U0 DPTransfer(I64 offset,U8 *text,I64 size){MemCpy(dp_source+offset,text,size);}', [])]
                for offset in range(0, len(source), 60):
                    chunk = source[offset:offset+60]
                    command = f'DPTransfer({offset},{json.dumps(chunk.replace(chr(36), chr(36)*2))},{len(chunk)});'
                    if len(command)>255:
                        raise ValueError('Servant fixture transfer exceeds console capacity')
                    commands.append((command, []))
                commands += [(f'FileWrite("C:/DollarContract.HC",dp_source,{len(source)})>0;', ['1']), ('Free(dp_source);', [])]
            if args.startup_hook:commands += [('#include "/Kernel/SymbolTypes.HH"', [])]
            commands += [('#include "C:/DollarContract.HC"', []), ('JRContract;', ['63']), ('6*7;', ['42'])]
            report['behavior'] = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input'](disk, out / 'behavior', cpu='486,-fpu', ram_mib=args.ram_mib, accel=args.accel, qmp_stdio=True, snapshot=False, welcome=True, keep_window_manager=True, startup_check={'status':'ok', 'answers':[], 'pause_window_manager':False, 'commands':commands})
        if not args.original:
            report['filesystem_integrity']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](disk)
            saved = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk, {'/DollarContract.HC'}).get('/DollarContract.HC')
            report['guest_fixture_sha256'] = hashlib.sha256(saved).hexdigest() if saved is not None else None
            if saved != fixture.read_bytes():
                raise ValueError('Guest fixture differs byte-for-byte from the pinned source')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        changed = [p for p, digest in pins.items() if sha(Path(p)) != digest]
        if changed:
            report.update(result='fail', error='Servant contract inputs changed', changed_inputs=changed)
        (out / 'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise RuntimeError(report['error'])


if __name__ == '__main__':
    main()
