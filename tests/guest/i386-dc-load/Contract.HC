I64 DCLoadContract(I64 drive)
{
  I64 i,j,size,used,high,flags,expected,mask=0;
  U8 *data,*name;
  CDC *dc;
  CTask *owner;
  Bool geometry=TRUE,pixels=TRUE,palette=TRUE,state=TRUE,ownership=TRUE,independent=TRUE;
  for(i=0;i<4;i++) {
    name=MStrPrint("%c:/load%d.DATA",drive,i);
    data=FileRead(name,&size);Free(name);
    if(!data)return 0;
    owner=NULL;if(i&1) {
      owner=Fs->parent_task;
      if(!owner || owner==Fs)ownership=FALSE;
    }
    dc=DCLoad(data,&used,owner);
    if(used!=size || dc->width!=9 || dc->width_internal!=16 || dc->height!=32 ||
       dc->x0!=-2 || dc->y0!=3 || dc->cdt!=123456789)geometry=FALSE;
    high=0;if(i==3)high=128;
    for(j=0;j<512;j++)
      if(dc->body[j]!=((j&15)|high))pixels=FALSE;
    for(j=0;j<COLORS_NUM;j++) {
      if(i&1 && j==2) {
        if(dc->palette[j].r!=1234 || dc->palette[j].g!=5678 || dc->palette[j].b!=9012)palette=FALSE;
      } else if(dc->palette[j]!=gr_palette_std[j])palette=FALSE;
    }
    flags=0;if(i&1)flags=DCF_PALETTE;
    if(dc->flags!=flags || dc->thick!=1 ||
       dc->r_norm!=0x100000000 || dc->dc_signature!=DCS_SIGNATURE_VAL)state=FALSE;
    for(j=0;j<16;j++) {
      expected=0;if(j%5==0)expected=0x100000000;
      if(dc->r[j]!=expected)state=FALSE;
    }
    if(!owner)owner=Fs;
    if(dc->mem_task!=owner || dc->win_task!=owner)ownership=FALSE;
    MemSet(data,0,size);Free(data);
    if(dc->body[7]!=(7|high))independent=FALSE;
    DCDel(dc);
  }
  if(geometry)mask|=1;if(pixels)mask|=2;if(palette)mask|=4;
  if(state)mask|=8;if(ownership)mask|=16;if(independent)mask|=32;
  return mask;
}

I64 ExpandRawContract()
{
  CArcCompress *arc=CAlloc(sizeof(CArcCompress)+8);
  U8 *body=&arc->body,*data;
  I64 i,mask=0,caught=0;
  Bool same=TRUE;
  if(!Fs->parent_task || Fs->parent_task==Fs) {Free(arc);return 0;}
  arc->compression_type=CT_NONE;arc->compressed_size=sizeof(CArcCompress);
  data=ExpandBuf(arc);
  if(data && !data[0])mask|=1;
  Free(data);
  arc->compressed_size=sizeof(CArcCompress)+8;arc->expanded_size=8;
  for(i=0;i<8;i++)body[i]=i*37;
  data=ExpandBuf(arc,Fs->parent_task);
  for(i=0;i<8;i++)if(data[i]!=body[i])same=FALSE;
  if(same && !data[8] && data!=body)mask|=2;
  Free(data);
  for(i=0;i<2;i++) {
    arc->compression_type=i*4;
    try {data=ExpandBuf(arc);Free(data);}
    catch {if(Fs->except_ch=='Compress')caught++;Fs->catch_except=TRUE;}
  }
  if(caught==2)mask|=4;
  arc->compression_type=CT_NONE;arc->expanded_size=I64_MAX;
  try {data=ExpandBuf(arc);Free(data);}
  catch {if(Fs->except_ch=='Compress')mask|=8;Fs->catch_except=TRUE;}
  arc->expanded_size=8;
  data=ExpandBuf(arc);
  if(data[7]==body[7] && !data[8])mask|=16;
  Free(data);Free(arc);return mask;
}
