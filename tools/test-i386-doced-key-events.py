#!/usr/bin/env python3
"""Exercise physical vertical editor navigation through QEMU key events."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT=Path(__file__).resolve().parents[1]

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--ram-mib',type=int,choices=(8,64),default=64)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    source,out=args.disk.resolve(),args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    files=[source,Path(__file__).resolve(),ROOT/'tools/i386-kernel-input.py',ROOT/'Kernel/FontStd.HC']
    pins={str(p):sha(p) for p in files};out.mkdir(parents=True)
    disk=out/'working.img';shutil.copyfile(source,disk)
    cursor=bytes([0xDB]).decode('cp437')
    commands=[('CDoc *vert_doc=DocNew("C:/NativeVertical.DD",Fs);',[]),
      ('DocEd(vert_doc);',['1'],{
        'begin':'DOC EDIT begin\n','end':'DOC EDIT end\n',
        'initial_rows':['TempleOS i386','DolDoc editor','C:/NativeVertical.DD','',cursor],
        'events':[{'text':'abcde'},{'key':'ret'},{'text':'xy'},
                  {'key':'ret'},{'text':'12345'},{'key':'home'},
                  {'key':'right'},{'key':'right'},{'key':'down'},
                  {'key':'down'},{'key':'up'},{'key':'up'},{'key':'down'}],
        'final_rows':['TempleOS i386','DolDoc editor','C:/NativeVertical.DD','',
                      'abcde','xy'+cursor,'12345']}),
      ("I64 vert_size;U8 *vert_text=DocSave(vert_doc,&vert_size);vert_size==15&&vert_text[5]==10&&vert_text[8]==5&&vert_text[9]==10;",['1']),
      ('Free(vert_text);DocDel(vert_doc);',[]),('6*7;',['42'])]
    report=dict(result='running',scope='Physical QEMU key down/up editor navigation and serialized cursor; not full editor qualification',input_sha256=pins)
    try:
        report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](
          disk,out/'qemu',snapshot=False,ram_mib=args.ram_mib,cpu='486,-fpu',accel='tcg',qmp_stdio=True,welcome=True,
          startup_check={'status':'ok','answers':[],'commands':commands,'command_timeout':120})
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==digest for p,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
