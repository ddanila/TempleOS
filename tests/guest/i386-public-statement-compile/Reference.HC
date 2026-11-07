U0 PSLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 ps_observed;F64 ps_float_observed;
U0 PSSet(I64 value){ps_observed=value;}
U0 PSSetF(F64 value){ps_float_observed=value;}
U0 PSCase(I64 *state,I64 *value,U8 *source,I64 expected_type=RT_I64,Bool empty=FALSE,I64 effect=0)
{
  CCmpCtrl *cc;U8 *code=NULL;I64 type=-1,flags=0;
#ifdef I386_PUBLIC_KERNEL_INCLUDED
  flags=CCF_TARGET_I386;
#endif
  cc=CmpCtrlNew(StrNew(source),flags,"C:/Probe/Statement.HC");
  try {
    Lex(cc);code=LexStmt2Bin(cc,&type,CMPF_PRS_SEMICOLON);
    if(empty)*state=code==INVALID_PTR && cc->token==TK_EOF && !cc->error_cnt;
    else *state=code && code!=INVALID_PTR && cc->token==TK_EOF && !cc->error_cnt &&
      !cc->warning_cnt && type==expected_type;
  }catch{Fs->catch_except=TRUE;}
  CmpCtrlDel(cc);
  if(code && code!=INVALID_PTR){*value=Call(code);if(effect==1)*value=ps_observed;else if(effect==2)*value=ps_float_observed(I64);Free(code);}
}
U0 PSCheck()
{
  I64 *r=CAlloc(22*8),used=Fs->data_heap->used_u8s,code_used=Fs->code_heap->used_u8s;
  U8 *s;CCmpCtrl *cc;CDoc *put=DocPut,*doc;
  PSCase(r+0,r+10,"6*7;");
  PSCase(r+1,r+11,"0x123456789ABCDEF;");
  PSCase(r+2,r+12,"2+3,6*7;");
  PSCase(r+3,r+13,"{3;6*7;}");
  PSCase(r+4,r+14,"if(1)PSSet(42);else PSSet(9);",RT_U0,FALSE,1);
  PSCase(r+5,r+15,"if(0)PSSet(9);else PSSet(42);",RT_U0,FALSE,1);
  PSCase(r+6,r+16,"1.25+2.5;",RT_F64);
  PSCase(r+7,r+17,"{PSSetF(1.25);PSSetF(1.25+2.5);}",RT_U0,FALSE,2);
  PSCase(r+8,r+9,";",RT_I64,TRUE);
  r[18]=Fs->data_heap->used_u8s==used;r[19]=Fs->code_heap->used_u8s==code_used;
  while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
  doc=DocNew;Fs->put_doc=doc;
  cc=CmpCtrlNew(StrNew("1+;"),0,"C:/Probe/BadStatement.HC");
  try{Lex(cc);LexStmt2Bin(cc,NULL,CMPF_PRS_SEMICOLON);}
  catch{r[9]=Fs->except_ch=='Compiler' && cc->error_cnt>0;Fs->catch_except=TRUE;}
  CmpCtrlDel(cc);Fs->put_doc=put;DocDel(doc);
  if(sizeof(U8 *)==8)r[20]=INVALID_PTR==I64_MAX;
  else r[20]=INVALID_PTR==U32_MAX;
  r[21]=sizeof(I64)==8;
  s=MStrPrint("EXPORT public-statement-compile.bin %X B0\n",r);PSLog(s);Free(s);
  PSLog("PUBLIC STATEMENT COMPILE DONE\n");Sleep(1000);
}
PSCheck;
