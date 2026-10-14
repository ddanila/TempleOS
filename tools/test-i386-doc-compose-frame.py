#!/usr/bin/env python3
"""Check previous-cell/current-sprite composition and single dynamic evaluation per frame."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('#include "/Adam/Gr/Gr.HH"', []),
    ('U0 CPRect(U8 *s){CSpritePtPt *r=s;r->type=SPT_RECT;r->x1=-4;r->y1=2;r->x2=8;r->y2=6;}', []),
    ('CDoc *cp_doc,*cp_display;I64 cp_count=0,cp_attr;', []),
    ('U0 CPLog(U8 *s){while(*s)OutU8(0xE9,*s++);}', []),
    ('U8 *CPTag(CDoc *d,CDocEntry *e,CTask *t){U8 s[2];s[0]=64+(++cp_count);s[1]=0;return StrNew(s,t);}', []),
    ('U0 CPText(){CDocEntry *e=CAlloc(sizeof(CDocEntry));e->type=DOCT_TEXT;e->de_flags=DOCEF_TAG|DOCEF_TAG_CB;e->tag=StrNew("");e->tag_cb=&CPTag;DocInsEntry(cp_doc,e);}', []),
    ('U8 *CPData(){U8 *s=CAlloc(sizeof(CSpriteColor)+sizeof(CSpritePtPt)+1);CSpriteColor *c=s;c->type=SPT_COLOR;c->color=BLUE;CPRect(s+sizeof(CSpriteColor));return s;}', []),
    ('CDocBin *CPBin(){CDocBin *b=CAlloc(sizeof(CDocBin));b->num=1;b->size=sizeof(CSpriteColor)+sizeof(CSpritePtPt)+1;b->use_cnt=1;b->data=CPData;QueIns(b,cp_doc->bin_head.last);return b;}', []),
    ('U0 CPSprite(){CDocEntry *e=CAlloc(sizeof(CDocEntry));e->type=DOCT_SPRITE;e->de_flags=DOCEF_TAG|DOCEF_HAS_BIN;e->tag=StrNew("");e->bin_num=1;e->bin_data=CPBin;DocInsEntry(cp_doc,e);}', []),
    ('U0 CPSetup(){I64 i;cp_attr=Fs->text_attr;cp_display=Fs->display_doc;cp_doc=DocNew("Compose.DD");Fs->text_attr=0xF0;Fs->display_doc=cp_doc;cp_doc->flags|=DOCF_NO_SCROLL_BARS;for(i=0;i<4800;i++)gr.text_base[i]=0xF020;gr.text_base[0]=0xF050;}', []),
    ('U0 CPDraw(CDC *dc){cp_doc->flags|=DOCF_DO_FULL_REFRESH;DocRecalc(cp_doc,RECALCt_TO_SCRN);}', []),
    ("U0 CPFrame(){if(sizeof(CSpriteColor)!=2||sizeof(CSpritePtPt)!=17)throw('Sprite');if(!NativeGraphicsPresent(&CPDraw))throw('Frame');}", []),
    ('U0 CPFinish(){Fs->display_doc=cp_display;Fs->text_attr=cp_attr;DocDel(cp_doc);NativeTextBaseRestore;}', []),
    ('I64 CPView(){I64 ok;CPSetup;CPText;CPSprite;CPFrame;CPLog("DOC COMPOSE first\\n");GetKey;CPFrame;CPLog("DOC COMPOSE second\\n");GetKey;ok=cp_count==2&&(gr.text_base[0]&255)==66;CPFinish;CPLog("DOC COMPOSE end\\n");return ok;}', []),
]

SPRITE_PIXELS = {(x,y):1 for y in range(2,7) for x in range(4,17)}
COMMANDS.append(('CPView;',['1'],{
    'begin':'DOC COMPOSE first\n','initial_rows':['P'],'initial_pixels':SPRITE_PIXELS,
    'events':[{'key':'spc'},{'wait_log':'DOC COMPOSE second\n'}],
    'final_rows':['A'],'final_pixels':SPRITE_PIXELS,
    'preserve_history':True,'exit_key':'esc','end':'DOC COMPOSE end\n'}))
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
    report = dict(result='running', scope='Two full-frame pixel checks: text P then A from previous cells, current document sprite rectangle above text, callback exactly once per frame and next cells B; not all sprites, focus, animation or automatic stdout rendering',
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
