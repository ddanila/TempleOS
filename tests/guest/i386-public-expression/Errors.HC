#include "/Kernel/I386/PublicCompiler.HH"
#include "/Kernel/I386/PublicTerminal.HH"
U0 EELog(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 EEGood()
{
  CCmpCtrl *cc=CmpCtrlNew(StrNew("6*7;"));I64 res;
  Lex(cc);res=LexExpressionI64(cc);CmpCtrlDel(cc);return res;
}
I64 EEThrow(){throw('EvalFail');return 0;}
U0 EECase(I64 *r,U8 *source,I64 mode=0)
{
  I64 used=Fs->data_heap->used_u8s,code_used=Fs->code_heap->used_u8s;
  CDoc *old_doc=Fs->put_doc,*doc=DocNew;
  CCmpCtrl *cc=CmpCtrlNew(StrNew(source),CCF_TARGET_I386|(1<<CCf_PASS_TRACE_PRESENT)|CCF_TARGET_HOST_CONST,"C:/Probe/Error.HC");
  CIntermediateCode *outer;
  CCodeCtrl *saved;
  U8 *code=NULL;
  Fs->put_doc=doc;COCInit(cc);outer=ICAdd(cc,IC_IMM_I64,99,cmp.internal_types[RT_I64]);saved=cc->coc.coc_next;
  Lex(cc);
  if(mode==1)cc->flags|=CCF_AOT_COMPILE;
  try{if(mode<2)code=LexExpression2Bin(cc);else if(mode==2)LexExpression(cc);else if(mode==3)LexExpressionI64(cc);else LexExpressionF64(cc);}
  catch{r[0]=Fs->except_ch;Fs->catch_except=TRUE;}
  r[1]=cc->error_cnt;
  r[2]=cc->coc.coc_next==saved;
  r[3]=(cc->flags&((1<<CCf_PASS_TRACE_PRESENT)|CCF_TARGET_HOST_CONST))==((1<<CCf_PASS_TRACE_PRESENT)|CCF_TARGET_HOST_CONST);
  r[4]=r[2] && cc->coc.coc_head.next==outer && cc->coc.coc_head.last==outer && outer->ic_data==99;
  r[7]=code==NULL;Free(code);
  //Clean any reachable failed frames so the probe can measure orphaned data.
  while(cc->coc.coc_next!=saved){COCDel(cc,&cc->coc);COCPop(cc);}
  COCDel(cc,&cc->coc);CmpCtrlDel(cc);Fs->put_doc=old_doc;DocDel(doc);TaskWait(adam_task);
  r[5]=Fs->data_heap->used_u8s-used;r[6]=Fs->code_heap->used_u8s-code_used;
  r[8]=EEGood;
}
U0 EECheck()
{
  I64 *r=CAlloc(81*8);U8 *s;
  if(EEGood!=42)throw;
  EECase(r,"1+;");EECase(r+9,"(2+;");EECase(r+18,"1+UnknownErrorName;");
  EECase(r+27,"6*7;");EECase(r+36,"6*7;",1);
  EECase(r+45,"EEThrow();",2);EECase(r+54,"EEThrow();",3);EECase(r+63,"EEThrow();",4);
  EECase(r+72,"0(I64[EEThrow()]);");
  s=MStrPrint("EXPORT expression-errors.bin %X 288\n",r);EELog(s);Free(s);
  EELog("EXPRESSION ERRORS DONE\n");Sleep(1000);
}
EECheck;
