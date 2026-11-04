#!/usr/bin/env python3
"""Verify each numeric case's own command and adjacent result in captured pixels."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]

def font_bytes():
    data=b''.join(struct.pack('<Q',int(value,16)) for value in re.findall(rb'0x[0-9A-Fa-f]{16}',(ROOT/'Kernel/FontStd.HC').read_bytes()))
    if len(data)!=2048:raise ValueError('Unexpected font size')
    return data

def text_at(pixels,font,text,column,row):
    colors=set()
    for n,ch in enumerate(text):
        for y in range(8):
            bits=font[ch*8+y]
            for x in range(8):
                color=pixels[(column+n)*8+x,row*8+y]
                if bits&(1<<x):
                    if color==(255,255,255):return None
                    colors.add(color)
                elif color!=(255,255,255):return None
    return sorted(colors)

def verify(path,word,font):
    command=b'ACNCheck("'+word+b'");'
    pixels=Image.open(path).convert('RGB').load()
    for row in range(1,59):
        for column in range(41-len(command)):
            source_colors=text_at(pixels,font,command,column,row)
            if source_colors is None:continue
            for result_column in range(39):
                result_colors=text_at(pixels,font,b'42',result_column,row+1)
                if result_colors and len(result_colors)==1:
                    return dict(command_column=column,command_row=row,source_colors=source_colors,result_column=result_column,result_row=row+1,result_foreground=result_colors[0])
    raise ValueError(f'Missing case-specific source and adjacent 42 in {path}')

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('run',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    if args.out.exists():ap.error('Use a fresh output file')
    run=args.run.resolve();result_path=run/'result.json';result=json.loads(result_path.read_text())
    if result.get('result')!='pass' or not result.get('inputs_unchanged') or result.get('indices')!=list(range(10)) or len(result.get('cases',[]))!=10:raise ValueError('Passed complete numeric run required')
    paths=[Path(__file__).resolve(),ROOT/'Kernel/FontStd.HC',result_path]+[run/f'guest/executed{index}.png' for index in range(10)]
    snapshot=args.out.with_suffix('.source.py')
    if snapshot.exists():raise ValueError('Use a fresh snapshot path')
    snapshot.write_bytes(Path(__file__).read_bytes());paths.append(snapshot.resolve())
    sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest();pins={str(path):sha(path) for path in paths}
    report=dict(result='running',input_sha256=pins,cases=[],scope='Exact font masks for each unique submitted completion command and 42 on the immediately following row. Prevents an earlier result from satisfying a later case. Left forty columns only; not full terminal appearance.')
    try:
        font=font_bytes()
        for index,case in enumerate(result['cases']):
            if case['index']!=index:raise ValueError('Incomplete or reordered cases')
            report['cases'].append(dict(index=index,word=case['word'],**verify(run/f'guest/executed{index}.png',case['word'].encode('ascii'),font)))
        report['result']='pass'
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(path))==digest for path,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        args.out.write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
