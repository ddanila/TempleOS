//Shared original-x64/native device-context ownership and behavior checks.
I64 GraphicsContextCheck()
{
  CDC *dc,*alias,*empty,*saved=gr.dc;
  I64 i,x,y,z,result=20,before=Fs->data_heap->used_u8s;
  I64 *matrix;
  CDate date;
  CD3I32 p1,p2,p3;
  CColorROPU32 color;
  U8 *span;
  dc=DCNew(9,3);
  if(dc->dc_signature!=DCS_SIGNATURE_VAL || dc->width!=9 || dc->width_internal!=16 ||
      dc->height!=3 || dc->mem_task!=Fs || dc->win_task!=Fs ||
      MHeapCtrl(dc)!=Fs->data_heap || MHeapCtrl(dc->body)!=Fs->data_heap ||
      MHeapCtrl(dc->r)!=Fs->data_heap) result=-1;
  for(i=0;i<48;i++) if(dc->body[i]) result=-2;
  for(i=0;i<16;i++) {
    if(dc->palette[i]!=gr_palette_std[i]) result=-3;
    if(i%5==0) { if(dc->r[i]!=(1(I64)<<32)) result=-4; }
    else if(dc->r[i]) result=-4;
  }
  if(dc->r_norm!=(1(I64)<<32) || dc->color!=BLACK || dc->thick!=1 ||
      dc->ls.x!=37837 || dc->ls.y!=37837 || dc->ls.z!=37837) result=-5;
  //Default-context operations must address the real public global.
  gr.dc=dc; DCFill(,0x123456A5);
  for(i=0;i<48;i++) if(dc->body[i]!=0xA5) result=-6;
  DCClear;
  for(i=0;i<48;i++) if(dc->body[i]) result=-7;
  DCExtentsInit;
  if(!(dc->flags&DCF_RECORD_EXTENTS) || dc->min_x!=I64_MAX || dc->max_x!=I64_MIN ||
      dc->min_y!=I64_MAX || dc->max_y!=I64_MIN) result=-8;
  dc->flags|=DCF_TRANSFORMATION|DCF_SYMMETRY|DCF_JUST_MIRROR;
  dc->x=7; dc->color=RED; dc->body[0]=WHITE;
  DCRst(dc);
  if(dc->x || dc->color!=BLACK || dc->body[0]!=WHITE ||
      dc->flags&(DCF_TRANSFORMATION|DCF_SYMMETRY|DCF_JUST_MIRROR) ||
      !(dc->flags&DCF_RECORD_EXTENTS)) result=-9;
  x=-3; y=4; z=5; dc->x=9; dc->y=-2; dc->z=11;
  (*dc->transform)(dc,&x,&y,&z);
  if(x!=6 || y!=2 || z!=16) result=-10;
  //32.32 fractional and negative arithmetic, not just identity transforms.
  dc->r[0]=1(I64)<<31; dc->r[5]=-(1(I64)<<32); dc->r[11]=2(I64)<<32;
  x=-3; y=4; z=5; Mat4x4MulXYZ(dc->r,&x,&y,&z);
  if(x!=-2 || y!=-4 || z!=7) result=-11;
  if(DCDepthBufAlloc(dc)!=dc->depth_buf || MHeapCtrl(dc->depth_buf)!=Fs->data_heap) result=-12;
  for(i=0;i<48;i++) if(dc->depth_buf[i]!=I32_MAX) result=-12;
  dc->depth_buf[17]=-123; DCDepthBufRst(dc);
  if(dc->depth_buf[17]!=I32_MAX || DCSize(dc)!=MSize2(dc)+MSize2(dc->body)+MSize2(dc->depth_buf) || DCSize(0)) result=-13;
  alias=DCAlias;
  if(alias->alias!=dc || !(alias->flags&DCF_ALIAS) || alias->body!=dc->body ||
      alias->r==dc->r || alias->r[0]!=(1(I64)<<32) || alias->mem_task!=Fs ||
      alias->depth_buf!=dc->depth_buf) result=-14;
  //Original aliases inherit the depth pointer; callers must detach borrowed depth before deletion.
  alias->depth_buf=0; alias->body[1]=BLUE; alias->color=RED;
  DCDel(alias);
  if(dc->body[1]!=BLUE || dc->color!=BLACK || dc->depth_buf[17]!=I32_MAX) result=-15;
  empty=DCNew(5,7,,TRUE);
  if(empty->body || !(empty->flags&DCF_DONT_DRAW) || empty->width_internal!=8) result=-16;
  DCDel(empty); DCDel(0);
  MemSet(&p1,0,sizeof(p1)); MemSet(&p2,0,sizeof(p2)); MemSet(&p3,0,sizeof(p3));
  color=RED; (*dc->lighting)(dc,&p1,&p2,&p3,color);
  if(dc->dither_probability_u16 || dc->color!=(ROPF_PROBABILITY_DITHER+((RED^8)<<16)+RED)) result=-17;
  matrix=Mat4x4IdentNew; matrix[0]=matrix[5]=matrix[10]=2(I64)<<32;
  Free(dc->r); DCMat4x4Set(,matrix);
  if(dc->r!=matrix || dc->r_norm<8589800000 || dc->r_norm>8590000000) result=-18;
  //The saved bitmap prefix remains 32 bytes independent of pointer width.
  dc->cdt=0x123456789ABCDEF0; dc->x0=-1; dc->y0=0x12345678;
  span=&dc->start; date=dc->cdt;
  if((&dc->end)(U8 *)-span!=32 || span(U64 *)[0]!=date ||
      span(U32 *)[2]!=0xFFFFFFFF || span(U32 *)[3]!=0x12345678 || sizeof(CDC)&7) result=-19;
  gr.dc=saved; DCDel(dc);
  if(Fs->data_heap->used_u8s!=before) result=-20;
  return result;
}
