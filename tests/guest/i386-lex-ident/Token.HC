I64 NativeTokenTest()
{
  CCmpCtrl cc; CLexFile parent; CI386Heap small; CHashTable table; CHash *bucket=0;
  CHashDefineStr macro; U8 input[146],*old; I64 ch,i,lines=0;
  input[0]='N'; input[1]='e'; input[2]='w'; input[3]=59; input[4]=0;
  IdentZero(&table,sizeof(CHashTable)); IdentZero(&macro,sizeof(CHashDefineStr));
  table.body=&bucket; macro.str="New"; macro.data="Other"; macro.type=HTT_DEFINE_STR; HashAdd(&macro,&table);
  if(!I386HeapInit(&small,0x50000,32)) return 160;
  old=I386HeapAlloc(&small,4,FALSE); if(!old) return 161;
  old[0]='O'; old[1]='l'; old[2]='d'; old[3]=0;
  for(i=0;i<2;i++) {
    IdentSeed(&cc,&parent,input); cc.cur_str=old; cc.cur_str_len=4; cc.token=77; cc.hash_entry=&macro;
    cc.htc.hash_table_lst=&table; if(!i) cc.flags|=CCF_NO_DEFINES;
    ch=I386LexRawChar(&small,&cc,&lines);
    if(I386LexIdentToken(&small,&cc,ch,"Macro",&lines)!=-1 || cc.cur_str!=old || cc.cur_str_len!=4 ||
        cc.token!=77 || cc.hash_entry!=&macro || StrCmp(old,"Old") || cc.lex_include_stk!=&parent ||
        small.allocations!=1 || !I386HeapValid(&small)) return 162+i;
  }
  if(!I386HeapFree(&small,old) || small.used || small.allocations) return 164;
  //Expansion retains the previous owned token until actual publication succeeds.
  IdentSeed(&cc,&parent,input); cc.htc.hash_table_lst=&table;
  old=I386HeapAlloc(&ident_heap,4,FALSE); if(!old) return 165;
  old[0]='O'; old[1]='l'; old[2]='d'; old[3]=0;
  cc.cur_str=old; cc.cur_str_len=4; cc.token=77;
  ch=I386LexRawChar(&ident_heap,&cc,&lines);
  if(I386LexIdentToken(&ident_heap,&cc,ch,"Macro",&lines)!=-2 || cc.cur_str!=old || cc.token!=77 ||
      cc.cur_str_len!=4 || ident_heap.allocations!=4 || !(cc.lex_include_stk->flags&LFSF_DEFINE)) return 166;
  ch=I386LexRawChar(&ident_heap,&cc,&lines);
  if(I386LexIdentToken(&ident_heap,&cc,ch,"Macro",&lines)!=TK_IDENT || StrCmp(cc.cur_str,"Other") ||
      cc.cur_str_len!=6 || ident_heap.allocations!=1 || cc.lex_include_stk!=&parent ||
      !MacroTextFree(&cc) || ident_heap.used) return 167;
  //An overlength scan fails before publication and before reading its delimiter.
  for(i=0;i<144;i++) input[i]='a'; input[144]=59; input[145]=0;
  IdentSeed(&cc,&parent,input); cc.token=77;
  ch=I386LexRawChar(&ident_heap,&cc,&lines);
  if(I386LexIdentToken(&ident_heap,&cc,ch,0,&lines)!=-3 || cc.token!=77 || cc.cur_str ||
      cc.cur_buf_ptr!=input+144 || ident_heap.used) return 168;
  return 0;
}
