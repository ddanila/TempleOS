I64 ConditionalCase(U8 *source,I64 first,I64 second,I64 flags=0,Bool local=FALSE)
{
  CCmpCtrl cc; CLexFile file; CHashTable table; CHash *bucket=0; CHashGeneric symbol;
  CHashClass scope; CMemberLst member; I64 lines=0,result=0;
  IdentZero(&table,sizeof(CHashTable)); IdentZero(&symbol,sizeof(CHashGeneric));
  IdentZero(&scope,sizeof(CHashClass)); IdentZero(&member,sizeof(CMemberLst));
  table.body=&bucket; table.next=ConditionalKeywords;
  symbol.str="Exists"; symbol.type=HTT_GLBL_VAR; HashAdd(&symbol,&table);
  IdentSeed(&cc,&file,source,flags); cc.htc.hash_table_lst=&table;
  if(local) { member.str="Exists"; scope.member_lst_and_root=&member; cc.htc.local_var_lst=&scope; }
  if(ConditionalNext(&cc,&lines)!=TK_I64 || cc.cur_i64!=first ||
      ConditionalNext(&cc,&lines)!=TK_I64 || cc.cur_i64!=second || ConditionalNext(&cc,&lines)!=TK_EOF ||
      cc.flags&CCF_NO_DEFINES) result=1;
  if(!ConditionalFree(&cc)) return 2;
  return result;
}
I64 ConditionalTest()
{
  if(ConditionalCase("#ifdef Exists 1 #else 2 #endif 3",1,3)) return 100;
  if(ConditionalCase("#ifdef Missing 1 #else 2 #endif 3",2,3)) return 101;
  if(ConditionalCase("#ifndef Exists 1 #else 2 #endif 3",2,3)) return 102;
  if(ConditionalCase("#ifndef Missing 1 #else 2 #endif 3",1,3)) return 103;
  if(ConditionalCase("#ifdef Missing 1 #ifdef Exists 2 #else 4 #endif #else 5 #endif 6",5,6)) return 104;
  if(ConditionalCase("#ifdef Exists #ifndef Missing 1 #else 2 #endif #else 3 #endif 4",1,4)) return 105;
  if(ConditionalCase("#ifdef Missing #if 1 2 #endif #else 3 #endif 4",3,4)) return 106;
  if(ConditionalCase("#else 1 #ifdef Exists 2 #endif #endif 3 4",3,4)) return 107;
  if(ConditionalCase("#endif 3 4",3,4)) return 108;
  if(ConditionalCase("#ifaot 1 #else 2 #endif 3",2,3)) return 109;
  if(ConditionalCase("#ifaot 1 #else 2 #endif 3",1,3,CCF_AOT_COMPILE)) return 110;
  if(ConditionalCase("#ifjit 1 #else 2 #endif 3",1,3)) return 111;
  if(ConditionalCase("#ifjit 1 #else 2 #endif 3",2,3,CCF_AOT_COMPILE)) return 112;
  if(ConditionalCase("#ifdef Missing // #else\n7 #endif 8",7,8)) return 113;
  if(ConditionalCase("#ifdef 7 8",7,8)) return 114;
  if(ConditionalCase("#ifndef 7 8",7,8)) return 115;
  if(ConditionalCase("#ifdef Exists 1 #else 2 #endif 3",2,3,0,TRUE)) return 116;
  return 0;
}
I64 ConditionalMarker(U8 *source,I64 token)
{
  CCmpCtrl cc; CLexFile file; I64 lines=0,result=0;
  IdentSeed(&cc,&file,source,CCF_IN_IF); cc.htc.hash_table_lst=ConditionalKeywords;
  if(ConditionalNext(&cc,&lines)!=token || cc.last_U16!=32 || !(cc.flags&CCF_USE_LAST_U16) ||
      ConditionalNext(&cc,&lines)!=TK_I64 || cc.cur_i64!=9 || ConditionalNext(&cc,&lines)!=TK_EOF ||
      !(cc.flags&CCF_IN_IF)) result=1;
  if(!ConditionalFree(&cc)) return 2;
  return result;
}
I64 ConditionalEdgeTest()
{
  CCmpCtrl cc; CLexFile file; I64 lines=0;
  if(ConditionalMarker("#if 9",TK_IF)) return 120;
  if(ConditionalMarker("#ifdef 9",TK_IFDEF)) return 121;
  if(ConditionalMarker("#ifndef 9",TK_IFNDEF)) return 122;
  if(ConditionalMarker("#ifaot 9",TK_IFAOT)) return 123;
  if(ConditionalMarker("#ifjit 9",TK_IFAOT)) return 124;
  if(ConditionalMarker("#else 9",TK_ELSE)) return 125;
  if(ConditionalMarker("#endif 9",TK_ENDIF)) return 126;
  IdentSeed(&cc,&file,"#ifdef Missing 1"); cc.htc.hash_table_lst=ConditionalKeywords;
  if(ConditionalNext(&cc,&lines)!=TK_EOF || !ConditionalFree(&cc)) return 127;
  IdentSeed(&cc,&file,"#ifdef Missing \"#else\" 7 #endif 8"); cc.htc.hash_table_lst=ConditionalKeywords;
  if(ConditionalNext(&cc,&lines)!=TK_STR || StrCmp(cc.cur_str," 7 #endif 8") ||
      ConditionalNext(&cc,&lines)!=TK_EOF || !ConditionalFree(&cc)) return 128;
  return 0;
}
