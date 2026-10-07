#!/usr/bin/env python3
"""Capture original macro form construction and popup ownership independently."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
SOURCE=r'''U0 MMReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
CTask *mm_owner=Fs;U8 *mm_entry,mm_saved[5],*mm_text;I64 mm_size,mm_calls,mm_mask;Bool mm_state;
U0 MMRestore(){I64 i;for(i=0;i<5;i++)mm_entry[i]=mm_saved[i];}
I64 MMHook(CDoc *d,I64 flags=0){
 U8 *text,*line;I64 size,fields=0;CDocEntry *e;
 mm_calls++;mm_mask=0;if(sys_macro_task==Fs)mm_mask|=1;if(mm_owner->popup_task==Fs)mm_mask|=2;
 if(d->flags&DOCF_FORM)mm_mask|=4;if(d->flags&DOCF_SIZE_MIN)mm_mask|=8;if(!flags)mm_mask|=16;mm_state=mm_mask==31;
 for(e=d->head.next;e!=d;e=e->next)if(e->type_u8==DOCT_DATA){fields++;line=MStrPrint("FIELD %s | %s | type %d flags %X len %d\n",e->tag,e->aux_str,e->raw_type,e->de_flags,e->len);MMReport(line);Free(line);}
 if(fields!=2)mm_state=FALSE;
 text=DocSave(d,&size);mm_text=MAlloc(size,mm_owner);MemCpy(mm_text,text,size);mm_size=size;Free(text);
 return 2;
}
U0 MMRun(){
 I64 i,res,d;U8 *line;
 mm_calls=0;mm_mask=0;mm_state=FALSE;mm_text=NULL;mm_size=0;
 mm_entry=&DocMenu;for(i=0;i<5;i++)mm_saved[i]=mm_entry[i];
 d=(&MMHook+0)(I64)-(mm_entry+0)(I64)-5;
 if(d<-0x80000000||d>0x7FFFFFFF){MMReport("FAIL hook range\n");return;}
 mm_entry[0]=0xE9;(mm_entry+1)(I32 *)[0]=d;
 try{res=PopUpMacroMenu;}catch{MMRestore;throw;}
 MMRestore;
 line=MStrPrint("OBS menu res %d calls %d mask %d macro %X popup %X\n",res,mm_calls,mm_mask,sys_macro_task,mm_owner->popup_task);MMReport(line);Free(line);
 if(res!=2||mm_calls!=1||!mm_state||sys_macro_task||mm_owner->popup_task){MMReport("FAIL original macro popup ownership\n");return;}
 for(i=0;i<5;i++)if(mm_entry[i]!=mm_saved[i]){MMReport("FAIL menu entry restore\n");return;}
 line=MStrPrint("EXPORT OriginalMacroMenu.DD %X %X\n",mm_text,mm_size);MMReport(line);Free(line);
 MMReport("PASS original macro form construction and ownership\n");
}
MMReport("START original macro menu\n");MMRun;
MMReport("DONE original macro menu\n");
'''


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args();out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    overlay=out/'overlay';overlay.mkdir(parents=True)
    (overlay/'Once.HC').write_text(SOURCE)
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in [Path(__file__).resolve(),ROOT/'Adam/DolDoc/DocMacro.HC',ROOT/'Adam/DolDoc/DocForm.HC',ROOT/'Adam/DolDoc/DocMenuCore.HC',ROOT/'Adam/DolDoc/DocFormDataCore.HC',ROOT/'Adam/DolDoc/DocPlain.HC',ROOT/'Adam/DolDoc/DocPutS.HC',ROOT/'Adam/DolDoc/DocPutSCore.HC',ROOT/'Adam/DolDoc/DocDollarServices.HH',ROOT/'Adam/DolDoc/DocDollarFlagsCore.HC',ROOT/'Adam/DolDoc/DocDollarParseCore.HC',ROOT/'Compiler/LexLib.HC',ROOT/'Compiler/PrsExp.HC',ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py']}
    report={'result':'running','input_sha256':pins,'scope':'Original PopUpMacroMenu executed with DocMenu entry interposed to capture actual form and popup handoff/cleanup; chooser interaction bypassed, not UI or port qualification'}
    try:
        iso=out/'original.iso'
        subprocess.run([sys.executable,'tools/build-iso.py','--overlay','build/rebuild-test/overlay','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'original'),'--timeout','90','--qmp-stdio'],cwd=ROOT,check=True)
        log=(out/'original/debug.log').read_text()
        if 'PASS original macro form construction and ownership\n' not in log:
            raise ValueError('Missing original macro menu verdict')
        report['result']='pass'
    except Exception as e:
        report.update(result='fail',error=str(e));raise
    finally:
        changed=[p for p,h in pins.items() if sha(Path(p))!=h]
        if changed:report.update(result='fail',error='Oracle inputs changed',changed_inputs=changed)
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise RuntimeError(report['error'])


if __name__=='__main__':main()
