U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 DCLoadGenerate()
{
  I64 i,j,size,high,flags;
  CDC *dc;
  U8 *data,*name,*line;
  CArcCompress *arc;
  for(i=0;i<4;i++) {
    dc=DCNew(9,32);dc->x0=-2;dc->y0=3;dc->cdt=123456789;
    high=0;if(i==3)high=128;
    for(j=0;j<512;j++)dc->body[j]=(j&15)|high;
    if(i&1) {dc->palette[2].r=1234;dc->palette[2].g=5678;dc->palette[2].b=9012;}
    flags=0;if(i>=2)flags=DCSF_COMPRESSED;
    data=DCSave(dc,&size,flags);
    if(i>=2) {
      arc=data+offset(CDC.end);if(i&1)arc(U8 *)+=COLORS_NUM*sizeof(CBGR48);
      flags=CT_7_BIT;if(i==3)flags=CT_8_BIT;
      if(arc->compression_type!=flags) {
        Report("FAIL expected archive type\n");return;
      }
    }
    name=MStrPrint("B:/load%d.DATA",i);FileWrite(name,data,size);Free(name);
    line=MStrPrint("EXPORT load%d.DATA %X %X\n",i,data,size);Report(line);Free(line);
    DCDel(dc);
  }
}
DCLoadGenerate;
