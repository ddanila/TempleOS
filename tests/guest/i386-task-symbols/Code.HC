//Native temporary IR graphs use shared initialization and legacy payload ownership.
I64 code_warnings,code_undefined;
U0 CodeLabel(U8 *context,CCmpCtrl *cc,U8 *name,Bool undefined)
{
  if(context!=&heap || !name || name[0]!='L' || root.lifetime_refs!=1) errors++;
  if(I386COCSave(&heap,cc) || I386CmpCtrlDel(&heap,cc)) errors++;
  I386SchedYield(&scheduler);
  if(undefined) code_undefined++; else code_warnings++;
}
U8 *CodeName()
{
  U8 *s=I386HeapAlloc(&heap,8,TRUE);
  if(s) s[0]='L';
  return s;
}
Bool CodePopulate(CCmpCtrl *cc)
{
  CIntermediateCode *ic;
  CCodeMisc *cm;
  CArrayDim *dim;
  CHashDefineStr *symbol;
  I64 type;
  cc->pass_trace=1; cc->lock_cnt=1; cc->last_line_num=0x100000002;
  ic=I386ICAdd(&heap,cc,0x1234000A,0x123456789ABCDEF0,0x1234,ICF_RES_NOT_USED);
  if(!ic || ic->ic_code!=0x0A || ic->ic_precedence!=0x1234 ||
      ic->ic_data!=0x123456789ABCDEF0 || ic->ic_line!=0x100000002 || ic->ic_class!=0x1234 ||
      ic->ic_flags!=(ICF_RES_NOT_USED|ICF_LOCK|ICF_PASS_TRACE) ||
      !(cc->flags&(1<<CCf_PASS_TRACE_PRESENT))) return FALSE;
  for(type=CMT_LABEL;type<=CMT_HASH_ENTRY;type++) {
    cm=I386COCMiscNew(&heap,cc,type);
    if(!cm || (cm->addr+0)(U32)!=0xFFFFFFFF || cm->use_cnt || cm->flags || cm->str || cm->h) return FALSE;
    cm->str=CodeName; if(!cm->str) return FALSE;
    switch(type) {
      case CMT_ASM_LABEL: cm->flags=CMF_DEFINED; break;
      case CMT_JMP_TABLE:
        cm->range=3; cm->jmp_table=I386HeapAlloc(&heap,3*sizeof(CCodeMisc *),TRUE);
        if(!cm->jmp_table) return FALSE;
        //References into the same graph are borrowed, not independently freed.
        cm->jmp_table[0]=cc->coc.coc_next_misc;
        break;
      case CMT_FLOAT_CONSTS:
        cm->num_consts=2; cm->float_consts=I386HeapAlloc(&heap,16,TRUE);
        if(!cm->float_consts) return FALSE;
        cm->float_consts(U64 *)[0]=0x3FF0000000000000;
        break;
      case CMT_ARRAY_DIM:
        cm->dim=I386HeapAlloc(&heap,sizeof(CArrayDim),TRUE);
        dim=I386HeapAlloc(&heap,sizeof(CArrayDim),TRUE);
        if(!cm->dim || !dim) return FALSE;
        cm->dim->next=dim; cm->dim->cnt=3; dim->cnt=2;
        break;
      case CMT_HASH_ENTRY:
        symbol=I386HeapAlloc(&heap,sizeof(CHashDefineStr),TRUE);
        if(!symbol) return FALSE;
        symbol->str=CodeName; symbol->data=CodeName; symbol->type=HTT_DEFINE_STR;
        if(!symbol->str || !symbol->data) return FALSE;
        cm->h=symbol;
        break;
    }
  }
  //A second undefined name must not leak the previous deferred diagnostic name.
  cm=I386COCMiscNew(&heap,cc,CMT_GOTO_LABEL);
  if(!cm || !(cm->str=CodeName)) return FALSE;
  return TRUE;
}
I64 CodeTest()
{
  CCmpCtrl *cc;
  CCodeCtrl *saved;
  CIntermediateCode *last;
  CCodeMisc *last_misc;
  U8 *fill;
  I64 used=heap.used,allocations=heap.allocations,base_used,base_allocations,i,enabled;
  U32 flags=GetRFlags;
  for(enabled=0;enabled<2;enabled++) {
    SetRFlags((flags&~0x200)|(enabled*0x200));
    code_warnings=0; code_undefined=0;
    cc=I386TaskCmpCtrlNew(&task_compiler,"IR",CCF_DONT_FREE_BUF);
    if(!cc || cc->coc.coc_head.next!=&cc->coc.coc_head.next ||
        cc->coc.coc_next_misc!=&cc->coc.coc_next_misc || cc->coc.coc_head.ic_code) return 60;
    base_used=heap.used; base_allocations=heap.allocations;
    if(!CodePopulate(cc)) return 61;
    last=cc->coc.coc_head.last; last_misc=cc->coc.coc_last_misc;
    cc->flags&=~CCF_DONT_FREE_BUF;
    cc->lex_include_stk->flags=LFSF_DOC; cc->lex_include_stk->doc=0x1234;
    if(I386CmpCtrlDel(&heap,cc) || root.lifetime_refs!=1 ||
        cc->coc.coc_head.last!=last || cc->coc.coc_last_misc!=last_misc) return 67;
    cc->flags|=CCF_DONT_FREE_BUF;
    cc->lex_include_stk->flags=0; cc->lex_include_stk->doc=0;
    if(!I386COCDiscard(&heap,cc,&CodeLabel,&heap) || code_warnings!=1 || code_undefined!=1 ||
        errors || heap.used!=base_used || heap.allocations!=base_allocations ||
        !I386COCDiscard(&heap,cc)) return 62;
    if(!CodePopulate(cc)) return 63;
    last=cc->coc.coc_head.last; last_misc=cc->coc.coc_last_misc;
    fill=I386HeapAlloc(&heap,heap.size-heap.used-16,FALSE);
    if(!fill || I386ICAdd(&heap,cc,0x0A,99,0) || I386COCMiscNew(&heap,cc,CMT_LABEL) ||
        cc->coc.coc_head.last!=last || cc->coc.coc_last_misc!=last_misc ||
        !I386HeapFree(&heap,fill)) return 64;
    if(!I386COCPush(&heap,cc)) return 65;
    saved=cc->coc.coc_next; COCSeed(&cc->coc);
    if(!CodePopulate(cc) || !I386COCDiscard(&heap,cc) || cc->coc.coc_next!=saved ||
        !CodePopulate(cc) || !I386CmpCtrlEnter(&heap,cc) || !I386CmpCtrlDrain(&root) ||
        root.lifetime_refs || root.active_controls || heap.used!=used || heap.allocations!=allocations ||
        !I386HeapValid(&heap) || (GetRFlags&0x200)!=(enabled*0x200)) return 66;
    SetRFlags(flags);
  }
  return 0;
}
