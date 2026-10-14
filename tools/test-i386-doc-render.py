#!/usr/bin/env python3
"""Check native public DocRecalc screen-cell output against the original."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('I64 DR[10],dr_attr;CDoc *dr_doc,*dr_display;', []),
    ('U0 DRSetup(){dr_attr=Fs->text_attr;dr_display=Fs->display_doc;dr_doc=DocNew("Render.DD");Fs->text_attr=0xF0;Fs->display_doc=dr_doc;dr_doc->flags|=DOCF_NO_SCROLL_BARS|DOCF_DO_FULL_REFRESH;}', []),
    ('U0 DRPrint(){DocPrint(dr_doc,"A\\x24FG,RED\\x24B\\x24FG\\x24C\\tD\\nE");}', []),
    ('U0 DRDraw(){DR[0]=DocRecalc(dr_doc,RECALCt_TO_SCRN);}', []),
    ('U0 DRCells(){I64 at=Fs->win_top*80+Fs->win_left;DR[1]=gr.text_base[at]&65535;DR[2]=gr.text_base[at+1]&65535;DR[3]=gr.text_base[at+2]&65535;DR[4]=gr.text_base[at+8]&65535;DR[5]=gr.text_base[at+80]&65535;}', []),
    ('U0 DRState(){DR[6]=dr_doc->max_x>=8;DR[7]=dr_doc->max_y>=1;DR[8]=!dr_doc->owning_task&&!Bt(&dr_doc->locked_flags,DOClf_LOCKED);DR[9]=DocRecalc(NULL);}', []),
    ('U0 DRFinish(){Fs->display_doc=dr_display;Fs->text_attr=dr_attr;DocDel(dr_doc);}', []),
    ('DRSetup;DRPrint;DRDraw;DRCells;DRState;DRFinish;', []),
    ('FileWrite("C:/DocRender.DATA",DR,sizeof(DR))>0;', ['1']),
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
    reference = ROOT/'tools/test-i386-doc-render-reference.py'
    builder = ROOT/'tools/build-i386-kernel.py'
    pins = {str(p):sha(p) for p in [source, runner, reference, builder, Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='10-field original DocRecalc text-cell foreground/reset, tab/newline layout, extents, unlock and null-document oracle; not presentation, sprites, cursor or whole renderer parity',
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
        data = runpy.run_path(str(builder))['mutated_file_contents'](working, {'/DocRender.DATA'})['/DocRender.DATA']
        report['observed'] = list(struct.unpack('<10q',data))
        if data != struct.pack('<10q',*expected):
            raise ValueError('Native document rendering differs from original byte oracle')
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
