//A source initializer may finish inside a macro while parser save points live.
I64 NativeSnapshotBoundaryTest()
{
  CCmpCtrl cc;
  CLexFile *root,*macro;
  U8 *bytes=&cc;
  I64 i,lines=0,used=state_heap.used,allocations=state_heap.allocations;
  for(i=0;i<sizeof(CCmpCtrl);i++) bytes[i]=0;
  CmpCtrlSeed(&cc,CCF_DONT_FREE_BUF,0,0);
  root=I386LexFilePush(&state_heap,&cc);
  if(!root) return 700;
  root->buf=root->buf_ptr=root->line_start=";R";
  root->line_num=1;cc.cur_buf_ptr=root->buf;
  if(!I386LexIncludeCopy(&state_heap,&cc,"Macro","{1}",TRUE)) return 701;
  macro=cc.lex_include_stk;
  if(InputRead(&cc,&lines)!='{' || !I386LexPush(&state_heap,&cc)) return 702;
  if(InputRead(&cc,&lines)!='1' || InputRead(&cc,&lines)!='}' ||
      InputRead(&cc,&lines)!=';') return 703;
  //Direct destruction still cannot invalidate a save point or its parents.
  if(I386LexFilePop(&state_heap,&cc)) return 704;
  if(!I386LexPop(&state_heap,&cc) || cc.lex_include_stk!=macro ||
      InputRead(&cc,&lines)!='1' || InputRead(&cc,&lines)!='}' ||
      InputRead(&cc,&lines)!=';' || InputRead(&cc,&lines)!='R') return 705;
  if(!I386LexFilePop(&state_heap,&cc) || cc.lex_include_stk || cc.lex_prs_stk ||
      state_heap.used!=used || state_heap.allocations!=allocations ||
      !I386HeapValid(&state_heap)) return 706;
  return 0;
}

