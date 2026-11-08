//Private IR grouping must preserve retired tree operands and public-node policy.
CIntermediateCode *SlabNode(CCmpCtrl *cc,I64 value)
{ return I386ICAddBytes(&heap,cc,0x0A,value,0,0,I386_FRONTEND_IC_BYTES); }
I64 CodeSlabTest()
{
  CCmpCtrl *cc,*other;
  CI386CmpCtrl *owned;
  CI386ICSlab *slab;
  CIntermediateCode *first,*second,*node,*foreign;
  CCodeCtrl *saved;
  CI386CmpRelease release;
  U8 *reserve,*fill,*block,*next;
  I64 used=heap.used,allocations=heap.allocations,base_used,base_allocations,i,size,count,enabled,reuse_used,reuse_allocations,reuse_issued;
  U32 flags=GetRFlags,irq;
  for(enabled=0;enabled<2;enabled++) {
    SetRFlags((flags&~0x200)|(enabled*0x200));
    cc=I386TaskCmpCtrlNew(&task_compiler,"slabs",CCF_DONT_FREE_BUF);owned=cc;
    other=I386TaskCmpCtrlNew(&task_compiler,"foreign slab",CCF_DONT_FREE_BUF);
    if(!cc || !other || !(foreign=SlabNode(other,17)) ||
        I386ICRetire(&heap,cc,foreign) || !I386CmpCtrlDel(&heap,other))return 310;
    base_used=heap.used;base_allocations=heap.allocations;
    first=SlabNode(cc,0xFEDCBA9876543210);second=SlabNode(cc,2);
    if(!first || !second || I386HeapSize(&heap,first)!=-1 ||
        I386ICRetire(&heap,cc,first(U8 *)+4))return 311;
    second->t.arg1_tree=first;
    for(i=0;i<199;i++)if(!SlabNode(cc,i+3))return 312;
    count=0;for(slab=owned->ic_slabs;slab;slab=slab->next)count++;
    if(count<2 || heap.allocations-base_allocations>=16 ||
        !(saved=I386COCSave(&heap,cc)) || !I386ICRetire(&heap,cc,first) ||
        I386ICRetire(&heap,cc,first) || first->ic_data!=0xFEDCBA9876543210 ||
        !I386COCDiscard(&heap,cc) || !owned->ic_slabs ||
        !I386ICLifetime(&heap,cc,first) || first->ic_data!=0xFEDCBA9876543210)return 313;
    //Freed slots are reusable, but a retired operand must never be reused.
    reuse_used=heap.used;reuse_allocations=heap.allocations;reuse_issued=owned->ic_slabs->issued;
    for(i=0;i<150;i++) {
      node=SlabNode(cc,i+211);
      if(!node || node==first || heap.used!=reuse_used || heap.allocations!=reuse_allocations ||
          owned->ic_slabs->issued!=reuse_issued || first->ic_data!=0xFEDCBA9876543210)return 325;
    }
    if(!I386COCDiscard(&heap,cc) || !I386COCHeaderFree(&heap,cc,saved) ||
        !I386ICLifetime(&heap,cc,first))return 326;
    if(!I386COCDiscard(&heap,cc) || owned->ic_slabs ||
        I386ICLifetime(&heap,cc,first) || heap.used!=base_used ||
        heap.allocations!=base_allocations)return 314;
    //FrontendPop uses retired collection directly, without a later discard.
    first=SlabNode(cc,67);
    if(!first || !I386ICRetire(&heap,cc,first))return 327;
    release.heap=&heap;release.control=cc;release.ok=TRUE;
    irq=I386IrqSave;I386CodeRetiredCollect(&release);I386IrqRestore(irq);
    if(!release.ok || owned->ic_slabs || owned->code_next!=&owned->code_next ||
        heap.used!=base_used || heap.allocations!=base_allocations)return 328;
    //A saved live outer tree keeps its retired operand across inner emission.
    first=SlabNode(cc,71);second=SlabNode(cc,83);
    if(!first || !second)return 315;
    second->t.arg1_tree=first;
    if(!I386ICRetire(&heap,cc,first) ||
        !I386COCPush(&heap,cc) || !I386COCInit(&heap,cc) ||
        !SlabNode(cc,97) || !I386COCInstructionsRelease(&heap,cc) ||
        first->ic_data!=71 || second->t.arg1_tree!=first ||
        !I386ICLifetime(&heap,cc,first) ||
        !(saved=I386COCPopNoFree(&heap,cc)) || !I386COCHeaderFree(&heap,cc,saved) ||
        !I386COCDiscard(&heap,cc) || owned->ic_slabs || heap.used!=base_used)return 315;
    //Constrain the only available span to three slots, then exhaust it.
    reserve=I386HeapAlloc(&heap,offset(CI386ICSlab.body)+3*I386_IC_SLAB_SLOT_BYTES);
    if(!reserve)return 316;
    fill=0;
    for(size=8192;size>=8;size>>=1)
      while(block=I386HeapAlloc(&heap,size,FALSE)) {block(U8 **)[0]=fill;fill=block;}
    if(!I386HeapFree(&heap,reserve) || !(first=SlabNode(cc,109)) ||
        !(second=SlabNode(cc,113)) || !(node=SlabNode(cc,127)) ||
        !owned->ic_slabs || owned->ic_slabs->capacity!=3 ||
        owned->ic_slabs->issued!=3 || owned->ic_slabs->live!=3 || SlabNode(cc,131))return 317;
    if(!I386COCDiscard(&heap,cc) || owned->ic_slabs)return 318;
    while(fill) {next=fill(U8 **)[0];if(!I386HeapFree(&heap,fill))return 319;fill=next;}
    if(heap.used!=base_used || heap.allocations!=base_allocations)return 320;
    //A span that cannot hold a slab still admits an individual compact node.
    reserve=I386HeapAlloc(&heap,I386_FRONTEND_IC_BYTES+sizeof(CI386CodeAllocation));
    if(!reserve)return 321;
    fill=0;
    for(size=8192;size>=8;size>>=1)
      while(block=I386HeapAlloc(&heap,size,FALSE)) {block(U8 **)[0]=fill;fill=block;}
    if(!I386HeapFree(&heap,reserve) || !(first=SlabNode(cc,137)) || owned->ic_slabs ||
        I386HeapSize(&heap,first)!=I386_FRONTEND_IC_BYTES+sizeof(CI386CodeAllocation) ||
        !I386COCDiscard(&heap,cc))return 322;
    while(fill) {next=fill(U8 **)[0];if(!I386HeapFree(&heap,fill))return 323;fill=next;}
    //Ownership teardown drains live/retired slots without trusting graph links.
    first=SlabNode(cc,139);second=SlabNode(cc,149);
    if(!first || !second || !I386ICRetire(&heap,cc,first) ||
        !I386COCPush(&heap,cc) || !I386COCInit(&heap,cc) || !SlabNode(cc,151) ||
        !I386CmpCtrlEnter(&heap,cc) || !I386CmpCtrlUnwind(&root,&root.next_cc) ||
        root.lifetime_refs || heap.used!=used || heap.allocations!=allocations ||
        !I386HeapValid(&heap) || (GetRFlags&0x200)!=(enabled*0x200))return 324;
    SetRFlags(flags);
  }
  return 0;
}
