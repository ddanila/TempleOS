#!/usr/bin/env python3
"""Require automatic persistent graphics and final-hook layering on a plain terminal."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('CDoc *pg_doc;I64 pg_attr,pg_pixel;U0 (*pg_old_final)(CDC *dc);', []),
    ('U0 PGLog(U8 *s){while(*s)OutU8(0xE9,*s++);}', []),
    ('U0 PGFinal(CDC *dc){dc->body[51280]=2;}', []),
    ('U0 PGSetup(){pg_doc=DocPut;pg_attr=Fs->text_attr;pg_pixel=gr.dc->body[51280];pg_old_final=gr.fp_final_scrn_update;DocRst(pg_doc,TRUE);pg_doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;DocPrint(pg_doc,"Plain\\n");gr.dc->body[51280]=4;}', []),
    ('U0 PGWait(U8 *s){Refresh(2);PGLog(s);GetKey;}', []),
    ('U0 PGSecond(){gr.dc->body[51280]=1;gr.fp_final_scrn_update=&PGFinal;}', []),
    ('U0 PGThird(){gr.fp_final_scrn_update=NULL;}', []),
    ('U0 PGClear(){gr.dc->body[51280]=TRANSPARENT;}', []),
    ('U0 PGFinish(){gr.dc->body[51280]=pg_pixel;gr.fp_final_scrn_update=pg_old_final;DocRst(pg_doc,TRUE);pg_doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;Fs->text_attr=pg_attr;DocPrint(pg_doc,"TempleOS i386\\nHolyC console\\n\\n");}', []),
    ('I64 PGView(){PGSetup;PGWait("PG A\\n");PGSecond;PGWait("PG B\\n");PGThird;PGWait("PG C\\n");PGClear;PGWait("PG D\\n");PGFinish;PGLog("PG end\\n");return 1;}', []),
]
COMMANDS.append(('PGView;',['1'],{
    'begin':'PG A\n','initial_rows':['Plain'],'initial_pixels':{(80,80):4},
    'events':[{'key':'spc'},{'wait_log':'PG B\n'},
              {'expect_rows':['Plain'],'pixels':{(80,80):2},'label':'final-hook'},
              {'key':'spc'},{'wait_log':'PG C\n'},
              {'expect_rows':['Plain'],'pixels':{(80,80):1},'label':'persistent-restored'},
              {'key':'spc'},{'wait_log':'PG D\n'}],
    'final_rows':['Plain'],'preserve_history':False,
    'return_rows':['TempleOS i386','HolyC console','','1','> '],
    'exit_key':'esc','end':'PG end\n'}))
COMMANDS.append(('6*7;',['42']))

if any(len(c[0])>255 for c in COMMANDS):
    raise ValueError("Put/display fixture exceeds native input limit")


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
    report = dict(result='running', scope='Persistent direct-body pixel admitted with plain existing put/display document; final hook overlays and removal reveals retained pixel, clearing returns plain document, then continued command input; not all graphics/input roles',
                  input_sha256=pins, commands=serializable(commands), ram_mib=args.ram_mib)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=args.ram_mib,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'pause_window_manager':False,
                           'rejection_prefixes':('INPUT REJECT ',),
                           # Original DOCT_PMT renders command input green.
                           'command_styles':{11:{
                               'typing_colors':{(4,x):2 for x in range(2,6)},
                               'return_colors':{**{(4,x):2 for x in range(2,6)},
                                                (5,0):2,(5,1):2,(6,0):2}}},
                           'command_timeout':30})
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
