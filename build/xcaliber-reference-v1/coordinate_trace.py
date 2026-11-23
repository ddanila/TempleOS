"""Record invalid floating coordinates before original sprite submission."""

import re


def instrument(source):
    calls = list(re.finditer(rb'\bSprite3ZB\(dc,', source))
    if not calls:
        raise ValueError('Missing X-Caliber sprite calls')
    for index, call in reversed(list(enumerate(calls, start=1))):
        head = f'XCRotate({index},dc,'.encode()
        source = source[:call.start()] + head + source[call.end():]
    helper = b'''U0 XCRotate(I64 site,CDC *dc,F64 x,F64 y,I64 z,U8 *sprite,F64 angle)
{
  U64 xb=*(&x)(U64 *),yb=*(&y)(U64 *),ab=*(&angle)(U64 *);
  U8 line[192],*p;
  if ((xb&0x7FF0000000000000)==0x7FF0000000000000 ||
      (yb&0x7FF0000000000000)==0x7FF0000000000000 ||
      (ab&0x7FF0000000000000)==0x7FF0000000000000) {
    StrPrint(line,"XC invalid sprite %d %016X %016X %016X\\n",site,xb,yb,ab);
    p=line;
    while (*p) OutU8(0xE9,*p++);
  }
  Sprite3ZB(dc,x,y,z,sprite,angle);
}

'''
    return helper + source
