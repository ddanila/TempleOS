#include "/Compiler/LexConditional.HH"
class CConditionalFault { I64 raw_calls,token_calls,raw_result,token_result; CHashGeneric keyword; };
I64 ConditionalFaultRaw(U8 *context,CCmpCtrl *cc)
{
  CConditionalFault *fault=context;
  if(fault->raw_calls++) return 0;
  return fault->raw_result;
}
I64 ConditionalFaultToken(U8 *context,CCmpCtrl *cc)
{
  CConditionalFault *fault=context; fault->token_calls++;
  cc->token=fault->token_result; cc->hash_entry=&fault->keyword;
  return fault->token_result;
}
I64 ConditionalFailureTest()
{
  CConditionalFault fault; CCmpCtrl cc; CLexCharSource raw,tokens; I64 i;
  raw.context=&fault; raw.read=&ConditionalFaultRaw;
  tokens.context=&fault; tokens.read=&ConditionalFaultToken;
  IdentZero(&fault,sizeof(CConditionalFault)); IdentZero(&cc,sizeof(CCmpCtrl));
  fault.raw_result=-1; cc.token=77;
  if(LexSkipConditional(&cc,&raw,&tokens,1,TRUE)!=-1 || cc.token!=77 || fault.raw_calls!=1 || fault.token_calls) return 140;
  for(i=-5;i<=0;i++) {
    IdentZero(&fault,sizeof(CConditionalFault));
    fault.raw_result=35; fault.token_result=i;
    if(LexSkipConditional(&cc,&raw,&tokens,1,TRUE)!=i || fault.raw_calls!=1 || fault.token_calls!=1) return 141;
  }
  IdentZero(&fault,sizeof(CConditionalFault));
  fault.raw_result=35; fault.token_result=TK_IDENT; fault.keyword.type=HTT_KEYWORD; fault.keyword.user_data0=KW_ELSE;
  if(LexSkipConditional(&cc,&raw,&tokens,1,TRUE)!=1 || fault.raw_calls!=1 || fault.token_calls!=1) return 142;
  fault.raw_calls=fault.token_calls=0;
  if(LexSkipConditional(&cc,&raw,&tokens,1,FALSE)!=0 || cc.token!=TK_EOF || fault.raw_calls!=2 || fault.token_calls!=1) return 143;
  fault.raw_calls=fault.token_calls=0; fault.keyword.user_data0=KW_ENDIF;
  if(LexSkipConditional(&cc,&raw,&tokens,1,FALSE)!=1 || fault.raw_calls!=1 || fault.token_calls!=1) return 144;
  fault.raw_calls=fault.token_calls=0;
  if(LexSkipConditional(&cc,&raw,&tokens,2,TRUE)!=0 || fault.raw_calls!=2 || fault.token_calls!=1) return 145;
  return 0;
}
