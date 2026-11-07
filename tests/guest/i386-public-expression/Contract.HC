U0 PELog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 PECase(I64 *state,I64 *value,U8 *source,I64 mode)
{
  CCmpCtrl *cc=CmpCtrlNew(StrNew(source),0,"C:/Probe/Expressions.HC");
  try {
    Lex(cc);
    if(mode==0)*value=LexExpression(cc);
    else if(mode==1)*value=LexExpressionI64(cc);
    else *value(F64 *)=LexExpressionF64(cc);
    *state=cc->token==';' && !cc->error_cnt && !cc->warning_cnt;
  }catch{Fs->catch_except=TRUE;}
  CmpCtrlDel(cc);
}
U0 PECheck()
{
  I64 *r=CAlloc(18*8);U8 *s;
  PECase(r+0,r+9,"6*7;",0);
  PECase(r+1,r+10,"0x123456789ABCDEF;",0);
  PECase(r+2,r+11,"-2+5;",0);
  PECase(r+3,r+12,"(2+3)*4;",0);
  PECase(r+4,r+13,"2<3;",0);
  PECase(r+5,r+14,"!0;",0);
  PECase(r+6,r+15,"1.25*4;",1);
  PECase(r+7,r+16,"3+4;",2);
  PECase(r+8,r+17,"1.25+2.5;",2);
  s=MStrPrint("EXPORT public-expression.bin %X %X\n",r,18*8);PELog(s);Free(s);
  PELog("PUBLIC EXPRESSION DONE\n");Sleep(1000);
}
PECheck;