I64 NativeSnapshotNestedTest()
{
  CCmpCtrl cc,other;
  CLexFile *root,*outer,*inner;
  CI386LexSnapshot *snapshot;
  CI386LexSavedFile *saved;
  CLexFile *saved_active,*parent_next;
  CI386LexSavedFile *saved_head;
  U8 *later;
  CI386HeapBlock *later_block;
  U32 irq;
  U8 *bytes=&cc;
  I64 i,lines=0,used=state_heap.used,count=state_heap.allocations;
  for(i=0;i<sizeof(CCmpCtrl);i++) bytes[i]=0;
  CmpCtrlSeed(&cc,CCF_DONT_FREE_BUF,0,0);
  root=I386LexFilePush(&state_heap,&cc); if(!root) return 710;
  LexFileSeed(root,"Z"); cc.cur_buf_ptr=root->buf;
  if(!I386LexIncludeCopy(&state_heap,&cc,"Outer","ab",TRUE)) return 711;
  outer=cc.lex_include_stk;
  if(!I386LexIncludeCopy(&state_heap,&cc,"Inner","xy",TRUE)) return 712;
  inner=cc.lex_include_stk;
  if(!I386LexPush(&state_heap,&cc) || InputRead(&cc,&lines)!='x' ||
      !I386LexPush(&state_heap,&cc) || InputRead(&cc,&lines)!='y' ||
      InputRead(&cc,&lines)!='a' || InputRead(&cc,&lines)!='b' ||
      InputRead(&cc,&lines)!='Z' || cc.lex_include_stk!=root) return 713;
  //Reject a mismatched parent link and preserve both interrupt states.
  snapshot=cc.lex_prs_stk; saved=snapshot->parents;
  if(!saved || !I386LexSnapshotValid(&state_heap,&cc,snapshot)) return 726;
  saved_active=saved->active; saved->active=inner;
  irq=GetRFlags; I386IrqSave;
  if(I386LexSnapshotValid(&state_heap,&cc,snapshot) || GetRFlags&0x200) return 727;
  SetRFlags(irq|0x200);
  if(I386LexSnapshotValid(&state_heap,&cc,snapshot) || !(GetRFlags&0x200)) return 728;
  I386IrqRestore(irq); saved->active=saved_active;
  //A forged block header inside a live allocation is not a saved-file record.
  later=I386HeapAllocHigh(&state_heap,sizeof(CI386LexFile)+16,TRUE);
  if(!later) return 732;
  later_block=later;later_block->span=sizeof(CI386LexSavedFile)+16;
  later_block->requested=sizeof(CI386LexSavedFile);later_block->tag=I386_HEAP_USED;
  saved_head=snapshot->parents;snapshot->parents=later+16;
  if(I386LexSnapshotValid(&state_heap,&cc,snapshot)) return 733;
  snapshot->parents=saved_head;
  //Nor can an interior pointer masquerade as the next active file.
  later_block->span=sizeof(CI386LexFile)+16;later_block->requested=sizeof(CI386LexFile);
  parent_next=snapshot->active->next;saved_active=saved->active;
  snapshot->active->next=later+16;saved->active=later+16;
  if(I386LexSnapshotValid(&state_heap,&cc,snapshot)) return 734;
  snapshot->active->next=parent_next;saved->active=saved_active;
  //Snapshot creation must reject a forged parent without changing its state.
  parent_next=inner->next;inner->next=later+16;cc.lex_include_stk=inner;
  i=state_heap.used;
  if(I386LexPush(&state_heap,&cc) || cc.lex_prs_stk!=snapshot ||
      cc.lex_include_stk!=inner || state_heap.used!=i) return 736;
  inner->next=parent_next;cc.lex_include_stk=root;
  if(!I386HeapFree(&state_heap,later)) return 735;
  //A later corrupt allocation must invalidate an earlier matching snapshot.
  later=I386HeapAllocHigh(&state_heap,32);
  if(!later || later<=(snapshot+0)(U8 *)) return 729;
  later_block=later-16; later_block->reserved=1;
  if(I386LexSnapshotValid(&state_heap,&cc,snapshot)) return 730;
  later_block->reserved=0;
  if(!I386LexSnapshotValid(&state_heap,&cc,snapshot) ||
      !I386HeapFree(&state_heap,later)) return 731;
  //Corrupt ownership in a deeper save point must reject before mutation.
  snapshot=cc.lex_prs_stk->next; snapshot->control=&other;
  i=state_heap.used;
  if(I386LexPop(&state_heap,&cc) || cc.lex_include_stk!=root ||
      state_heap.used!=i) return 714;
  snapshot->control=&cc;
  i=state_heap.used;
  if(I386LexIncludeTake(&state_heap,&cc,"Alias",inner->buf) ||
      I386LexIncludeTake(&state_heap,&cc,"Alias",outer->buf) ||
      cc.lex_include_stk!=root || state_heap.used!=i) return 719;
  if(!I386LexPop(&state_heap,&cc) || cc.lex_include_stk!=inner ||
      InputRead(&cc,&lines)!='y' || InputRead(&cc,&lines)!='a' ||
      InputRead(&cc,&lines)!='b' || InputRead(&cc,&lines)!='Z') return 715;
  if(!I386LexPop(&state_heap,&cc) || cc.lex_include_stk!=inner ||
      InputRead(&cc,&lines)!='x' || InputRead(&cc,&lines)!='y' ||
      InputRead(&cc,&lines)!='a' || InputRead(&cc,&lines)!='b' ||
      InputRead(&cc,&lines)!='Z' || !I386LexFilePop(&state_heap,&cc) ||
      state_heap.used!=used || state_heap.allocations!=count) return 716;
  //Discard all save points after crossing two source boundaries; free once.
  root=I386LexFilePush(&state_heap,&cc); if(!root) return 717;
  LexFileSeed(root,"Z"); cc.cur_buf_ptr=root->buf;
  if(!I386LexIncludeCopy(&state_heap,&cc,"Outer","a",TRUE) ||
      !I386LexIncludeCopy(&state_heap,&cc,"Inner","x",TRUE) ||
      !I386LexPush(&state_heap,&cc) || !I386LexPush(&state_heap,&cc) ||
      InputRead(&cc,&lines)!='x' || InputRead(&cc,&lines)!='a' ||
      InputRead(&cc,&lines)!='Z' || !I386LexPop(&state_heap,&cc,FALSE) ||
      !I386LexPop(&state_heap,&cc,FALSE) || cc.lex_include_stk!=root ||
      !I386LexFilePop(&state_heap,&cc) || state_heap.used!=used ||
      state_heap.allocations!=count || !I386HeapValid(&state_heap)) return 718;
  return 0;
}

I64 NativeSnapshotAllocationTest()
{
  CCmpCtrl cc;
  CI386Heap small;
  CLexFile *root,*macro;
  U8 *bytes=&cc,*position;
  I64 i,size,used,count,failures=0,successes=0;
  for(size=256;size<=512;size+=8) {
    for(i=0;i<sizeof(CCmpCtrl);i++) bytes[i]=0;
    CmpCtrlSeed(&cc,CCF_DONT_FREE_BUF,0,0);
    if(!I386HeapInit(&small,0x61000,size) ||
        !(root=I386LexFilePush(&small,&cc))) return 720;
    LexFileSeed(root,"Z"); cc.cur_buf_ptr=root->buf;
    if(!I386LexIncludeCopy(&small,&cc,"M","xy",TRUE)) return 721;
    macro=cc.lex_include_stk;
    cc.flags|=CCF_USE_LAST_U16; cc.last_U16='Q';
    position=cc.cur_buf_ptr; used=small.used; count=small.allocations;
    if(I386LexPush(&small,&cc)) {
      successes++;
      if(!I386LexPop(&small,&cc,FALSE)) return 722;
    } else {
      failures++;
      if(cc.lex_prs_stk || cc.lex_include_stk!=macro ||
          cc.cur_buf_ptr!=position || cc.last_U16!='Q' ||
          cc.flags!=(CCF_DONT_FREE_BUF|CCF_USE_LAST_U16) ||
          macro->last_U16 || small.used!=used || small.allocations!=count) return 723;
    }
    if(!I386LexFilePop(&small,&cc) || !I386LexFilePop(&small,&cc) ||
        small.used || small.allocations || !I386HeapValid(&small)) return 724;
  }
  if(!failures || !successes) return 725;
  return 0;
}
