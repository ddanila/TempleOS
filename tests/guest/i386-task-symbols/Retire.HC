//Optimizer tree references remain readable after unlink, until graph disposal.
I64 CodeRetireTest()
{
  CCmpCtrl *cc,*other;
  CIntermediateCode *first,*second,*third,*foreign,*borrowed;
  CCodeCtrl *saved;
  U8 *fill,*block,*next;
  I64 used=heap.used,allocations=heap.allocations,base_used,base_allocations,enabled,round,size,full_used;
  U32 flags=GetRFlags;
  for(enabled=0;enabled<2;enabled++) {
    SetRFlags((flags&~0x200)|(enabled*0x200));
    cc=I386TaskCmpCtrlNew(&task_compiler,"retire",CCF_DONT_FREE_BUF);
    other=I386TaskCmpCtrlNew(&task_compiler,"foreign",CCF_DONT_FREE_BUF);
    if(!cc || !other) return 110;
    foreign=I386ICAdd(&heap,other,0x0A,7,0);
    if(!foreign || I386ICRetire(&heap,cc,foreign) || I386ICRetire(&heap,cc,0) ||
        I386ICRetire(&heap,cc,&cc->coc.coc_head) || !I386CmpCtrlDel(&heap,other)) return 111;
    base_used=heap.used; base_allocations=heap.allocations;
    first=I386ICAdd(&heap,cc,0x0A,0xFEDCBA9876543210,0);
    second=I386ICAdd(&heap,cc,0x0A,2,0);
    saved=I386COCSave(&heap,cc);
    if(!first || !second || !saved) return 112;
    second->t.arg1_tree=first; borrowed=second->t.arg1_tree;
    fill=0;
    for(size=8192;size>=8;size>>=1)
      while(block=I386HeapAlloc(&heap,size,FALSE)) { block(U8 **)[0]=fill; fill=block; }
    full_used=heap.used;
    if(!I386ICRetire(&heap,cc,first) || I386ICRetire(&heap,cc,first) ||
        heap.used!=full_used || borrowed->ic_data!=0xFEDCBA9876543210 ||
        cc->coc.coc_head.next!=second || second->last!=&cc->coc.coc_head.next ||
        first->next!=second || first->last!=&cc->coc.coc_head.next) return 113;
    while(fill) {
      next=fill(U8 **)[0]; if(!I386HeapFree(&heap,fill)) return 114; fill=next;
    }
    third=I386ICAdd(&heap,cc,0x0A,0x1122334455667788,0);
    if(!third || third==first || borrowed->ic_data!=0xFEDCBA9876543210 ||
        !I386COCDiscard(&heap,cc) || I386HeapSize(&heap,borrowed)<sizeof(CIntermediateCode) ||
        borrowed->ic_data!=0xFEDCBA9876543210 || !I386COCHeaderFree(&heap,cc,saved) ||
        I386HeapSize(&heap,borrowed)<sizeof(CIntermediateCode)) return 115;
    //Header release alone is not an optimizer phase boundary. A subsequent
    //discard with no other live records can collect the retired instruction.
    if(!I386COCDiscard(&heap,cc) || I386HeapSize(&heap,borrowed)!=-1 ||
        heap.used!=base_used || heap.allocations!=base_allocations) return 116;
    for(round=0;round<32;round++) {
      first=I386ICAdd(&heap,cc,0x0A,round,0);
      second=I386ICAdd(&heap,cc,0x0A,round+1,0);
      if(!first || !second || !I386ICRetire(&heap,cc,first) || first->ic_data!=round ||
          !I386COCDiscard(&heap,cc) || heap.used!=base_used || heap.allocations!=base_allocations) return 117;
    }
    first=I386ICAdd(&heap,cc,0x0A,123,0);
    if(!first || !I386COCPush(&heap,cc) || !I386ICRetire(&heap,cc,first) ||
        !I386CmpCtrlEnter(&heap,cc) || !I386CmpCtrlUnwind(&root,&root.next_cc) ||
        root.lifetime_refs || heap.used!=used || heap.allocations!=allocations ||
        !I386HeapValid(&heap) || (GetRFlags&0x200)!=(enabled*0x200)) return 118;
    SetRFlags(flags);
  }
  return 0;
}
