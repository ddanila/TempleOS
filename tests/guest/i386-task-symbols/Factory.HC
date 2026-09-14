I64 factory_documents;
U0 FactoryDocument(U8 *context,CDoc *document)
{
  if(context!=&factory_documents || document!=0x1234 || root.lifetime_refs!=1 ||
      I386TaskSymbolsDestroy(&root)) errors++;
  factory_documents++;
}
Bool FactoryName(U8 *a,U8 *b)
{
  while(*a && *a==*b) { a++; b++; }
  return *a==*b;
}
I64 FactoryRootTest()
{
  CCmpCtrl *cc;
  U8 *source,*fill;
  I64 used=heap.used,allocations=heap.allocations;
  control_services.version=I386_COMPILER_SERVICES_VERSION-1;
  control_services.bytes=sizeof(CI386CompilerServices);
  control_services.control_enter=&I386CmpCtrlEnter; control_services.control_leave=&I386CmpCtrlLeave;
  control_services.control_drain=&I386CmpCtrlDrain;
  control_services.control_new=&I386CmpCtrlNew; control_services.control_del=&I386CmpCtrlDel;
  if(I386TaskCmpCtrlNew(&task_compiler) ||
      I386TaskCompilerInit(&task_compiler,&control_services,"~/Tmp.DD.Z",char_bmp_alpha_numeric,char_bmp_alpha_numeric_no_at)) return 20;
  control_services.version=I386_COMPILER_SERVICES_VERSION;
  if(!I386TaskCompilerInit(&task_compiler,&control_services,"~/Tmp.DD.Z",char_bmp_alpha_numeric,char_bmp_alpha_numeric_no_at) ||
      I386TaskCompilerInit(&task_compiler,&control_services,"other",char_bmp_alpha_numeric,char_bmp_alpha_numeric_no_at)) return 21;
  cc=I386TaskCmpCtrlNew(&task_compiler,"source",CCF_DONT_FREE_BUF);
  if(!cc || !FactoryName(cc->lex_include_stk->full_name,"~/Tmp.DD.Z") ||
      cc->char_bmp_alpha_numeric!=char_bmp_alpha_numeric || cc->htc.glbl_hash_table!=symbols ||
      root.lifetime_refs!=1 || I386TaskSymbolsDestroy(&root) || !I386CmpCtrlDel(&heap,cc) || root.lifetime_refs) return 22;
  source=I386HeapAlloc(&heap,8,TRUE);
  if(!source) return 23;
  source[0]='X';
  fill=I386HeapAlloc(&heap,heap.size-heap.used-16,FALSE);
  if(!fill || I386TaskCmpCtrlNew(&task_compiler,source,0,"Fail.HC") ||
      I386HeapSize(&heap,source)!=8 || source[0]!='X' || root.lifetime_refs ||
      !I386HeapFree(&heap,fill)) return 24;
  cc=I386TaskCmpCtrlNew(&task_compiler,source);
  if(!cc || root.lifetime_refs!=1 || !I386CmpCtrlDel(&heap,cc) || root.lifetime_refs ||
      I386HeapSize(&heap,source)!=-1) return 27;
  cc=I386TaskCmpCtrlNew(&task_compiler);
  if(!cc) return 28;
  cc->lex_include_stk->flags=LFSF_DOC; cc->lex_include_stk->doc=0x1234;
  if(I386CmpCtrlDel(&heap,cc) || root.lifetime_refs!=1 ||
      !I386CmpCtrlDel(&heap,cc,&FactoryDocument,&factory_documents) || root.lifetime_refs || factory_documents!=1) return 29;
  root.lifetime_refs=0xFFFFFFFF;
  if(I386TaskCmpCtrlNew(&task_compiler,"source",CCF_DONT_FREE_BUF) || heap.used!=used || heap.allocations!=allocations) return 25;
  root.lifetime_refs=0;
  if(heap.used!=used || heap.allocations!=allocations || !I386HeapValid(&heap)) return 26;
  return 0;
}
Bool FactoryWorkerTest(I64 id)
{
  U32 irq=GetRFlags;
  I64 flags=CCF_DONT_FREE_BUF;
  U8 *expected="C:/Entry.HC";
  U32 *bitmap=char_bmp_alpha_numeric;
  CCmpCtrl *cc;
  if(I386TaskCompilerInit(&other_compiler,&control_services,"bad",char_bmp_alpha_numeric,char_bmp_alpha_numeric_no_at)) return FALSE;
  if(id) {
    if(!I386TaskFilesSet(I386TaskSelf,"/Child",'D')) return FALSE;
    flags|=CCF_KEEP_AT_SIGN; expected="D:/Child/Entry.HC"; bitmap=char_bmp_alpha_numeric_no_at;
  }
  SetRFlags(irq|0x200);
  cc=I386TaskCmpCtrlNew(&task_compiler,"source",flags,"Entry.HC");
  if(!cc || !(GetRFlags&0x200) || !FactoryName(cc->lex_include_stk->full_name,expected) ||
      cc->char_bmp_alpha_numeric!=bitmap || cc->htc.glbl_hash_table!=I386TaskSelf->hash_table ||
      I386TaskSelf->lifetime_refs!=1) return FALSE;
  if(id) {
    if(!I386CmpCtrlDel(I386TaskSelf->memory,cc) || !(GetRFlags&0x200) || I386TaskSelf->lifetime_refs) return FALSE;
  } else retained_control=cc;
  SetRFlags(irq);
  return TRUE;
}
