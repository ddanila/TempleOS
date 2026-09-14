I64 IncludeCase(U8 *source,I64 count,I64 a,I64 b=0,I64 c=0,I64 d=0,I64 e=0)
{
  CCmpCtrl cc; CLexFile file; CHashTable table; CHash *bucket=0,*entry;
  CHashDefineStr macro; I64 lines=0,i,token,wanted[5];
  wanted[0]=a; wanted[1]=b; wanted[2]=c; wanted[3]=d; wanted[4]=e;
  IdentZero(&table,sizeof(CHashTable)); IdentZero(&macro,sizeof(CHashDefineStr));
  table.body=&bucket; table.next=ConditionalKeywords;
  macro.str="IncludePath"; macro.type=HTT_DEFINE_STR; macro.data="\"T:/First.HC\""; macro.cnt=-1;
  HashAdd(&macro,&table);
  IdentSeed(&cc,&file,source);
  cc.htc.hash_table_lst=cc.htc.define_hash_table=cc.htc.glbl_hash_table=cc.htc.local_hash_table=&table;
  IncludePrepare;
  for(i=0;i<count;i++) {
    token=IncludeNext(&cc,&lines);
    if(wanted[i]<0) { if(token!=-wanted[i]) return 1; }
    else if(token!=TK_I64 || cc.cur_i64!=wanted[i]) return 2;
  }
  if(IncludeNext(&cc,&lines)!=TK_EOF || cc.lex_include_stk!=&file || !ConditionalFree(&cc)) return 3;
  while(entry=bucket) {
    bucket=entry->next; entry->next=0;
    if(entry!=&macro && !IncludeSymbolFree(entry)) return 4;
  }
  return 0;
}
I64 IncludeTest()
{
  if(IncludeCase("#include \"T:/First.HC\" IncludeValue 99",5,11,22,13,42,99) || !IncludeLoads(2)) return 170;
  if(IncludeCase("#include IncludePath 99",4,11,22,13,99) || !IncludeLoads(2)) return 171;
  if(IncludeCase("#include \"T:/First.HC\"; 99",5,11,22,13,-59,99) || !IncludeLoads(2)) return 172;
  if(IncludeCase("#ifdef Missing #include \"T:/Never.HC\" #else #include \"T:/Empty.HC\" 8 #endif 9",2,8,9) || !IncludeLoads(1)) return 173;
  if(IncludeCase("#include #include \"T:/Name.HC\" 99",2,22,99) || !IncludeLoads(2)) return 174;
  if(IncludeCase("#include 7 9",2,7,9) || !IncludeLoads(0)) return 175;
  if(IncludeCase("#include \"T:/Empty.HC\" 9",1,9) || !IncludeLoads(1)) return 176;
  if(IncludeCase("#ifdef Missing #ifdef Missing #include \"T:/Never.HC\" #endif #else #include \"T:/Second.HC\" #endif 9",2,22,9) || !IncludeLoads(1)) return 177;
  return 0;
}
