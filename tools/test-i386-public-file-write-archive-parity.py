#!/usr/bin/env python3
"""Compare native FileWrite archives byte-for-byte with original CompressBuf."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

ROOT=Path(__file__).resolve().parents[1]
DATE=0x1122334455667788
# Modes: repeated Q, sixteen ASCII symbols, random seven/eight-bit, repeated FF,
# and sixteen high-bit symbols.
CASES=[('empty',0,0),('single7',1,0),('single8',1,4),('repeat7',65536,0),
       ('dictionary7',65536,1),('dictionary8',65536,5),('fallback7',32768,2),('fallback8',32768,3)]


def payload(size,mode):
    random=0x12345678
    data=bytearray()
    for _ in range(size):
        random=(random*1664525+1013904223)&0xFFFFFFFF
        byte=random>>24
        data.append(81 if mode==0 else 65+(byte&15) if mode==1 else byte&127 if mode==2 else 255 if mode==4 else 128+(byte&15) if mode==5 else byte)
    return bytes(data)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--replace',action='store_true',help='Replace every archive with another fixture before inspection')
    args=parser.parse_args()
    out=args.out.resolve();out.mkdir(parents=True,exist_ok=True)
    candidate=out/'candidate.img'
    if candidate==args.disk.resolve():parser.error('output overlaps source')
    original=args.disk.read_bytes();candidate.write_bytes(original)
    report=dict(result='fail',source_disk_sha256=hashlib.sha256(original).hexdigest(),
                scope='Original archive bytes for empty, one-byte, repetition, dictionary growth and incompressible seven/eight-bit input; not complete file API parity')
    (out/'result.json').unlink(missing_ok=True)
    try:
        overlay=out/'overlay';overlay.mkdir(exist_ok=True)
        lines=['U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}',
               'U0 Oracle(){I64 size;U8 *src,*check,*line;CArcCompress *arc;']
        for name,size,mode in CASES:
            (overlay/(name+'.BIN')).write_bytes(payload(size,mode))
            lines += [f'size={size};src=CAlloc(size+1);',
                      f'if(size){{check=FileRead("T:/{name}.BIN");MemCpy(src,check,size);Free(check);}}',
                      'arc=CompressBuf(src,size);check=ExpandBuf(arc);',
                      'if(MemCmp(check,src,size)||check[size]){Report("FAIL original archive roundtrip\\n");return;}',
                      f'line=MStrPrint("EXPORT {name}.arc %X %X\\n",arc,arc->compressed_size);Report(line);Free(line);Free(check);Free(src);']
        lines += ['Report("DONE archive oracle\\n");}','Oracle;']
        (overlay/'Once.HC').write_text('\n'.join(lines)+'\n')
        report['oracle_bootstrap']={name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest()
            for name in ('0000Boot/0000Kernel.BIN.C','Compiler/Compiler.BIN')}
        report['oracle_script_sha256']=hashlib.sha256((overlay/'Once.HC').read_bytes()).hexdigest()
        subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(out/'oracle.iso')],cwd=ROOT,check=True)
        subprocess.run(['python3','tools/guest-run.py',str(out/'oracle.iso'),'--out',str(out/'oracle'),'--timeout','180','--qmp-stdio'],cwd=ROOT,check=True)
        commands=[('U8 ArchiveBytes[65536];',[]),
                  ('U8 ArchiveByte(U32 r,I64 mode){U8 v=r>>24;if(mode==0)return 81;if(mode==1)return 65+(v&15);if(mode==2)return v&127;if(mode==4)return 255;if(mode==5)return 128+(v&15);return v;}',[]),
                  ('I64 ArchiveWrite(U8 *name,I64 size,I64 mode){U32 r=0x12345678;I64 i;for(i=0;i<size;i++){r=r*1664525+1013904223;ArchiveBytes[i]=ArchiveByte(r,mode);}return FileWrite(name,ArchiveBytes,size,0x1122334455667788)>0;}',[])]
        for name,size,mode in CASES:
            commands.append((f'ArchiveWrite("C:/Probe/{name}.BIN.Z",{size},{mode});',['1']))
        final_cases=list(CASES)
        expected_date=DATE
        if args.replace:
            commands.append(('I64 ArchiveDate=0x1122334455667789;',[]))
            commands.append(('I64 ArchiveReplace(U8 *name,I64 size,I64 mode){if(!ArchiveWrite(name,size,mode))return 0;return FileWrite(name,ArchiveBytes,size,ArchiveDate)>0;}',[]))
            final_cases=[]
            for (name,_,_), (source,size,mode) in zip(CASES,reversed(CASES)):
                commands.append((f'ArchiveReplace("C:/Probe/{name}.BIN.Z",{size},{mode});',['1']))
                final_cases.append((name,size,mode,source))
            expected_date=DATE+1
        commands.append(('6*7;',['42']))
        runner=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        report['behavior']=runner(candidate,out/'behavior',snapshot=False,cpu='486,-fpu',qmp_stdio=True,
            startup_check={'status':'ok','answers':[],'commands':commands})
        build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        report['filesystem']=build['verify_mutated_volume'](candidate)
        find=runpy.run_path(str(ROOT/'tools/test-i386-public-file-write.py'))['find_record']
        names={f'/Probe/{name}.BIN.Z' for name,_,_ in CASES}
        files=build['mutated_file_contents'](candidate,names)
        results={}
        for case in final_cases:
            name,size,mode=case[:3]
            source=case[3] if len(case)>3 else name
            path=f'/Probe/{name}.BIN.Z';entry=find(candidate,path)
            archive=files.get(path);expected=(out/'oracle'/(source+'.arc')).read_bytes()
            if archive!=expected:raise ValueError(f'{name}: native archive differs from original')
            if not entry or entry['date']!=expected_date or entry['attr']!=0xC00:
                raise ValueError(f'{name}: archive metadata differs')
            stored,expanded,kind=struct.unpack_from('<qqB',archive)
            if stored!=len(archive) or expanded!=size:raise ValueError(f'{name}: invalid archive header')
            if source=='single8' and kind!=1:raise ValueError('One eight-bit byte must use the original capacity fallback')
            if source.startswith('fallback') and kind!=1:raise ValueError(f'{name}: fallback was not exercised')
            if source.startswith('dictionary') and (kind!=(2 if mode==1 else 3) or (stored-18)*8//12<=4096):
                raise ValueError('Dictionary fixture did not emit enough codes to require recycling')
            results[name]=dict(bytes=stored,expanded=expanded,type=kind,sha256=hashlib.sha256(archive).hexdigest())
        report.update(result='pass',cases=results,replacements=args.replace)
    except Exception as error:
        report['error']=str(error);raise
    finally:
        report['source_disk_unchanged']=args.disk.read_bytes()==original
        if not report['source_disk_unchanged']:report.update(result='fail',error='Source changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':main()
