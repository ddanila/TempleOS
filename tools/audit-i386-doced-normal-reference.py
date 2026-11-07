#!/usr/bin/env python3
"""Verify original editor state exports and all client pixels against the font/text oracle."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('reference',type=Path);args=ap.parse_args();p=args.reference.resolve()
    r=json.loads((p/'result.json').read_text())
    if r['result']!='pass' or not r['inputs_unchanged']:raise ValueError('Reference session did not pass')
    if any(not Path(n).is_file() or sha(Path(n))!=h for n,h in r['input_sha256'].items()):raise ValueError('Reference inputs changed')
    if struct.unpack('<4q',(p/'normal-active.bin').read_bytes())!=(127,)*4 or struct.unpack('<2q',(p/'normal-return.bin').read_bytes())!=(127,)*2:raise ValueError('State exports differ')
    for case in range(2):
        if (p/f'normal-edit-{case}.bin').read_bytes()!=b'Z\x05First\nSecond\n':raise ValueError('Serialized document differs')
    focus=[list(map(int,line.split()[3:])) for line in (p/'guest/debug.log').read_text().splitlines() if line.startswith('NORMAL EDIT FOCUS ')]
    if focus!=[[0,0,1],[0,1,1],[1,0,1],[1,1,1]]:raise ValueError('Caller focus differs')
    font=b''.join(struct.pack('<Q',int(v,16)) for v in re.findall(rb'0x[0-9A-Fa-f]{16}',(ROOT/'Kernel/FontStd.HC').read_bytes()))
    if len(font)!=2048:raise ValueError('Unexpected font')
    hashes={};rasters={}
    for stage in range(2):
        im=Image.new('RGB',(624,456),'white');px=im.load()
        for row,line in enumerate(['ZFirst' if stage else 'First','Second']):
            for col,ch in enumerate(line.encode()):
                for y in range(8):
                    for x in range(8):
                        if font[ch*8+y]&(1<<x):px[col*8+x,row*8+y]=(0,0,0)
        im.paste('white',(stage*8,0,stage*8+8,8));wanted=im.tobytes();rasters[str(stage)]=hashlib.sha256(wanted).hexdigest()
        for case in range(2):
            name=f'normal-{case}-{stage}';f=p/'guest'/(name+'-client.png')
            raw=Image.open(p/'guest'/(name+'.png')).convert('RGB').crop((8,16,632,472));raw.paste('white',(stage*8,0,stage*8+8,8))
            if raw.tobytes()!=wanted or Image.open(f).convert('RGB').tobytes()!=wanted:raise ValueError('Client differs: '+name)
            hashes[f.name]=sha(f)
    audit=dict(result='pass',client_sha256=hashes,expected_raster_sha256=rasters,focus=focus,
               compared_pixels_per_frame=624*456-64,auditor_sha256=sha(Path(__file__).resolve()),
               scope='Four fixed-geometry client frames match independently rendered First/Second or ZFirst/Second, black on white. Only the known caret cell is excluded; text/cursor and state exports are checked separately. Autocomplete is disabled/restored through its public API.')
    (p/'visual-audit.json').write_text(json.dumps(audit,indent=2)+'\n');print('PASS: original state, focus, serialized text and four client rasters')
if __name__=='__main__':main()
