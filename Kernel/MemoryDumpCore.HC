public U0 D(U8 *addr,I64 cnt=0x80,Bool show_offset=TRUE)
{//Dump mem, showing offsets.
//See $LK,"DocD",A="MN:DocD"$() for a live dump.
  I64 i,j,ch;
  U8 *ptr=addr;
  while (cnt) {
    if (show_offset)
      "%08X ",ptr-addr;
    else
      "%010X ",ptr;
    if (cnt>16)
      j=16;
    else
      j=cnt;
    for (i=0;i<j;i++)
      "%02X ",ptr[i];
    for (;i<16;i++)
      "   ";
    for (i=0;i<j;i++) {
      ch=ptr[i];
      if (ch<CH_SHIFT_SPACE || ch==CH_BACKSPACE)
	ch='.';
      '' ch;
      if (ch=='$$')
	'' ch;
    }
    '\n';
    cnt-=j;
    ptr+=j;
  }
}
