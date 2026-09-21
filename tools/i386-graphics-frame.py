"""Independent expected VGA frames for native text/task/persistent/final layering."""
from pathlib import Path
import runpy


def graphics_frame_pixels(mode):
    pixels=bytearray(runpy.run_path(str(Path(__file__).with_name('i386-text-frame.py')))['text_frame_pixels'](mode))
    palette=[]
    for color in range(16):
        rgb=[(42 if color&bit else 0)+(21 if color&8 else 0) for bit in (4,2,1)]
        if color==6: rgb[1]=21
        palette.append(bytes((v<<2)|((v&1)*3) for v in rgb))
    def put(x,y,color):
        offset=(y*640+x)*3
        pixels[offset:offset+3]=palette[color]
    for y in range(80,240):
        for x in range(80,400): put(x,y,(x//20+y//20)&15)
    for y in range(140,340):
        for x in range(240,560):
            if (x//16+y//16)&1: put(x,y,(x//32+y//32)&15)
    for y in range(180,300):
        for x in range(300,320): put(x,y,15)
    for y in range(230,250):
        for x in range(250,370): put(x,y,0)
    return bytes(pixels)
