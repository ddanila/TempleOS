U0 IdentSeed(CCmpCtrl *cc,CLexFile *file,U8 *input,I64 flags=0)
{
  U8 *bytes=cc; I64 i; U32 *bitmap=char_bmp_alpha_numeric;
  for(i=0;i<sizeof(CCmpCtrl);i++) bytes[i]=0;
  bytes=file; for(i=0;i<sizeof(CLexFile);i++) bytes[i]=0;
  if(flags&CCF_KEEP_AT_SIGN) bitmap=char_bmp_alpha_numeric_no_at;
  CmpCtrlSeed(cc,flags|CCF_DONT_FREE_BUF,0,bitmap);
  LexFileSeed(file,input); cc->lex_include_stk=file; cc->cur_buf_ptr=input;
}

U0 IdentZero(U8 *bytes,I64 size) { I64 i; for(i=0;i<size;i++) bytes[i]=0; }
U8 stream_input[114]={65,108,112,104,97,61,48,120,49,48,48,48,48,48,48,48,49,59,32,47,42,32,111,117,116,101,114,32,47,42,32,105,110,110,101,114,32,42,47,32,42,47,32,66,101,116,97,40,50,101,48,44,34,97,92,48,98,34,44,39,65,66,39,41,59,32,47,47,101,110,100,10,60,60,61,32,62,62,61,32,43,43,32,45,45,32,45,62,32,38,38,32,124,124,32,94,94,32,33,61,32,60,61,32,62,61,32,46,46,46,32,46,46,0};
I64 stream_tokens[27]={TK_IDENT,61,TK_I64,59,TK_IDENT,40,TK_F64,44,TK_STR,44,TK_CHAR_CONST,41,59,TK_SHL_EQU,TK_SHR_EQU,TK_PLUS_PLUS,TK_MINUS_MINUS,TK_DEREFERENCE,TK_AND_AND,TK_OR_OR,TK_XOR_XOR,TK_NOT_EQU,TK_LESS_EQU,TK_GREATER_EQU,TK_ELLIPSIS,TK_DOT_DOT,TK_EOF};
I64 StreamTest()
{
  CCmpCtrl cc; CLexFile file; I64 i,t,lines=0;
  IdentSeed(&cc,&file,stream_input);
  for(i=0;i<27;i++) {
    t=MacroNext(&cc,&lines);
    if(t!=stream_tokens[i]) return 300+i;
    if(i==0 && (StrCmp(cc.cur_str,"Alpha") || cc.cur_str_len!=6)) return 340;
    if(i==2 && cc.cur_i64!=0x100000001) return 341;
    if(i==4 && (StrCmp(cc.cur_str,"Beta") || cc.cur_str_len!=5)) return 342;
    if(i==6 && cc.cur_f64(U64)!=0x4000000000000000) return 343;
    if(i==8 && (cc.cur_str_len!=4 || cc.cur_str[0]!=97 || cc.cur_str[1] || cc.cur_str[2]!=98 || cc.cur_str[3])) return 344;
    if(i==10 && cc.cur_i64!=0x4241) return 345;
  }
  if(cc.lex_include_stk!=&file || !MacroTextFree(&cc)) return 346;
  return 0;
}
I64 ModeTest()
{
  CCmpCtrl cc; CLexFile file; I64 lines=0;
  IdentSeed(&cc,&file,"@a",CCF_KEEP_AT_SIGN);
  if(MacroNext(&cc,&lines)!=64 || MacroNext(&cc,&lines)!=TK_IDENT || StrCmp(cc.cur_str,"a") || !MacroTextFree(&cc)) return 350;
  IdentSeed(&cc,&file,"@a");
  if(MacroNext(&cc,&lines)!=TK_IDENT || StrCmp(cc.cur_str,"@a") || !MacroTextFree(&cc)) return 351;
  IdentSeed(&cc,&file,"'a';",CCF_NO_CHAR_CONST);
  if(MacroNext(&cc,&lines)!=TK_IDENT || StrCmp(cc.cur_str,"a") || MacroNext(&cc,&lines)!=59 || !MacroTextFree(&cc)) return 352;
  IdentSeed(&cc,&file,"#abc;",CCF_KEEP_SIGN_NUM);
  if(MacroNext(&cc,&lines)!=35 || MacroNext(&cc,&lines)!=TK_IDENT || StrCmp(cc.cur_str,"abc") || MacroNext(&cc,&lines)!=59 || !MacroTextFree(&cc)) return 353;
  IdentSeed(&cc,&file,"a\nb;",CCF_KEEP_NEW_LINES);
  if(MacroNext(&cc,&lines)!=TK_IDENT || cc.last_line_num!=1 || file.line_num!=2 || MacroNext(&cc,&lines)!=10 || MacroNext(&cc,&lines)!=TK_IDENT || StrCmp(cc.cur_str,"b") || cc.last_line_num!=2 || MacroNext(&cc,&lines)!=59 || !MacroTextFree(&cc)) return 354;
  return 0;
}
