I64 ArcSystemRead(U8 *context,CArcCtrl *c)
{
  return BFieldExtU32(c->src_buf,c->src_pos,c->next_bits_in_use);
}
U0 ArcExpandBuf(CArcCtrl *c)
{//Use ExpandBuf for a complete archive. Shared loop retains streaming state.
  if(!ArcExpandStep(c,&ArcSystemRead,&ArcEntryGet)) throw('Compress');
}

CArcCtrl *ArcCtrlNew(Bool expand,I64 compression_type=CT_8_BIT)
{//MAlloc archive ctrl struct.
  CArcCtrl *c;
  c=CAlloc(sizeof(CArcCtrl));
  if (expand) {
    c->stk_base=MAlloc(1<<ARC_BITS_MAX);
    c->stk_ptr=c->stk_base;
  }
  ArcCtrlSeed(c,compression_type);
  ArcEntryGet(c);
  c->entry_used=TRUE;
  return c;
}

U0 ArcCtrlDel(CArcCtrl *c)
{//Free archive ctrl struct.
  Free(c->stk_base);
  Free(c);
}

U8 *ExpandBuf(CArcCompress *arc,CTask *mem_task=NULL)
{//See $LK,"::/Demo/Dsk/SerializeTree.HC"$.
  CArcCtrl *c;
  U8 *res;

  if (!(CT_NONE<=arc->compression_type<=CT_8_BIT) ||
	arc->expanded_size>mem_mapped_space)
    throw('Compress');

  res=MAlloc(arc->expanded_size+1,mem_task);
  res[arc->expanded_size]=0; //terminate
  switch [arc->compression_type] {
    case CT_NONE:
      MemCpy(res,&arc->body,arc->expanded_size);
      break;
    case CT_7_BIT:
    case CT_8_BIT:
      c=ArcCtrlNew(TRUE,arc->compression_type);
      c->src_size=arc->compressed_size<<3;
      c->src_pos=sizeof(CArcCompress)<<3;
      c->src_buf=arc;
      c->dst_size=arc->expanded_size;
      c->dst_buf=res;
      c->dst_pos=0;
      ArcExpandBuf(c);
      ArcCtrlDel(c);
      break;
  }
  return res;
}
