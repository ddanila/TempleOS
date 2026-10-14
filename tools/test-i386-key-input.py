#!/usr/bin/env python3
"""Check ScanKey/GetKey against the original queue/echo/wait byte oracle."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('I64 KeyEmpty(){I64 ch=99,sc=99;FlushMsgs;return !ScanKey(&ch,&sc,FALSE)&&!ch&&!sc;}', []),
    ('KeyEmpty();', ['1']),
    ('I64 KI[28],key_echo_count=0,key_echo_ch=0,key_echo_sc=0,key_wait_observed=0,key_producer_done=0;', []),
    ('Bool CaptureKey(I64 ch,I64 sc){key_echo_count++;key_echo_ch=ch;key_echo_sc=sc;return TRUE;}', []),
    ('U0 KeyScan(I64 slot,Bool echo=FALSE){I64 ch=99,sc=99;KI[slot]=ScanKey(&ch,&sc,echo);KI[slot+1]=ch;KI[slot+2]=sc;}', []),
    ('U0 KeyRead(I64 slot,Bool echo=FALSE){I64 sc=99;KI[slot]=GetKey(&sc,echo);KI[slot+1]=sc;}', []),
    ('U0 KeyEcho(I64 slot){KI[slot]=key_echo_count;KI[slot+1]=key_echo_ch;KI[slot+2]=key_echo_sc;}', []),
    ('U8 *key_hook;Bool key_old_desc,key_old_silent,key_old_idle,key_old_await;', []),
    ('U0 KeySetup(){key_old_desc=LBtr(&Fs->win_inhibit,12);key_old_silent=LBtr(&Fs->display_flags,DISPLAYf_SILENT);key_old_idle=LBtr(&Fs->task_flags,TASKf_IDLE);key_old_await=LBtr(&Fs->task_flags,TASKf_AWAITING_MSG);FlushMsgs;}', []),
    ('KeySetup;KeyScan(0);', []),
    ('U0 KeyFiltered(){FlushMsgs;PostMsg(Fs,MSG_KEY_UP,117,0x9E);PostMsg(Fs,MSG_MS_MOVE,7,8);PostMsg(Fs,MSG_KEY_DOWN,97,0x1E);KeyScan(3);KI[6]=ScanMsg(NULL,NULL,~1);}', []), ('KeyFiltered;', []),
    ('U0 KeyZero(){PostMsg(Fs,MSG_KEY_DOWN,0,0x4B);KI[7]=ScanKey(NULL,NULL);}', []), ('KeyZero;', []),
    ('PostMsg(Fs,MSG_KEY_DOWN,0,0x48);KeyRead(8);', []),
    ('U0 KeyHook(){key_hook=KeyDevAdd(&CaptureKey,NULL,10,TRUE);}', []), ('KeyHook;', []),
    ('PostMsg(Fs,MSG_KEY_DOWN,98,0x30);KeyRead(10,TRUE);KeyEcho(12);', []),
    ('PostMsg(Fs,MSG_KEY_DOWN,99,0x8000002E);KeyScan(15,TRUE);KeyEcho(18);', []),
    ('U0 KeyFilter(){LBts(&Fs->win_inhibit,12);PostMsg(Fs,MSG_KEY_DOWN,120,0x8000002D);PostMsg(Fs,MSG_KEY_DOWN,100,0x20);KeyScan(21);KI[24]=ScanKey(NULL,NULL);}', []), ('KeyFilter;', []),
    ('U0 KeyProducer(U8 *data){CTask *t=data;I64 mask=1<<TASKf_IDLE|1<<TASKf_AWAITING_MSG;while((t->task_flags&mask)!=mask)Yield;key_wait_observed=1;PostMsg(t,MSG_KEY_DOWN,101,0x12);key_producer_done=1;}', []),
    ('U0 KeyWait(){CTask *t;LBtr(&Fs->task_flags,TASKf_IDLE);LBtr(&Fs->task_flags,TASKf_AWAITING_MSG);t=Spawn(&KeyProducer,Fs,"Key producer",-1,Fs,8192);KeyRead(25);while(!key_producer_done||TaskValidate(t))Yield;}', []),
    ('U0 KeyFinish(){KI[27]=key_wait_observed&&!Bt(&Fs->task_flags,TASKf_IDLE);KeyDevRem(key_hook);LBEqu(&Fs->win_inhibit,12,key_old_desc);LBEqu(&Fs->display_flags,DISPLAYf_SILENT,key_old_silent);}', []),
    ('U0 KeyRestore(){LBEqu(&Fs->task_flags,TASKf_IDLE,key_old_idle);LBEqu(&Fs->task_flags,TASKf_AWAITING_MSG,key_old_await);}', []),
    ('KeyWait;KeyFinish;KeyRestore;', []),
    ('FileWrite("C:/KeyInput.DATA",KI,sizeof(KI))>0;', ['1']), ('6*7;', ['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
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
    report = dict(result='running', scope='28-field original ScanKey/GetKey message, echo callback, descriptor and delayed-wait oracle; physical keyboard, raw cursor, debugger polling and default document echo remain open',
                  input_sha256=pins, commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejection_prefixes':('INPUT REJECT ',),
                           'command_timeout':120})
        import struct
        expected = runpy.run_path(str(reference))['EXPECTED']
        data = runpy.run_path(str(builder))['mutated_file_contents'](working, {'/KeyInput.DATA'})['/KeyInput.DATA']
        report['observed'] = list(struct.unpack('<28q',data))
        if data != struct.pack('<28q',*expected):
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
