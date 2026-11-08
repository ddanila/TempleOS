#include "/Compiler/I386/Control.HC"
I64 control_documents,control_code_labels;
I64 control_owned_documents;
U0 ControlOwnedDocument(U8 *context,CDoc *document)
{
  if(context!=&control_owned_documents || !document || document->doc_signature!=DOC_SIGNATURE_VAL)
    state_free_errors++;
  control_owned_documents++;StateFree(document);
}
CDoc *ControlNewDocument()
{
  CDoc *doc=StateAlloc(sizeof(CDoc));
  if(doc) {doc->doc_signature=DOC_SIGNATURE_VAL;doc->head.next=doc;}
  return doc;
}
U0 ControlCodeLabel(U8 *context,CCmpCtrl *cc,U8 *name,Bool undefined)
{
  if(context!=&control_code_labels || !undefined || !name || name[0]!='X' ||
      I386COCSave(&state_heap,cc) || I386CmpCtrlDel(&state_heap,cc) ||
      I386COCDiscard(&state_heap,cc)) state_free_errors++;
  control_code_labels++;
}
U0 ControlDocument(U8 *context,CDoc *document)
{
  if(context!=&control_documents || document!=0x1234) state_free_errors++;
  control_documents++;
}
U0 ControlZero(U8 *p,I64 size){while(size--)*p++=0;}
Bool ControlScopeTest()
{
  CI386Task task;CI386Scheduler scheduler;
  CI386TaskSymbols *scope=StateAlloc(sizeof(CI386TaskSymbols));
  CHashTable owned,first,second,detached;
  CCmpCtrl *cc;CIntermediateCode *retired,*live;CCodeMisc *misc;CCodeCtrl *saved;
  Bool valid=TRUE;
  ControlZero(&task,sizeof(task));ControlZero(&scheduler,sizeof(scheduler));
  ControlZero(&owned,sizeof(owned));ControlZero(&first,sizeof(first));
  ControlZero(&second,sizeof(second));ControlZero(&detached,sizeof(detached));
  if(!scope)return FALSE;
  task.owner=&scheduler;scheduler.current=&task;task.lifetime_refs=1;
  task.next_cc=task.last_cc=&task.next_cc;task.symbol_state=scope;task.hash_table=&owned;
  scope->task=&task;scope->heap=&state_heap;scope->table=&owned;
  scope->signature=I386_TASK_SYMBOLS_MAGIC;
  if(!I386CmpTaskOwnerValid(&task,&state_heap,&owned))valid=FALSE;
  first.next=&second;second.next=&owned;task.hash_table=&first;
  cc=I386CmpCtrlNew(&state_heap,"1",CCF_DONT_FREE_BUF,"Scope",&first,char_bmp_alpha_numeric,&task);
  if(!cc)valid=FALSE;
  else {
    if(!I386CmpCtrlEnter(&state_heap,cc) || !I386COCInit(&state_heap,cc))valid=FALSE;
    retired=I386ICAdd(&state_heap,cc,0x0A,1,0);
    live=I386ICAdd(&state_heap,cc,0x0A,2,0);
    misc=I386COCMiscNew(&state_heap,cc,CMT_ASM_LABEL);
    if(!retired || !live || !misc)valid=FALSE;
    else {
      misc->flags=CMF_DEFINED;live->t.arg1_tree=retired;
      if(!I386ICRetire(&state_heap,cc,retired) || !I386COCInstructionsRelease(&state_heap,cc) ||
          I386HeapSize(&state_heap,live)>=0 || I386HeapSize(&state_heap,retired)>=0 ||
          I386HeapSize(&state_heap,misc)<0 || cc->coc.coc_next_misc!=misc ||
          cc->coc.coc_head.next!=&cc->coc.coc_head.next || cc->coc.coc_head.last!=&cc->coc.coc_head.next ||
          !I386COCDiscard(&state_heap,cc) || I386HeapSize(&state_heap,retired)>=0 ||
          I386HeapSize(&state_heap,misc)>=0)valid=FALSE;
    }
    //An outer graph must keep its detached operands across inner emission.
    retired=I386ICAdd(&state_heap,cc,0x0A,3,0);live=I386ICAdd(&state_heap,cc,0x0A,4,0);
    if(!retired || !live)valid=FALSE;
    else {
      live->t.arg1_tree=retired;
      if(!I386ICRetire(&state_heap,cc,retired) || !I386COCPush(&state_heap,cc) ||
          !I386COCInit(&state_heap,cc) || !I386ICAdd(&state_heap,cc,0x0A,5,0) ||
          !I386COCInstructionsRelease(&state_heap,cc) || I386HeapSize(&state_heap,retired)<0 ||
          live->t.arg1_tree!=retired || !I386COCDiscard(&state_heap,cc) ||
          !(saved=I386COCPopNoFree(&state_heap,cc)) || !I386COCHeaderFree(&state_heap,cc,saved) ||
          !I386COCInstructionsRelease(&state_heap,cc) ||
          I386HeapSize(&state_heap,retired)>=0 || I386HeapSize(&state_heap,live)>=0 ||
          !I386COCDiscard(&state_heap,cc))valid=FALSE;
    }
    task.hash_table=&detached;
    if(I386CmpTaskOwnerValid(&task,&state_heap,&detached) || I386COCInit(&state_heap,cc))valid=FALSE;
    task.hash_table=&first;second.next=&first;
    if(I386CmpTaskOwnerValid(&task,&state_heap,&first) || I386COCInit(&state_heap,cc) ||
        I386CmpCtrlNew(&state_heap,"1",CCF_DONT_FREE_BUF,"Cycle",&first,char_bmp_alpha_numeric,&task))valid=FALSE;
    second.next=&owned;
    if(!I386CmpCtrlLeave(&state_heap,cc) || !I386CmpCtrlDel(&state_heap,cc))valid=FALSE;
  }
  if(scope->table!=&owned || task.hash_table!=&first || task.active_controls || task.lifetime_refs!=1)valid=FALSE;
  task.hash_table=&owned;scope->signature=0;
  if(I386CmpTaskOwnerValid(&task,&state_heap,&owned))valid=FALSE;
  StateFree(scope);
  return valid && !state_free_errors && !state_heap.used && !state_heap.allocations && I386HeapValid(&state_heap);
}
I64 NativeControlTest()
{
  CCmpCtrl *cc;
  CI386Heap small,foreign;
  U8 *source,*prompt;
  CLexHashTableContext *hash;
  CCodeMisc *misc;
  I64 size,i,successes=0,failures=0,used,lines=0;
  U32 flags=GetRFlags;
  if(!ControlScopeTest())return 108;
  for(size=24;size<=1024;size+=8) {
    if(!I386HeapInit(&small,0x61000,size)) return 70;
    cc=I386CmpCtrlNew(&small,"source",CCF_DONT_FREE_BUF,"C:/Name.HC",0,char_bmp_alpha_numeric);
    if(cc) {
      successes++;
      if(!I386CmpCtrlDel(&small,cc)) return 71;
    } else failures++;
    if(small.used || small.allocations || !I386HeapValid(&small)) return 72;
  }
  //Owned input stays with its caller if any later constructor allocation fails.
  for(size=48;size<=1024;size+=8) {
    if(!I386HeapInit(&small,0x61000,size) || !(source=I386HeapAlloc(&small,8,TRUE))) return 86;
    source[0]='X';
    cc=I386CmpCtrlNew(&small,source,0,"Owned",0,char_bmp_alpha_numeric);
    if(cc) {
      if(!I386CmpCtrlDel(&small,cc)) return 87;
    } else if(I386HeapSize(&small,source)!=8 || source[0]!='X' || !I386HeapFree(&small,source)) return 88;
    if(small.used || small.allocations || !I386HeapValid(&small)) return 89;
  }
  if(!successes || !failures || I386CmpCtrlNew(&state_heap,0,0,0,0,char_bmp_alpha_numeric) ||
      I386CmpCtrlNew(&state_heap,"borrowed",0,"name",0,char_bmp_alpha_numeric)) return 73;
  source=StateAlloc(17);
  if(!source) return 74;
  source[0]='X';
  cc=I386CmpCtrlNew(&state_heap,source,0,"C:/Root.HC",0x1234,char_bmp_alpha_numeric);
  if(!cc || cc->next!=cc || cc->last!=cc || cc->htc.glbl_hash_table!=0x1234 ||
      cc->next_stream_blk!=&cc->next_stream_blk || cc->last_stream_blk!=&cc->next_stream_blk ||
      cc->cur_buf_ptr!=source || cc->lex_include_stk->depth!=-1 ||
      cc->lex_include_stk->line_num!=1 || cc->char_bmp_alpha_numeric!=char_bmp_alpha_numeric) return 75;
  if(!I386LexPush(&state_heap,cc) || !I386LexIncludeCopy(&state_heap,cc,"Child","child") ||
      !I386LexPush(&state_heap,cc)) return 76;
  for(i=0;i<2;i++) {
    hash=StateAlloc(sizeof(CLexHashTableContext)); if(!hash) return 77;
    hash->next=cc->htc.next; cc->htc.next=hash;
  }
  cc->ps=StateAlloc(sizeof(CPrsStk)); cc->cur_str=StateAlloc(13);
  cc->cur_help_idx=StateAlloc(9); cc->dollar_buf=StateAlloc(7);
  if(!cc->ps || !cc->cur_str || !cc->cur_help_idx || !cc->dollar_buf ||
      !I386HeapInit(&foreign,0x62000,512) || I386CmpCtrlDel(&foreign,cc) ||
      !I386CmpCtrlDel(&state_heap,cc) || state_heap.used || state_heap.allocations) return 78;
  //Control teardown also releases sources detached by raw EOF under snapshots.
  cc=I386CmpCtrlNew(&state_heap,"Z",CCF_DONT_FREE_BUF,"Retained",0,char_bmp_alpha_numeric);
  if(!cc || !I386LexIncludeCopy(&state_heap,cc,"Outer","a",TRUE) ||
      !I386LexIncludeCopy(&state_heap,cc,"Inner","x",TRUE) ||
      !I386LexPush(&state_heap,cc) || !I386LexPush(&state_heap,cc) ||
      I386LexRawChar(&state_heap,cc,&lines)!='x' ||
      I386LexRawChar(&state_heap,cc,&lines)!='a' ||
      I386LexRawChar(&state_heap,cc,&lines)!='Z' ||
      !I386CmpCtrlDel(&state_heap,cc) || state_heap.used || state_heap.allocations ||
      !I386HeapValid(&state_heap)) return 103;
  //A missing document service rejects before changing the control or its graph.
  cc=I386CmpCtrlNew(&state_heap,0,0,"Document",0,char_bmp_alpha_numeric);
  if(!cc) return 79;
  cc->lex_include_stk->flags=LFSF_DOC; cc->lex_include_stk->doc=0x1234;
  used=state_heap.used;
  if(I386CmpCtrlDel(&state_heap,cc) || state_heap.used!=used ||
      !I386CmpCtrlDel(&state_heap,cc,&ControlDocument,&control_documents) || control_documents!=1) return 80;
  //Owned document children use their own cleanup, including under snapshots,
  //even when the control has no document callback or has a different one.
  for(i=0;i<2;i++) {
    CDoc *first,*second;
    cc=I386CmpCtrlNew(&state_heap,"P",CCF_DONT_FREE_BUF,"OwnedDocs",0,char_bmp_alpha_numeric);
    first=ControlNewDocument;second=ControlNewDocument;
    if(!cc || !first || !second ||
        !I386LexIncludeDocTake(&state_heap,cc,"First",first,&ControlOwnedDocument,&control_owned_documents) ||
        !I386LexIncludeDocTake(&state_heap,cc,"Second",second,&ControlOwnedDocument,&control_owned_documents) ||
        !I386LexPush(&state_heap,cc))return 104;
    if(i) {
      if(!I386CmpCtrlDel(&state_heap,cc,&ControlDocument,&control_documents))return 105;
    } else if(!I386CmpCtrlDel(&state_heap,cc))return 106;
    if(control_owned_documents!=2*(i+1) || control_documents!=1 || state_free_errors ||
        state_heap.used || state_heap.allocations || !I386HeapValid(&state_heap))return 107;
  }
  //Preserve public root-retention semantics, even for a generated prompt buffer.
  for(i=0;i<2;i++) {
    SetRFlags(flags|0x200);
    cc=I386CmpCtrlNew(&state_heap,0,CCF_PMT|(i*CCF_DONT_FREE_BUF),"Prompt",0,char_bmp_alpha_numeric);
    if(!cc || !(GetRFlags&0x200)) return 81;
    prompt=cc->cur_buf_ptr;
    for(size=0;size<8;size++) if(prompt[size]) return 82;
    if(!I386CmpCtrlDel(&state_heap,cc) || !(GetRFlags&0x200)) return 83;
    SetRFlags(flags);
    if(i && !I386HeapFree(&state_heap,prompt)) return 84;
    if(state_heap.used || state_heap.allocations || !I386HeapValid(&state_heap)) return 85;
  }
  for(i=0;i<2;i++) {
    SetRFlags((flags&~0x200)|(i*0x200));
    cc=I386CmpCtrlNew(&state_heap,"IR",CCF_DONT_FREE_BUF,"IR",0,char_bmp_alpha_numeric);
    if(!cc || !I386ICAdd(&state_heap,cc,0x0A,42,0)) return 100;
    misc=I386COCMiscNew(&state_heap,cc,CMT_GOTO_LABEL);
    if(!misc || !(misc->str=I386HeapAlloc(&state_heap,8,TRUE))) return 101;
    misc->str[0]='X';
    if(!I386COCPush(&state_heap,cc) ||
        !I386ICRetire(&state_heap,cc,cc->coc.coc_head.next) ||
        !I386COCDiscard(&state_heap,cc,&ControlCodeLabel,&control_code_labels) ||
        !I386CmpCtrlDel(&state_heap,cc) || control_code_labels!=i+1 || state_free_errors ||
        state_heap.used || state_heap.allocations || !I386HeapValid(&state_heap) ||
        (GetRFlags&0x200)!=(i*0x200)) return 102;
    SetRFlags(flags);
  }
  return state_free_errors;
}

#include "/Kernel/SymbolDelete.HC"
