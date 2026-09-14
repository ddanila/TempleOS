//Exercise the parser's copied-header patterns independently of allocation ownership.
I64 CodeViewsTest()
{
  CCmpCtrl *cc,*other;
  CCodeCtrl *saved,*increment,*parent,*alias;
  CIntermediateCode *node,*first;
  CCodeMisc *misc;
  U8 *fill,*block,*next;
  I64 used=heap.used,allocations=heap.allocations,enabled,sum,count,size;
  U32 flags=GetRFlags;
  for(enabled=0;enabled<2;enabled++) {
    SetRFlags((flags&~0x200)|(enabled*0x200));
    cc=I386TaskCmpCtrlNew(&task_compiler,"views",CCF_DONT_FREE_BUF);
    other=I386TaskCmpCtrlNew(&task_compiler,"other",CCF_DONT_FREE_BUF);
    if(!cc || !other || I386COCPopNoFree(&heap,cc)) return 80;
    first=I386ICAdd(&heap,cc,0x0A,1,0);
    misc=I386COCMiscNew(&heap,cc,CMT_LABEL);
    if(!first || !misc) return 81;
    misc->use_cnt=1;
    saved=I386COCSave(&heap,cc);
    if(!saved || I386COCAppend(&heap,other,saved) || I386COCHeaderFree(&heap,other,saved) ||
        !I386COCAppend(&heap,cc,saved) || cc->coc.coc_head.next!=first ||
        first->last!=&cc->coc.coc_head.next || misc->last!=&cc->coc.coc_next_misc) return 82;
    if(!I386COCPush(&heap,cc) || I386COCHeaderFree(&heap,cc,cc->coc.coc_next) ||
        I386COCAppend(&heap,cc,cc->coc.coc_next)) return 83;
    COCSeed(&cc->coc);
    node=I386ICAdd(&heap,cc,0x0A,3,0); misc=I386COCMiscNew(&heap,cc,CMT_LABEL);
    if(!node || !misc) return 84;
    misc->use_cnt=3;
    //The original for-loop path copies its increment, pops it without freeing,
    //then restores the parent before compiling the body and appending increment.
    if(!I386COCPush(&heap,cc)) return 85;
    increment=I386COCPopNoFree(&heap,cc); parent=I386COCPopNoFree(&heap,cc);
    if(!increment || !parent || increment==parent || !I386COCHeaderFree(&heap,cc,parent) ||
        cc->coc.coc_head.next!=first) return 86;
    node=I386ICAdd(&heap,cc,0x0A,2,0); misc=I386COCMiscNew(&heap,cc,CMT_LABEL);
    if(!node || !misc) return 87;
    misc->use_cnt=2;
    if(!I386COCAppend(&heap,cc,increment)) return 88;
    sum=0; count=0;
    for(node=cc->coc.coc_head.next;node!=&cc->coc.coc_head.next;node=node->next) {
      if(++count>3 || node->next->last!=node || node->last->next!=node) return 89;
      sum=sum*10+node->ic_data;
    }
    if(sum!=123 || count!=3) return 90;
    sum=0; count=0;
    for(misc=cc->coc.coc_next_misc;misc!=&cc->coc.coc_next_misc;misc=misc->next) {
      if(++count>3 || misc->next->last!=misc || misc->last->next!=misc) return 91;
      sum=sum*10+misc->use_cnt;
    }
    if(sum!=123 || count!=3) return 92;
    //Header release leaves small holes. Exhaust all free spans, not just the
    //largest contiguous one, before checking allocation rollback.
    fill=0;
    for(size=8192;size>=8;size>>=1)
      while(block=I386HeapAlloc(&heap,size,FALSE)) { block(U8 **)[0]=fill; fill=block; }
    if(!fill || I386COCSave(&heap,cc) || I386COCPush(&heap,cc) ||
        cc->coc.coc_next || cc->coc.coc_head.next!=first) return 93;
    while(fill) {
      next=fill(U8 **)[0];
      if(!I386HeapFree(&heap,fill)) return 96;
      fill=next;
    }
    alias=I386COCSave(&heap,cc);
    if(!alias || !I386COCPush(&heap,cc)) return 94;
    //Discard every queue view without freeing its nodes. Owner cleanup must
    //still reclaim the allocations exactly once, including both copied headers.
    cc->coc.coc_next=0; COCSeed(&cc->coc);
    if(!I386CmpCtrlEnter(&heap,cc) || !I386CmpCtrlUnwind(&root,&root.next_cc) ||
        !I386CmpCtrlDel(&heap,other) || root.lifetime_refs || root.active_controls ||
        heap.used!=used || heap.allocations!=allocations || !I386HeapValid(&heap) ||
        (GetRFlags&0x200)!=(enabled*0x200)) return 95;
    SetRFlags(flags);
  }
  return 0;
}
