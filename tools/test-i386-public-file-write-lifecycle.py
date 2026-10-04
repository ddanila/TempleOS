#!/usr/bin/env python3
"""FileWrite replacement, empty/negative size and invalid-parent persistence."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy

ROOT=Path(__file__).resolve().parents[1]
DATE=0x1122334455667788


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    out=args.out.resolve();out.mkdir(parents=True,exist_ok=True)
    candidate=out/'candidate.img'
    if candidate==args.disk.resolve():parser.error('output overlaps source')
    original=args.disk.read_bytes();candidate.write_bytes(original)
    (out/'result.json').unlink(missing_ok=True)
    commands=[
        ('U8 WriteBytes[4]={65,0,66,255};I64 WriteBlock=0;',[]),
        ('U0 WriteReport(I64 v){U8 *s="FILEWRITE BLOCK ",*digits="0123456789ABCDEF";I64 i;while(*s)OutU8(0xE9,*s++);for(i=60;i>=0;i-=4)OutU8(0xE9,digits[(v>>i)&15]);OutU8(0xE9,10);}',[]),
        (f'FileWrite("C:/Probe/WriteReplace.BIN","OLD",3,{DATE},0x800)>0;',['1']),
        (f'Bool WriteReplace(){{WriteBlock=FileWrite("C:/Probe/WriteReplace.BIN",WriteBytes,4,{DATE+1},0x800);return WriteBlock>0;}}',[]),
        ('WriteReplace;WriteReport(WriteBlock);',['1']),
        (f'FileWrite("C:/Probe/WriteEmpty.BIN",0,0,{DATE},0x800)==-1;',['1']),
        (f'FileWrite("C:/Probe/WriteNegative.BIN",0,-1,{DATE},0x800)==-1;',['1']),
        (f'FileWrite("C:/MissingWriteParent/Bad.BIN",WriteBytes,4,{DATE},0x800)==0;',['1']),
        ('6*7;',['42'])]
    report=dict(result='fail',source_disk_sha256=hashlib.sha256(original).hexdigest(),
                scope='Explicit-date contiguous FileWrite replacement/empty/negative/invalid-parent semantics and persisted bytes; not default date, compression/resident or exhaustive failures')
    try:
        runner=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        report['behavior']=runner(candidate,out/'behavior',snapshot=False,cpu='486,-fpu',qmp_stdio=True,
            startup_check={'status':'ok','answers':[],'commands':commands})
        build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        report['filesystem']=build['verify_mutated_volume'](candidate)
        paths={'/Probe/WriteReplace.BIN','/Probe/WriteEmpty.BIN','/Probe/WriteNegative.BIN','/MissingWriteParent/Bad.BIN'}
        payloads=build['mutated_file_contents'](candidate,paths)
        if payloads!={'/Probe/WriteReplace.BIN':b'A\0B\xff','/Probe/WriteEmpty.BIN':b'','/Probe/WriteNegative.BIN':b''}:
            raise ValueError('Persisted lifecycle files differ')
        find=runpy.run_path(str(ROOT/'tools/test-i386-public-file-write.py'))['find_record']
        entries={path:find(candidate,path) for path in payloads}
        blocks=re.findall(r'^FILEWRITE BLOCK ([0-9A-F]{16})$',(out/'behavior/debug.log').read_text(),re.M)
        if len(blocks)!=1 or int(blocks[0],16)!=entries['/Probe/WriteReplace.BIN']['block']:
            raise ValueError('Replacement return is not its persisted cluster')
        for path,entry in entries.items():
            expected_date=DATE+1 if path.endswith('WriteReplace.BIN') else DATE
            if entry['date']!=expected_date or entry['attr']!=0x800:
                raise ValueError('Lifecycle metadata differs')
            if not entry['bytes'] and entry['block']:
                raise ValueError('Empty file owns data blocks')
        report.update(result='pass',entries=entries)
    except Exception as error:
        report['error']=str(error);raise
    finally:
        report['source_disk_unchanged']=args.disk.read_bytes()==original
        if not report['source_disk_unchanged']:report.update(result='fail',error='Source changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':main()
