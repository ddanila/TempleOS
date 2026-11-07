public extern I64 PXLate(I64 value);
U0 PXLifeLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 PXLifeCheck()
{
  CCmpCtrl *cc=CmpCtrlNew(StrNew("PXLate(5);"));
  U8 *code,*s;I64 type,mask=0,*result;
  Lex(cc);code=LexExpression2Bin(cc,&type);
  if(code && type==RT_I64 && cc->token==';' && !cc->error_cnt && !cc->warning_cnt)mask|=1;
  CmpCtrlDel(cc);
  try{Call(code);}catch{if(Fs->except_ch=='UndefExt')mask|=2;Fs->catch_except=TRUE;}
  ExePutS("I64 PXLate(I64 value){return value+37;}");
  try{if(Call(code)==42)mask|=4;}catch{Fs->catch_except=TRUE;}
  Free(code);
  cc=CmpCtrlNew(StrNew("PXLate(6);"));Lex(cc);
  if(LexExpressionI64(cc)==43 && cc->token==';' && !cc->error_cnt && !cc->warning_cnt)mask|=8;
  CmpCtrlDel(cc);
  result=MAlloc(8);*result=mask;
  s=MStrPrint("EXPORT public-expression-lifetime-mask.bin %X 8\n",result);PXLifeLog(s);Free(s);
  PXLifeLog("PUBLIC EXPRESSION LIFETIME DONE\n");Sleep(1000);
}
PXLifeCheck;
