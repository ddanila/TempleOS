#!/usr/bin/env python3
"""Inspect captured picker frame layers; this is not a visual acceptance oracle."""
import argparse
from pathlib import Path
import collections,json,re,struct
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('capture',type=Path);args=ap.parse_args();out=args.capture.resolve()
phases=sorted(int(p.name.split('-')[1]) for p in out.glob('render-*-state.bin'))
if len(phases)<2:raise ValueError('At least two captured phases required')
font=b''.join(struct.pack('<Q',int(s,16)) for s in re.findall(rb'0x[0-9A-Fa-f]{16}',(ROOT/'Kernel/FontStd.HC').read_bytes()));assert len(font)==2048
palette=[]
for c in range(16):
 rgb=[(42 if c&bit else 0)+(21 if c&8 else 0) for bit in (4,2,1)]
 if c==6:rgb[1]=21
 palette.append(bytes((v<<2)|((v&1)*3) for v in rgb))
def save(name,data):
 Image.frombytes('RGB',(640,480),b''.join(palette[v] if v<16 else b'\xff\x00\xff' for v in data)).save(out/name)
def render(cells,blink):
 pixels=bytearray(307200)
 def attr(c):
  a=(c>>8)&255
  if c&(1<<30):a^=255
  if c&(1<<29):a=((a<<4)|(a>>4))&255
  if c&(1<<28) and blink:a=((a<<4)|(a>>4))&255
  return a
 for i,c in enumerate(cells):
  base=(i//80)*8*640+(i%80)*8
  for y in range(8):pixels[base+y*640:base+y*640+8]=bytes([attr(c)>>4])*8
 for i,c in enumerate(cells):
  x=(c>>16)&31;y=(c>>21)&31
  if x&16:x-=32
  if y&16:y-=32
  base=((i//80)*8+y)*640+(i%80)*8+x
  if (x or y) and not 0<=base<307200-7*640-8:continue
  for gy in range(8):
   glyph=255 if gy==7 and c&(1<<31) else font[(c&255)*8+gy]
   for gx in range(8):
    if glyph&(1<<gx):pixels[base+gy*640+gx]=attr(c)&15
 return pixels
report={}
for phase in phases:
 cells=struct.unpack('<4800I',(out/f'render-{phase}-cells.bin').read_bytes());state=struct.unpack('<16q',(out/f'render-{phase}-state.bin').read_bytes());actual=(out/f'render-{phase}-pixels.bin').read_bytes();overlay=(out/f'render-{phase}-overlay.bin').read_bytes();assert state[13:15]==(0,0)
 if len(actual)!=307200 or len(overlay)!=307200:raise ValueError('Incomplete pixel layer')
 left,right,top,bottom=state[7:11]
 if not (0<=left<=right<80 and 0<=top<=bottom<60):raise ValueError('Invalid popup bounds')
 save(f'captured-{phase}.png',actual)
 candidate=render(cells,False);save(f'cells-{phase}.png',candidate)
 (out/f'cells-{phase}.txt').write_text('\n'.join(''.join(chr(c&255) if 32<=c&255<127 else '.' for c in cells[row*80:(row+1)*80]) for row in range(60))+'\n')
 diffs=[];interior_diffs=[]
 for blink in (False,True):
  candidate=render(cells,blink)
  composed=bytes(o if o!=255 else c for o,c in zip(overlay,candidate))
  diffs.append(sum(a!=b for a,b in zip(composed,actual)))
  interior_diffs.append(sum(composed[y*640+x]!=actual[y*640+x]
    for y in range(top*8,(bottom+1)*8) for x in range(left*8,(right+1)*8)))
 report[phase]=dict(state=state,shifted_cells=sum(bool((c>>16)&1023) for c in cells),overlay_values=dict(collections.Counter(overlay)),rendered_values=dict(collections.Counter(actual)),text_plus_overlay_differences=diffs,popup_interior_differences=interior_diffs)
report['changed_cells']=sum(a!=b for a,b in zip(struct.unpack('<4800I',(out/'render-0-cells.bin').read_bytes()),struct.unpack('<4800I',(out/f'render-{phases[-1]}-cells.bin').read_bytes())))
(out/'layer-analysis.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
