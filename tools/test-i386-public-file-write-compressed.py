#!/usr/bin/env python3
"""FileWrite .Z inference must produce an archive usable by native #include."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct

ROOT=Path(__file__).resolve().parents[1]
NAME='/Probe/PublicCompressed.HC.Z'
BODY='I64 CompressedAnswer(){return 42;}'
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
    commands=[(f'FileWrite("C:{NAME}",{json.dumps(BODY)},{len(BODY)},{DATE})>0;',['1']),
              (f'#include "C:{NAME}"',[]),('CompressedAnswer;',['42']),('6*7;',['42'])]
    report=dict(result='fail',source_disk_sha256=hashlib.sha256(original).hexdigest(),
                scope='Filename-inferred .Z write, native include/execution and independent archive header/metadata; not complete compression/resident parity')
    try:
        runner=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        report['behavior']=runner(candidate,out/'behavior',snapshot=False,cpu='486,-fpu',qmp_stdio=True,
            startup_check={'status':'ok','answers':[],'commands':commands})
        find=runpy.run_path(str(ROOT/'tools/test-i386-public-file-write.py'))['find_record']
        entry=find(candidate,NAME)
        if not entry or entry['date']!=DATE or entry['attr']!=0xC00:
            raise ValueError('Compressed file metadata differs')
        image=candidate.read_bytes();archive=image[entry['block']*512:entry['block']*512+entry['bytes']]
        if len(archive)<17:raise ValueError('Missing archive header')
        stored,expanded,kind=struct.unpack_from('<qqB',archive)
        if stored!=len(archive) or expanded!=len(BODY) or kind!=2:
            raise ValueError('Compressed archive size/type differs')
        build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        report['filesystem']=build['verify_mutated_volume'](candidate)
        report.update(result='pass',entry=entry,archive_type=kind)
    except Exception as error:
        report['error']=str(error);raise
    finally:
        report['source_disk_unchanged']=args.disk.read_bytes()==original
        if not report['source_disk_unchanged']:report.update(result='fail',error='Source changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':main()
