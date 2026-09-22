#!/usr/bin/env python3
"""Acceptance test for a persistent native DolDoc edit and reopen session."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT=Path(__file__).resolve().parents[1]
INPUT=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path,nargs='?',default=ROOT/'build/i386-kernel/kernel.img')
    parser.add_argument('--out',type=Path,default=ROOT/'build/i386-doldoc-session')
    args=parser.parse_args()
    args.out.mkdir(parents=True,exist_ok=True)
    candidate=args.out/'session.img'
    shutil.copyfile(args.disk,candidate)
    source_hash=hashlib.sha256(args.disk.read_bytes()).hexdigest()
    result={'result':'incomplete','source_disk_sha256':source_hash,'candidate':str(candidate)}
    (args.out/'result.json').unlink(missing_ok=True)
    try:
        create={
          'status':'ok','answers':[],
          'commands':[
            ('CDoc *edit_doc=DocNew("C:/NativeEdit.DD",Fs);',[]),
            ('edit_doc!=0&&edit_doc->doc_signature==DOC_SIGNATURE_VAL;',['1']),
            ('DocEd(edit_doc);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeEdit.DD','',
                              bytes([0xDB]).decode('cp437')],
              'events':[{'text':'abc'},{'key':'left'},{'key':'left'},
                        {'text':'X'},{'key':'backspace'},{'text':'Z'}],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeEdit.DD','',
                            'aZ'+bytes([0xDB]).decode('cp437')+'bc'],
            }),
            ("I64 edit_size;U8 *edit_text=DocSave(edit_doc,&edit_size);edit_text[0]=='a'&&edit_text[1]=='Z'&&edit_text[2]==5&&edit_text[3]=='b'&&edit_text[4]=='c'&&edit_text[5]==0;",['1']),
            ('Free(edit_text);DocWrite(edit_doc);',['1']),
          ],
          'command_timeout':60,
        }
        result['create_edit_save']=INPUT(candidate,args.out/'create-edit-save',startup_check=create,snapshot=False)
        reopen={
          'status':'ok','answers':[],
          'commands':[
            ('CDoc *saved_doc=DocRead("C:/NativeEdit.DD");',[]),
            ('saved_doc!=0;',['1']),
            ('DocEd(saved_doc);',['1'],{
              'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
              'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeEdit.DD','',
                              'aZ'+bytes([0xDB]).decode('cp437')+'bc'],
              'events':[],
              'final_rows':['TempleOS i386','DolDoc editor','C:/NativeEdit.DD','',
                            'aZ'+bytes([0xDB]).decode('cp437')+'bc'],
            }),
            ("I64 saved_size;U8 *saved_text=DocSave(saved_doc,&saved_size);saved_text[0]=='a'&&saved_text[1]=='Z'&&saved_text[2]==5&&saved_text[3]=='b'&&saved_text[4]=='c'&&saved_text[5]==0;",['1']),
            ('saved_size==5;',['1']),
            ('Free(saved_text);DocDel(saved_doc);',[]),
          ],
          'command_timeout':60,
        }
        result['reopen_after_boot']=INPUT(candidate,args.out/'reopen',startup_check=reopen,snapshot=False)
        result['result']='pass'
    except Exception as exc:
        result['failure']=f'{type(exc).__name__}: {exc}'
        for phase in ('create-edit-save','reopen'):
            checkpoint=args.out/phase/'checkpoint.json'
            debug=args.out/phase/'debug.log'
            if checkpoint.exists():
                result['failure_phase']=phase
                result['failure_checkpoint']=json.loads(checkpoint.read_text())
                if debug.exists() and 'COMMAND ERROR\n' in debug.read_text():
                    result['failure_kind']='guest command rejected'
    finally:
        result['source_disk_unchanged']=hashlib.sha256(args.disk.read_bytes()).hexdigest()==source_hash
        if not result['source_disk_unchanged']:
            result['result']='fail'
            result['failure']='Source disk changed during acceptance'
        result['candidate_sha256']=hashlib.sha256(candidate.read_bytes()).hexdigest()
        (args.out/'result.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))
    return 0 if result['result']=='pass' else 1


if __name__=='__main__': raise SystemExit(main())
