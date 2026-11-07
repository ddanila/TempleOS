U0 PGLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 PGCase(U8 *source,I64 opcode,I64 value)
{
  CCmpCtrl *cc=CmpCtrlNew(StrNew(source));
  CIntermediateCode *ret,*producer;I64 pass,mask=0,expected_type=RT_I64;
  COCInit(cc);Lex(cc);
  if(PrsExpression(cc,NULL,FALSE))mask|=1;
  ret=ICAdd(cc,IC_RETURN_VAL,0,NULL);ICAdd(cc,IC_RET,0,NULL);
  for(pass=0;pass<3;pass++){cc->pass=pass;OptPass012(cc);}
  producer=ret->t.arg1_tree;
  if(producer && producer->ic_code==opcode && producer->ic_data==value)mask|=2;
  if(opcode==IC_IMM_F64)expected_type=RT_F64;
  if(producer && cc->token==';' && !cc->error_cnt && !cc->warning_cnt && producer->ic_class &&
      producer->ic_class->raw_type==expected_type)mask|=4;
  COCDel(cc,&cc->coc);CmpCtrlDel(cc);return mask;
}
U0 PGCheck()
{
  I64 value,*result=MAlloc(8);U8 *s;
  value(F64)=3.75;
  *result=PGCase("6*7;",IC_IMM_I64,42)|PGCase("1.25+2.5;",IC_IMM_F64,value)<<3;
  s=MStrPrint("EXPORT public-parser-graph.bin %X 8\n",result);PGLog(s);Free(s);
  PGLog("PUBLIC PARSER GRAPH DONE\n");Sleep(1000);
}
PGCheck;
