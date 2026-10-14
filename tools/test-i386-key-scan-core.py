#!/usr/bin/env python3
"""Execute the unchanged ScanKey core on i386 with a controlled echo callback."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = [0,0,0, 1,97,0x1E,0, 1,0,0x4B,1,
            1,99,0x8000002E,1,99,0x8000002E,
            1,100,0x20,2,100,0x20,0]
COMMANDS = [
    ('I64 KI[24],key_echo_count=0,key_echo_ch=0,key_echo_sc=0;Bool key_old_desc;', []),
    ('U0 KeyEchoRecord(I64 ch,I64 sc){key_echo_count++;key_echo_ch=ch;key_echo_sc=sc;}', []),
    ('#define PutKey KeyEchoRecord', []), ('#define ScanKey SharedScanKey', []),
    ('#include "/Kernel/KeyScanCore.HC"', []),
    ('U0 KeyScan(I64 slot,Bool echo=FALSE){I64 ch=99,sc=99;KI[slot]=SharedScanKey(&ch,&sc,echo);KI[slot+1]=ch;KI[slot+2]=sc;}', []),
    ('U0 KeyEcho(I64 slot){KI[slot]=key_echo_count;KI[slot+1]=key_echo_ch;KI[slot+2]=key_echo_sc;}', []),
    ('U0 KeySetup(){key_old_desc=LBtr(&Fs->win_inhibit,12);FlushMsgs;KeyScan(0);}', []), ('KeySetup;', []),
    ('U0 KeyFiltered(){FlushMsgs;PostMsg(Fs,MSG_KEY_UP,117,0x9E);PostMsg(Fs,MSG_MS_MOVE,7,8);PostMsg(Fs,MSG_KEY_DOWN,97,0x1E);KeyScan(3);KI[6]=ScanMsg(NULL,NULL,~1);}', []), ('KeyFiltered;', []),
    ('PostMsg(Fs,MSG_KEY_DOWN,0,0x4B);KeyScan(7);', []),
    ('U0 KeyNull(){PostMsg(Fs,MSG_KEY_DOWN,0,0x4B);KI[10]=SharedScanKey(NULL,NULL);}', []), ('KeyNull;', []),
    ('PostMsg(Fs,MSG_KEY_DOWN,99,0x8000002E);KeyScan(11,TRUE);KeyEcho(14);', []),
    ('U0 KeyFilter(){LBts(&Fs->win_inhibit,12);PostMsg(Fs,MSG_KEY_DOWN,120,0x8000002D);PostMsg(Fs,MSG_KEY_DOWN,100,0x20);KeyScan(17,TRUE);KeyEcho(20);KI[23]=SharedScanKey(NULL,NULL);}', []), ('KeyFilter;', []),
    ('U0 KeyRestore(){LBEqu(&Fs->win_inhibit,12,key_old_desc);}', []), ('KeyRestore;', []),
    ('FileWrite("C:/KeyInput.DATA",KI,sizeof(KI))>0;', ['1']), ('6*7;', ['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--public-bindings',action='store_true',
                        help='Exercise exported ScanKey and real KeyDev dispatch instead of the test alias')
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    if args.public_bindings:
        commands = [(s.replace('SharedScanKey','ScanKey'),answers)
                    for s,answers in commands if not s.startswith(('#define','#include'))]
        commands[2:2] = [
            ('CKeyDevEntry *key_echo_hook;',[]),
            ('Bool KeyEchoHook(I64 ch,I64 sc){KeyEchoRecord(ch,sc);return TRUE;}',[])]
        commands = [(s.replace('key_old_desc=LBtr','key_echo_hook=KeyDevAdd(&KeyEchoHook,NULL,10,TRUE);key_old_desc=LBtr')
                      .replace('U0 KeyRestore(){','U0 KeyRestore(){KeyDevRem(key_echo_hook);'),answers)
                    for s,answers in commands]
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    reference = ROOT/'tools/test-i386-key-input-reference.py'
    builder = ROOT/'tools/build-i386-kernel.py'
    pins = {str(p):sha(p) for p in [source, runner, reference, builder, Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='Shared ScanKey body on real native message queues: empty/filtered/zero-character/null-output cases, echo arguments and descriptor filtering; test-only echo callback, not public bindings, KeyDev dispatch or GetKey waiting',
                  input_sha256=pins, commands=commands)
    report['mode'] = 'public-bindings' if args.public_bindings else 'shared-core-alias'
    if args.public_bindings:
        report['scope'] = 'Public ScanKey and real KeyDev echo dispatch: 24 queue/character/scan-code/descriptor fields; not GetKey waiting, default document echo or raw/debug paths'
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejection_prefixes':('INPUT REJECT ',),
                           'command_timeout':120})
        import struct
        expected = EXPECTED
        data = runpy.run_path(str(builder))['mutated_file_contents'](working, {'/KeyInput.DATA'})['/KeyInput.DATA']
        report['observed'] = list(struct.unpack('<24q',data))
        if data != struct.pack('<24q',*expected):
            raise ValueError('Native key input differs from original byte oracle')
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == digest for p,digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Native fixture inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':
        raise ValueError(report['error'])


if __name__=='__main__':
    main()
