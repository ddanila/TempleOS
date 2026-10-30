I64 prompt_case,prompt_calls;
U64 prompt_float_bits;
U8 *PromptFixture(I64 flags=0)
{
  no_warn flags;
  prompt_calls++;
  switch(prompt_case) {
    case 0: return StrNew("");
    case 1: return StrNew("6*7");
    case 2: if(prompt_calls==1)return StrNew("99"); else return StrNew("7");
    case 3: return StrNew("2.5+1.25");
    case 4: return StrNew("");
    case 5: if(prompt_calls==1)return StrNew("no_such_prompt_identifier"); else return StrNew("8");
  }
  return StrNew("");
}
I64 NumericPromptContract(Bool errors=FALSE)
{
  U8 *(*saved)(I64 flags=0);
  I64 mask=0;
  saved=fp_getstr2;fp_getstr2=&PromptFixture;
  prompt_case=0;prompt_calls=0;if(GetI64(NULL,13)==13 && prompt_calls==1)mask|=1;
  prompt_case=1;prompt_calls=0;if(GetI64==42 && prompt_calls==1)mask|=2;
  prompt_case=2;prompt_calls=0;if(GetI64(NULL,0,1,10)==7 && prompt_calls==2)mask|=4;
  prompt_case=3;prompt_calls=0;prompt_float_bits=GetF64()(U64);if(prompt_float_bits==0x400E000000000000 && prompt_calls==1)mask|=8;
  prompt_case=4;prompt_calls=0;if(GetDate(NULL,123)==123 && prompt_calls==1)mask|=16;
  if(errors) {prompt_case=5;prompt_calls=0;if(GetI64()==8 && prompt_calls==2)mask|=32;}
  fp_getstr2=saved;
  return mask;
}
