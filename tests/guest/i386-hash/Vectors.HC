U0 HashTestString(U8 *buffer,I64 index)
{//Explicit wide intermediates/masks keep the byte sequence identical on both hosts.
  I64 i,length=index%257;
  U64 state=index+0x386;
  I64 ch;
  for(i=0;i<length;i++) {
    state=(state*1664525+1013904223)&0xFFFFFFFF;
    ch=(state>>24)&255;
    if(!ch) ch=1;
    if(index==256) ch=255;
    buffer[i]=ch;
  }
  buffer[length]=0;
}
