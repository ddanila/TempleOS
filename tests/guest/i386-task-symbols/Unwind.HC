//Explicit boundaries preserve enclosing compilation, even with deferred documents.
I64 unwind_documents;
U32 unwind_flags;
U0 UnwindDocument(U8 *context,CDoc *document)
{
  if(context!=&root || !root.compiler_busy || !root.lifetime_refs ||
      (GetRFlags&0x200)!=unwind_flags || I386TaskCmpCtrlNew(&task_compiler) ||
      I386CmpCtrlUnwind(&root,root.last_cc)) errors++;
  unwind_documents=unwind_documents*10+(document+0)(U32);
  I386SchedYield(&scheduler);
}
I64 UnwindRootTest()
{
  CCmpCtrl *outer,*inner,*missing,*detached;
  I64 used=heap.used,allocations=heap.allocations,enabled,suffix_used,suffix_allocations;
  U32 flags=GetRFlags;
  for(enabled=0;enabled<2;enabled++) {
    unwind_flags=enabled*0x200; unwind_documents=0;
    SetRFlags((flags&~0x200)|unwind_flags);
    outer=I386TaskCmpCtrlNew(&task_compiler);
    inner=I386TaskCmpCtrlNew(&task_compiler);
    missing=I386TaskCmpCtrlNew(&task_compiler);
    detached=I386TaskCmpCtrlNew(&task_compiler,"detached",CCF_DONT_FREE_BUF);
    if(!outer || !inner || !missing || !detached) return 50;
    outer->lex_include_stk->flags=LFSF_DOC; outer->lex_include_stk->doc=9;
    inner->lex_include_stk->flags=LFSF_DOC; inner->lex_include_stk->doc=2;
    missing->lex_include_stk->flags=LFSF_DOC; missing->lex_include_stk->doc=3;
    if(!I386CmpCtrlEnter(&heap,outer) || !I386CmpCtrlEnter(&heap,missing) ||
        !I386CmpCtrlEnter(&heap,inner,&UnwindDocument,&root)) return 51;
    suffix_used=heap.used; suffix_allocations=heap.allocations;
    if(I386CmpCtrlUnwind(&root,0) || I386CmpCtrlUnwind(&root,detached) ||
        I386CmpCtrlUnwind(&root,outer) || unwind_documents || root.active_controls!=3 ||
        root.lifetime_refs!=4 || root.last_cc!=inner || outer->next!=missing ||
        heap.used!=suffix_used || heap.allocations!=suffix_allocations) return 52;
    if(!I386CmpCtrlDel(&heap,missing,&UnwindDocument,&root) || unwind_documents!=3 ||
        !I386CmpCtrlUnwind(&root,outer) || unwind_documents!=32 || errors ||
        root.next_cc!=outer || root.last_cc!=outer || root.active_controls!=1 ||
        root.lifetime_refs!=2 || !I386CmpCtrlUnwind(&root,outer) ||
        I386CmpCtrlDrain(&root) || I386CmpCtrlUnwind(&root,detached)) return 53;
    if(!I386CmpCtrlDel(&heap,detached) || root.lifetime_refs!=1 ||
        !I386CmpCtrlDel(&heap,outer,&UnwindDocument,&root) || unwind_documents!=329 || errors ||
        root.active_controls || root.lifetime_refs || root.compiler_cleanup_failed || root.compiler_busy ||
        !I386CmpCtrlUnwind(&root,&root.next_cc) || heap.used!=used ||
        heap.allocations!=allocations || !I386HeapValid(&heap) ||
        (GetRFlags&0x200)!=unwind_flags) return 54;
    SetRFlags(flags);
  }
  return 0;
}
