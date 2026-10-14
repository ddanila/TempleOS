#!/usr/bin/env python3
"""Check original document text rendering through QEMU VGA pixels."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('CDoc *rf_doc,*rf_display;I64 rf_attr;', []),
    ('U0 RFLog(U8 *s){while(*s)OutU8(0xE9,*s++);}', []),
    ('U0 RFSetup(){rf_attr=Fs->text_attr;rf_display=Fs->display_doc;rf_doc=DocNew("Render.DD");Fs->text_attr=0xF0;Fs->display_doc=rf_doc;rf_doc->flags|=DOCF_NO_SCROLL_BARS;}', []),
    ('U0 RFText(){DocPrint(rf_doc,"A\\x24FG,RED\\x24B\\x24FG\\x24C\\tD\\nE\\n\\x24UL,1\\x24UL\\x24UL,0\\x24\\n\\x24IV,1\\x24IV\\x24IV,0\\x24\\n\\x24BG,BLUE\\x24BG\\x24BG\\x24\\n\\x24BK,1\\x24BL\\x24BK,0\\x24");}', []),
    ("U0 RFDraw(Bool blink){I64 i;for(i=0;i<4800;i++)gr.text_base[i]=0xF020;rf_doc->flags|=DOCF_DO_FULL_REFRESH;DocRecalc(rf_doc,RECALCt_TO_SCRN);if(!NativeTextBasePresent(blink))throw('Frame');}", []),
    ('U0 RFFinish(){Fs->display_doc=rf_display;Fs->text_attr=rf_attr;DocDel(rf_doc);NativeTextBaseRestore;}', []),
    ('I64 RFView(){RFSetup;RFText;RFDraw(FALSE);RFLog("DOC FRAME first\\n");GetKey;RFDraw(TRUE);RFLog("DOC FRAME blink\\n");GetKey;RFFinish;RFLog("DOC FRAME end\\n");return 1;}', []),
]

FRAME_ROWS = ['ABC     D', 'E', 'UL', 'IV', 'BG', 'BL']
FRAME_COLORS = {(0, 1): 4, (3, 0): 15, (3, 1): 15}
FRAME_BACKGROUNDS = {(3, 0): 0, (3, 1): 0, (4, 0): 1, (4, 1): 1}
FRAME_UNDERLINES = {(2, 0), (2, 1)}
BLINK_COLORS = dict(FRAME_COLORS)
BLINK_COLORS.update({(5,0):15,(5,1):15})
BLINK_BACKGROUNDS = dict(FRAME_BACKGROUNDS)
BLINK_BACKGROUNDS.update({(5,0):0,(5,1):0})
COMMANDS.append(('RFView;',['1'],{
    'begin':'DOC FRAME first\n','initial_rows':FRAME_ROWS,
    'initial_colors':FRAME_COLORS,'initial_backgrounds':FRAME_BACKGROUNDS,
    'initial_underlines':FRAME_UNDERLINES,
    'events':[{'key':'spc'},{'wait_log':'DOC FRAME blink\n'}],
    'final_rows':FRAME_ROWS,'final_colors':BLINK_COLORS,
    'final_backgrounds':BLINK_BACKGROUNDS,'final_underlines':FRAME_UNDERLINES,
    'preserve_history':True,'exit_key':'esc','end':'DOC FRAME end\n'}))
COMMANDS.append(('6*7;',['42']))



def serializable(value):
    if isinstance(value,dict):
        return {str(key):serializable(item) for key,item in value.items()}
    if isinstance(value,(list,tuple)):
        return [serializable(item) for item in value]
    if isinstance(value,set):
        return [serializable(item) for item in sorted(value)]
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--ram-mib',type=int,choices=(8,64),default=64)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, ROOT/'Kernel/FontStd.HC', Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='Full-frame independent font/palette checks of DocRecalc text cells presented through NativeTextBasePresent: foreground/reset, tab/newline, underline, inverse, background and two blink phases; not sprites, cursor, scrolling or default stdout integration',
                  input_sha256=pins, commands=serializable(commands), ram_mib=args.ram_mib)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=args.ram_mib,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejection_prefixes':('INPUT REJECT ',),
                           'command_timeout':120})
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
