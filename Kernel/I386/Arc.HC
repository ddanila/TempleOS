#include "/Kernel/I386/Arc.HH"
U0 I386ArcEntryGet(CArcCtrl *c)
{//Native pointer arithmetic replaces the x64 assembly's fixed record strides.
  I64 i;
  CArcEntry *tmp,**link;
  if(c->entry_used&1) {
    i=c->free_idx;
    c->entry_used&=~1;
    c->cur_entry=c->next_entry;
    c->cur_bits_in_use=c->next_bits_in_use;
    if(c->next_bits_in_use<ARC_BITS_MAX) {
      c->next_entry=&c->compress[i++];
      if(i==c->free_limit) {
        c->next_bits_in_use++;
        c->free_limit=1<<c->next_bits_in_use;
      }
    } else {
      do if(++i==c->free_limit) i=c->min_table_entry;
      while(c->hash[i]);
      tmp=&c->compress[i];
      c->next_entry=tmp;
      link=&c->hash[tmp->basecode];
      while(*link) {
        if(*link==tmp) { *link=tmp->next; break; }
        link=&(*link)->next;
      }
    }
    c->free_idx=i;
  }
}

#include "/Kernel/ArcSeed.HC"
#include "/Kernel/I386/Cpu.HH"
#define I386_ARC_MAGIC 0x41333243
class CI386ArcOwner
{
  CArcCtrl control;
  CI386Heap *heap;
  U8 *stack;
  U32 signature;
};
CArcCtrl *I386ArcCtrlNew(CI386Heap *heap,Bool expand,I64 compression_type=CT_8_BIT)
{
  CI386ArcOwner *owner;
  U32 flags=I386IrqSave;
  owner=I386HeapAlloc(heap,sizeof(CI386ArcOwner),TRUE);
  if(owner && expand) {
    owner->stack=I386HeapAlloc(heap,1<<ARC_BITS_MAX,FALSE);
    if(!owner->stack) { I386HeapFree(heap,owner); owner=0; }
  }
  I386IrqRestore(flags);
  if(!owner) return 0;
  owner->heap=heap; owner->signature=I386_ARC_MAGIC;
  owner->control.stk_base=owner->control.stk_ptr=owner->stack;
  ArcCtrlSeed(&owner->control,compression_type);
  I386ArcEntryGet(&owner->control);
  owner->control.entry_used=1;
  return &owner->control;
}
Bool I386ArcCtrlDel(CI386Heap *heap,CArcCtrl *c)
{
  CI386ArcOwner *owner=c;
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  if(I386HeapSize(heap,owner)!=sizeof(CI386ArcOwner)) goto done;
  if(owner->signature!=I386_ARC_MAGIC || owner->heap!=heap ||
      (owner->stack && I386HeapSize(heap,owner->stack)!=(1<<ARC_BITS_MAX))) goto done;
  //Only constructor-owned allocations are released; source/destination buffers stay borrowed.
  if(owner->stack && !I386HeapFree(heap,owner->stack)) goto done;
  owner->signature=0;
  result=I386HeapFree(heap,owner);
done:
  I386IrqRestore(flags);
  return result;
}
