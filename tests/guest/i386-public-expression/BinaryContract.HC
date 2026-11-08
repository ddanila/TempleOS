//The Boolean compile wrapper returns code that survives its public controller.
U0 PBLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 PBCheck()
{
  I64 r[5],used=Fs->data_heap->used_u8s;
  CCmpCtrl *cc=CmpCtrlNew(StrNew("6*7;"));
  U8 *code=NULL,*message;
  Lex(cc);
  r[0]=IsLexExpression2Bin(cc,&code) && code!=NULL;
  r[1]=code && MSize(code)>0 && Call(code)==42;
  r[2]=cc->token==';' && !cc->error_cnt && !cc->warning_cnt;
  CmpCtrlDel(cc);
  r[3]=code && Call(code)==42;
  Free(code);
  r[4]=Fs->data_heap->used_u8s==used;
  message=MStrPrint("EXPORT public-expression-binary.bin %X 28\n",r);PBLog(message);Free(message);
  PBLog("PUBLIC EXPRESSION BINARY DONE\n");Sleep(1000);
}
PBCheck;
