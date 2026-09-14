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
