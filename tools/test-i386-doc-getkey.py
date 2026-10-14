#!/usr/bin/env python3
"""Check native DocGetKey against original descriptor and filter-exit behavior."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('I64 DG[14],dg_count=0,dg_desc=0,dg_inhibit=0;U8 *dg_hook;Bool dg_old_desc,dg_old_silent;', []),
    ('Bool DGHook(I64 ch,I64 sc){dg_count++;if(sc&SCF_KEY_DESC)dg_desc++;if(Bt(&Fs->win_inhibit,12))dg_inhibit++;return TRUE;}', []),
    ('U0 DGFilter(){CDoc *d=DocPut;CDocEntry *e;for(e=d->head.next;e!=d;e=e->next)e->de_flags|=DOCEF_FILTER_SKIP;d->find_replace->filter_lines=1;}', []),
    ('Bool DGClear(){CDoc *d=DocPut;CDocEntry *e;if(d->find_replace->filter_lines)return FALSE;for(e=d->head.next;e!=d;e=e->next)if(e->de_flags&DOCEF_FILTER_SKIP)return FALSE;return !d->owning_task&&!Bt(&d->locked_flags,DOClf_LOCKED);}', []),
    ('U0 DGSetup(){dg_old_desc=LBts(&Fs->win_inhibit,12);dg_old_silent=LBtr(&Fs->display_flags,DISPLAYf_SILENT);dg_hook=KeyDevAdd(&DGHook,NULL,10,TRUE);FlushMsgs;}', []),
    ('U0 DGFirst(){I64 sc;PostMsg(Fs,MSG_KEY_DOWN,120,SCF_KEY_DESC|0x2D);PostMsg(Fs,MSG_KEY_DOWN,97,0x1E);DG[0]=DocGetKey(&sc);DG[1]=sc;DG[2]=dg_count;DG[3]=dg_desc;DG[4]=dg_inhibit;DG[5]=Bt(&Fs->win_inhibit,12);}', []),
    ('U0 DGZero(){I64 sc;PostMsg(Fs,MSG_KEY_DOWN,98,0x30);DG[6]=DocGetKey;PostMsg(Fs,MSG_KEY_DOWN,0,0x48);DG[7]=DocGetKey(&sc);DG[8]=sc;}', []),
    ('U0 DGEscape(I64 ch,I64 next,I64 slot){DGFilter;PostMsg(Fs,MSG_KEY_DOWN,ch,1);PostMsg(Fs,MSG_KEY_DOWN,next,0x10);DG[slot]=DocGetKey;DG[slot+1]=DGClear;}', []),
    ('U0 DGFinish(){DG[13]=dg_count;KeyDevRem(dg_hook);LBEqu(&Fs->win_inhibit,12,dg_old_desc);LBEqu(&Fs->display_flags,DISPLAYf_SILENT,dg_old_silent);}', []),
    ('DGSetup;DGFirst;DGZero;DGEscape(27,113,9);DGEscape(28,114,11);DGFinish;', []),
    ('FileWrite("C:/DocGetKey.DATA",DG,sizeof(DG))>0;', ['1']),
    ('6*7;', ['42']),
]


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
    reference = ROOT/'tools/test-i386-doc-getkey-reference.py'
    builder = ROOT/'tools/build-i386-kernel.py'
    pins = {str(p):sha(p) for p in [source, runner, reference, builder, Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='14-field original DocGetKey descriptor echo/discard, inhibition restore, queued/zero-character/null-output and filter-exit oracle; default document echo, physical input and GetStr remain open',
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
        data = runpy.run_path(str(builder))['mutated_file_contents'](working, {'/DocGetKey.DATA'})['/DocGetKey.DATA']
        report['observed'] = list(struct.unpack('<14q',data))
        if data != struct.pack('<14q',*expected):
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
