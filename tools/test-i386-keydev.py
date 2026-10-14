#!/usr/bin/env python3
"""Check original output-hook dispatch through native public interfaces."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = [321,2,33511,0,0,321321,0,0,4,21,6,2]
COMMANDS = [
    ('I64 trace=0,KD[12];CKeyDevEntry *KD_A,*KD_B,*KD_C,*KD_D;Bool KD_old_silent;', []),
    ('Bool KeyA(I64 ch,I64 sc){trace=trace*10+1;return TRUE;}', []),
    ('Bool KeyB(I64 ch,I64 sc){trace=trace*10+2;return sc&SCF_KEY_DESC;}', []),
    ('Bool KeyC(I64 ch,I64 sc){trace=trace*10+3;return FALSE;}', []),
    ('Bool KeyD(I64 ch,I64 sc){trace=trace*10+4;return TRUE;}', []),
    ('Bool StringB(U8 *s){trace=trace*10+5;return FALSE;}', []),
    ('Bool StringD(U8 *s){trace=trace*10+6;return TRUE;}', []),
    ('U0 KDSetup(){KD_old_silent=LBtr(&Fs->display_flags,DISPLAYf_SILENT);KD_A=KeyDevAdd(&KeyA,NULL,30,FALSE);KD_B=KeyDevAdd(&KeyB,&StringB,20,TRUE);KD_C=KeyDevAdd(&KeyC,NULL,10,FALSE);}', []), ('KDSetup;', []),
    ('U0 KDKeys(){trace=0;PutKey(97,0);KD[0]=trace;trace=0;PutKey(99,SCF_KEY_DESC|0x2E);KD[1]=trace;trace=0;PutS("ab");KD[2]=trace;}', []), ('KDKeys;', []),
    ('U0 KDSilent(){LBts(&Fs->display_flags,DISPLAYf_SILENT);trace=0;PutKey(115,0);KD[3]=trace;trace=0;PutS("ab");KD[4]=trace;LBtr(&Fs->display_flags,DISPLAYf_SILENT);}', []), ('KDSilent;', []),
    ('U0 KDNull(){trace=0;PutChars(0x420041);KD[5]=trace;trace=0;PutKey(0,0);KD[6]=trace;trace=0;PutS(NULL);KD[7]=trace;}', []), ('KDNull;', []),
    ('U0 KDReplace(){KD_D=KeyDevAdd(&KeyD,&StringD,10,FALSE);trace=0;PutKey(100,0);KD[8]=trace;trace=0;PutS("ab");KD[10]=trace;trace=0;PutKey(99,SCF_KEY_DESC|0x2E);KD[11]=trace;}', []), ('KDReplace;', []),
    ('U0 KDFinish(){KeyDevRem(KD_D);trace=0;PutKey(97,0);KD[9]=trace;KeyDevRem(KD_A);KeyDevRem(KD_B);LBEqu(&Fs->display_flags,DISPLAYf_SILENT,KD_old_silent);}', []), ('KDFinish;', []),
    ('FileWrite("C:/KeyDev.DATA",KD,sizeof(KD))>0;', ['1']), ('6*7;', ['42'])]


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
    reference = ROOT/'tools/test-i386-keydev-reference.py'
    builder = ROOT/'tools/build-i386-kernel.py'
    pins = {str(p):sha(p) for p in [source, runner, reference, builder, Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='Public native output-hook ordering, descriptor/silent filters, PutS fallback, packed characters and replacement/removal; default document/raw output, scroll waiting and callback lifetime remain open',
                  input_sha256=pins, commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejection_prefixes':('INPUT REJECT ',),
                           'command_timeout':120})
        import struct
        expected = EXPECTED
        data = runpy.run_path(str(builder))['mutated_file_contents'](working, {'/KeyDev.DATA'})['/KeyDev.DATA']
        report['observed'] = list(struct.unpack('<12q',data))
        if data != struct.pack('<12q',*expected):
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
