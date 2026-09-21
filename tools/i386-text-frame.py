"""Independent expected VGA pixels for the native text-layer demonstration."""
from pathlib import Path
import re
import struct


def text_frame_pixels(mode):
    font_source=(Path(__file__).resolve().parents[1]/'Kernel/FontStd.HC').read_bytes()
    font=b''.join(struct.pack('<Q',int(s,16)) for s in re.findall(rb'0x[0-9A-Fa-f]{16}',font_source))
    assert len(font)==2048
    px,py={2:(3,-2),3:(-7,7)}.get(mode,(0,0))
    hide=mode==3
    sx,sy=int(px<0),int(py<0)
    cols,rows=80-int(bool(px or hide)),60-int(bool(py or hide))
    cells=[]
    for i in range(4800):
        x=i%31-15 if i%7==0 else 0
        y=i%31-15 if i%11==0 else 0
        cells.append((i*17&255)|((i*7&255)<<8)|((x&31)<<16)|((y&31)<<21)|((i//256%16)<<28))
    pixels=bytearray(640*480)
    def attr(cell):
        a=(cell>>8)&255
        if cell&(1<<30): a^=255
        if cell&(1<<29): a=((a<<4)|(a>>4))&255
        if cell&(1<<28) and mode&1: a=((a<<4)|(a>>4))&255
        return a
    for row in range(rows):
        for col in range(cols):
            cell=cells[(row+sy)*80+col+sx]
            base=((row+sy)*8+py)*640+(col+sx)*8+px
            for y in range(8): pixels[base+y*640:base+y*640+8]=bytes([attr(cell)>>4])*8
    for row in range(rows):
        for col in range(cols):
            cell=cells[(row+sy)*80+col+sx]
            base=(row+sy)*8*640+(col+sx)*8
            packed=((cell>>16)&1023)+px+(py<<5)
            if packed:
                x=packed&31
                if x&16: x|=~31
                y=packed>>5
                if y&16: y|=~31
                base+=y*640+x
                if not 0<=base<640*480-7*640-8: continue
            for y in range(8):
                glyph=255 if y==7 and cell&(1<<31) else font[(cell&255)*8+y]
                for x in range(8):
                    if glyph&(1<<x): pixels[base+y*640+x]=attr(cell)&15
    palette=[]
    for c in range(16):
        rgb=[(42 if c&bit else 0)+(21 if c&8 else 0) for bit in (4,2,1)]
        if c==6: rgb[1]=21
        #Match the QEMU VGA DAC expansion used by tools/test-i386.py.
        rgb=[(v<<2)|((v&1)*3) for v in rgb]
        palette.append(bytes(rgb))
    return b''.join(palette[c] for c in pixels)
