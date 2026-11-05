#!/usr/bin/env python3
"""Compare complete settings bodies using the real initialized autocomplete task."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = [255, 127, 31, 63, 95293]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk', type=Path, nargs='?')
    ap.add_argument('--reference', type=Path)
    ap.add_argument('--archive', type=Path, required=True,
                    help='Qualified original ACWords archive output directory')
    ap.add_argument('--out', type=Path, required=True)
    args = ap.parse_args()
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    archive_dir = args.archive.resolve()
    archive = archive_dir/'guest/ACWords.DATA.Z'
    archive_report = archive_dir/'result.json'
    archive_info = json.loads(archive_report.read_text())
    if (archive_info.get('result') != 'pass' or
            not archive_info.get('inputs_unchanged') or
            archive_info.get('archive_sha256') != sha(archive)):
        raise ValueError('Qualified original dictionary archive required')
    names = ['tests/guest/i386-task-settings/Contract.HC',
             'tests/guest/i386-task-settings-tasks/Contract.HC',
             'tests/guest/i386-task-settings-remote/Contract.HC',
             'tests/guest/i386-settings-lifecycle/Contract.HC']
    paths = [ROOT/name for name in names]
    source = b'\n'.join(p.read_bytes() for p in paths)
    settings = ROOT/'Adam/TaskSettingsCore.HC'
    original = subprocess.check_output(
        ['git', 'show', 'c26482bb6ad3f80106d28504ec5db3c6a360732c:Adam/TaskSettings.HC'], cwd=ROOT)
    if original[original.index(b'public CTaskSettings *SettingsPush'):].strip() != settings.read_bytes().strip():
        raise ValueError('Settings core differs from complete pinned original bodies')
    paths += [settings, ROOT/'Adam/TaskSettings.HC', archive, archive_report,
              Path(__file__).resolve()] + [ROOT/n for n in (
                  'tools/build-iso.py', 'tools/guest-run.py', 'tools/test-i386-timeclock-reference.py',
                  'tools/package-i386-native-image.py', 'tools/build-i386-kernel.py',
                  'tools/test-i386-timeclock-welcome.py', 'Kernel/FontStd.HC')]
    if args.disk:
        if not args.reference:
            ap.error('Native run requires --reference')
        gold = args.reference.resolve()
        info = json.loads((gold/'result.json').read_text())
        if (info.get('result') != 'pass' or not info.get('inputs_unchanged') or
                info.get('rows') != EXPECTED or
                (gold/'settings-lifecycle.bin').read_bytes() != struct.pack('<5q', *EXPECTED)):
            raise ValueError('Passing original lifecycle reference required')
        paths += [args.disk.resolve(), gold/'result.json', gold/'settings-lifecycle.bin']
    out.mkdir(parents=True)
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', mode='native' if args.disk else 'pinned-original',
                  expected=EXPECTED, input_sha256=pins,
                  scope='Complete unchanged settings bodies with actual dictionary initialization and autocomplete. Native library publication occurs in Adam and contracts execute in its child console. Nested field/palette/window/directory restoration, song/animation replacement and TSF_SAME_SONG, remote-task settings, active autocomplete preservation/restart and inactive restoration. Not waveform, failure cleanup, default startup or whole application qualification.')
    try:
        if args.disk:
            disk = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            required = ['Adam/TaskSettings.HC', 'Adam/TaskSettingsCore.HC',
                        'Adam/AutoComplete/MakeAC.HC', 'Adam/AutoComplete/ACFill.HC',
                        'Adam/AutoComplete/ACTask.HC', 'Adam/AutoComplete/ACInit.HC',
                        'Adam/AutoComplete/ACWords.DATA', 'Adam/AutoComplete/ACDefs.DATA']
            files = pack['snapshot'](args.disk.read_bytes())[1]
            for name in required:
                paths.append(ROOT/name)
                pins[str(ROOT/name)] = sha(ROOT/name)
                if files['/'+name][2] != (ROOT/name).read_bytes():
                    raise ValueError('Shipped source/asset differs: '+name)
            native_source = source + b'\nU0 SettingsLifecycleWrite(){I64 *rows=SettingsLifecycleRows;FileWrite("C:/SettingsLifecycle.DATA",rows,40);Free(rows);}\n'
            report['packaging'] = pack['package'](args.disk.resolve(), disk, additions={
                '/Probe/SettingsLifecycle.HC': native_source,
                '/Adam/AutoComplete/ACWords.DATA.Z': archive.read_bytes()},
                addition_attributes={'/Adam/AutoComplete/ACWords.DATA.Z': 0xC00})
            commands = ['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);',
                        'Adam("ACInit;");', 'AdamFile("C:/Adam/TaskSettings.HC",FALSE);',
                        '#include "C:/Probe/SettingsLifecycle.HC"', 'SettingsLifecycleWrite;', '6*7;']
            report['commands'] = commands
            runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](
                disk, out/'guest', commands, 64, True, accel='kvm', command_timeout=1800)
            build = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
            data = build['mutated_file_contents'](disk, {'/SettingsLifecycle.DATA'})['/SettingsLifecycle.DATA']
            report['filesystem'] = build['verify_mutated_volume'](disk)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            ref = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))
            report['reference_sha256'] = ref['restore_reference'](overlay)
            (overlay/'Adam/AutoComplete/ACWords.DATA.Z').write_bytes(archive.read_bytes())
            once = source + b'\nU0 SettingsLifecycleLog(U8 *s){while(*s)OutU8(0xE9,*s++);}\n'
            once += b'ACInit;I64 *settings_rows=SettingsLifecycleRows;U8 *settings_notice=MStrPrint("EXPORT settings-lifecycle.bin %X %X\\n",settings_rows,40);SettingsLifecycleLog(settings_notice);SettingsLifecycleLog("DONE settings lifecycle\\n");\n'
            (overlay/'Once.HC').write_bytes(once)
            iso = out/'original.iso'
            subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay), '--output', str(iso)], cwd=ROOT, check=True)
            report['iso_sha256'] = sha(iso)
            subprocess.run(['python3', 'tools/guest-run.py', str(iso), '--out', str(out/'guest'), '--qmp-stdio', '--timeout', '180'], cwd=ROOT, check=True)
            data = (out/'guest/settings-lifecycle.bin').read_bytes()
        (out/'settings-lifecycle.bin').write_bytes(data)
        report['rows'] = list(struct.unpack('<5q', data))
        if report['rows'] != EXPECTED:
            raise ValueError('Settings lifecycle differs: '+repr(report['rows']))
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(p.is_file() and sha(p) == pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:
            report['result'] = 'fail'
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
