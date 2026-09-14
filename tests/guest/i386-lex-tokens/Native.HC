I64 NativeTest()
{
  CCmpCtrl cc; CLexFile file; CI386Heap scratch; U8 *old; I64 lines=0,i; U8 input[150];
  IdentSeed(&cc,&file,"#abc"); cc.token=77;
  if(MacroNext(&cc,&lines)!=-4 || cc.token!=77 || cc.cur_buf_ptr!=file.buf+1) return 360;
  for(i=0;i<144;i++) input[i]=97; input[144]=59; input[145]=0;
  IdentSeed(&cc,&file,input);
  if(MacroNext(&cc,&lines)!=-3) return 361;
  IdentSeed(&cc,&file,"'123456789'");
  if(MacroNext(&cc,&lines)!=-5) return 362;
  IdentSeed(&cc,&file,"a",CCF_PMT);
  if(MacroNext(&cc,&lines)!=-1) return 363;
  IdentSeed(&cc,&file,";"); cc.last_U16=TK_INS_BIN; cc.flags|=CCF_USE_LAST_U16;
  if(MacroNext(&cc,&lines)!=TK_INS_BIN || MacroNext(&cc,&lines)!=59 || MacroNext(&cc,&lines)!=TK_EOF) return 364;
  IdentSeed(&cc,&file,""); cc.last_U16=TK_TKS_NUM+1; cc.flags|=CCF_USE_LAST_U16;
  if(MacroNext(&cc,&lines)!=-1) return 365;
  IdentSeed(&cc,&file,";"); cc.last_U16=TK_INS_BIN_SIZE; cc.flags|=CCF_USE_LAST_U16;
  if(MacroNext(&cc,&lines)!=TK_INS_BIN_SIZE || MacroNext(&cc,&lines)!=59 || MacroNext(&cc,&lines)!=TK_EOF) return 366;
  if(!I386HeapInit(&scratch,0x70000,32)) return 367;
  old=I386HeapAlloc(&scratch,4); if(!old) return 368;
  old[0]=79; old[1]=108; old[2]=100; old[3]=0;
  IdentSeed(&cc,&file,"New;"); cc.cur_str=old; cc.cur_str_len=4; cc.token=77;
  if(I386LexNext(&scratch,&cc,&token_tables,"Macro",&lines)!=-1 || cc.cur_str!=old ||
      cc.cur_str_len!=4 || cc.token!=77 || StrCmp(old,"Old")) return 369;
  IdentSeed(&cc,&file,"\"new\";"); cc.cur_str=old; cc.cur_str_len=4; cc.token=77;
  if(I386LexNext(&scratch,&cc,&token_tables,"Macro",&lines)!=-1 || cc.cur_str!=old ||
      cc.cur_str_len!=4 || cc.token!=77 || StrCmp(old,"Old")) return 370;
  if(!I386HeapFree(&scratch,old) || scratch.used || scratch.allocations || !I386HeapValid(&scratch)) return 371;
  return 0;
}
