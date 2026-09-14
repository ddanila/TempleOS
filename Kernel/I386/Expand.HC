#include "/Kernel/I386/Expand.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/ArcExpand.HH"
class CI386ArcCheck
{
  U8 valid[512];
  I64 previous;
  Bool first;
};
I64 I386ArcChain(CI386ArcCheck *check,CArcCtrl *c,I64 code,I64 forbidden)
{
  I64 length=1;
  while(code>=c->min_table_entry) {
    if(code>=4096 || code==forbidden || !(check->valid[code>>3]&(1<<(code&7))) || length>=4096) return -1;
    length++; code=c->compress[code].basecode;
  }
  return length;
}
I64 I386ArcCheckedRead(U8 *context,CArcCtrl *c)
{
  CI386ArcCheck *check=context;
  I64 code=I386ArcReadCode(c),current,length;
  if(code<0) return -1;
  if(check->first) {
    if(code>=c->min_table_entry) return -1;
    check->first=FALSE; check->previous=code;
    return code;
  }
  current=c->cur_entry-c->compress;
  if(current<c->min_table_entry || current>=4096 ||
      I386ArcChain(check,c,check->previous,current)<0) return -1;
  if(code==current) length=I386ArcChain(check,c,check->previous,-1)+1;
  else length=I386ArcChain(check,c,code,-1);
  if(length<1 || length>4096) return -1;
  check->valid[current>>3]|=1<<(current&7);
  check->previous=code;
  return code;
}
U8 *I386ExpandBuf(CI386Heap *heap,CArcCompress *arc,I64 archive_size,I64 *size=0)
{
  CArcCtrl *c=0;
  CI386ArcCheck check;
  U8 *output=0,*body;
  I64 i,expanded,packed,type;
  U32 flags;
  Bool ok=FALSE;
  if(!heap || !arc || archive_size<17 || archive_size>0xFFFFFFFF ||
      (arc+0)(U64)+archive_size>0xFFFFFFFF) return 0;
  expanded=arc->expanded_size; packed=arc->compressed_size; type=arc->compression_type;
  if(expanded<0 || expanded>0xFFFFFFFF-24 || packed<17 || packed>archive_size ||
      type<CT_NONE || type>CT_8_BIT || (type==CT_NONE && expanded>packed-17)) return 0;
  flags=I386IrqSave;
  output=I386HeapAlloc(heap,expanded+1,FALSE);
  I386IrqRestore(flags);
  if(!output) return 0;
  if(type==CT_NONE) {
    body=(arc+0)(U8 *)+17;
    for(i=0;i<expanded;i++) output[i]=body[i];
    ok=TRUE;
  } else if(!expanded) ok=packed==17;
  else {
    c=I386ArcCtrlNew(heap,TRUE,type);
    if(c) {
      for(i=0;i<512;i++) check.valid[i]=0;
      check.previous=0; check.first=TRUE;
      c->src_buf=arc; c->src_pos=17<<3; c->src_size=packed<<3;
      c->dst_buf=output; c->dst_size=expanded;
      ok=ArcExpandStep(c,&I386ArcCheckedRead,&I386ArcEntryGet,&check) &&
        c->dst_pos==expanded && c->stk_ptr==c->stk_base &&
        c->src_size-c->src_pos<8;
      if(!I386ArcCtrlDel(heap,c)) ok=FALSE;
    }
  }
  if(!ok) {
    flags=I386IrqSave; I386HeapFree(heap,output); I386IrqRestore(flags); return 0;
  }
  output[expanded]=0;
  if(size) *size=expanded;
  return output;
}
