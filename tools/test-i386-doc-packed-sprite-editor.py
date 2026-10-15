#!/usr/bin/env python3
"""Check packed original sprite binary save/reload and editor presentation."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('#include "/Adam/Gr/Gr.HH"', []),
    ('CDoc *cp_doc;', []),
    ('U0 CPRect(U8 *s){CSpritePtPt *r=s;r->type=SPT_RECT;r->x1=-4;r->y1=2;r->x2=8;r->y2=6;}', []),
    ('U8 *CPData(){U8 *s=CAlloc(sizeof(CSpriteColor)+sizeof(CSpritePtPt)+1);CSpriteColor *c=s;c->type=SPT_COLOR;c->color=BLUE;CPRect(s+sizeof(CSpriteColor));return s;}', []),
    ('CDocBin *CPBin(){CDocBin *b=CAlloc(sizeof(CDocBin));b->num=1;b->size=sizeof(CSpriteColor)+sizeof(CSpritePtPt)+1;b->use_cnt=1;b->data=CPData;QueIns(b,cp_doc->bin_head.last);return b;}', []),
    ('U0 CPSprite(){CDocEntry *e=CAlloc(sizeof(CDocEntry));e->type=DOCT_SPRITE;e->de_flags=DOCEF_TAG|DOCEF_HAS_BIN;e->tag=StrNew("");e->bin_num=1;e->bin_data=CPBin;DocInsEntry(cp_doc,e);}', []),
    ('U0 CPSetup(){cp_doc=DocNew("C:/PackedSprite.DD");cp_doc->flags|=DOCF_NO_CURSOR;DocPrint(cp_doc,"A");}', []),
    ('I64 CPReady(){CPSetup;CPSprite;if(!DocWrite(cp_doc))return 0;DocDel(cp_doc);cp_doc=DocRead("C:/PackedSprite.DD");if(!cp_doc)return 0;cp_doc->flags|=DOCF_NO_CURSOR;return cp_doc->bin_head.next->size==20;}', []),
    ('CPReady;', ['1']),
]

EDITOR_ROWS=['TempleOS i386','DolDoc editor','C:/PackedSprite.DD','','A']
SPRITE_PIXELS={(x,y+32):1 for y in range(2,7) for x in range(4,17)}
COMMANDS.append(('DocEd(cp_doc);',['1'],{
    'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
    'initial_rows':EDITOR_ROWS,'initial_pixels':SPRITE_PIXELS,
    'events':[],'final_rows':EDITOR_ROWS,'final_pixels':SPRITE_PIXELS}))
COMMANDS += [('DocDel(cp_doc);',[]),('6*7;',['42'])]


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
    parser.add_argument('--mouse',action='store_true',
                        help='Check physical pointer XOR and clean sprite backing after movement')
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    if args.mouse:
        for index,spec in enumerate(commands):
            if spec[0]=='DocEd(cp_doc);':
                interaction=dict(spec[2])
                interaction['events']=[
                    {'mouse_to':[12,36]},
                    {'expect_rows':EDITOR_ROWS,'pixels':SPRITE_PIXELS,
                     'pointer':[12,36],'label':'pointer-over-packed-rectangle'},
                    {'mouse_to':[100,60]},
                    {'expect_rows':EDITOR_ROWS,'pixels':SPRITE_PIXELS,
                     'pointer':[100,60],'label':'clean-rectangle-after-pointer-move'},
                    {'mouse_to':[12,36]},
                ]
                interaction['final_pointer']=[12,36]
                commands[index]=(spec[0],spec[1],interaction)
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, ROOT/'Kernel/FontStd.HC', Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='Original packed 20-byte color/rectangle/end saved and reloaded, then full-frame editor pixels including inclusive rectangle edges; not arbitrary sprites, editing gestures or full desktop parity',
                  input_sha256=pins, commands=serializable(commands), ram_mib=args.ram_mib,
                  mouse=args.mouse)
    if args.mouse:
        report['scope']+='; physical pointer over blue rectangle, movement restores clean backing'
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
