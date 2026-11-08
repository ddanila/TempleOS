//Final ordered stage: initialize tables and publish only after all bodies load.
#include "/Compiler/LexPunctInit.HC"
U0 NativeSystemLexPublish()
{
 U32 *first=NULL,*second=NULL,*third=NULL;U8 *s="PUBLIC LEX loaded\n";
 if(!cmp.dual_U16_tokens1 && !cmp.dual_U16_tokens2 && !cmp.dual_U16_tokens3){
  try{
   first=CAlloc(sizeof(U32)*TK_TKS_NUM);second=CAlloc(sizeof(U32)*TK_TKS_NUM);third=CAlloc(sizeof(U32)*TK_TKS_NUM);
   LexPunctInit(first,second,third);
  }catch{Free(first);Free(second);Free(third);}
  cmp.dual_U16_tokens1=first;cmp.dual_U16_tokens2=second;cmp.dual_U16_tokens3=third;
 }
 if(!cmp.dual_U16_tokens1 || !cmp.dual_U16_tokens2 || !cmp.dual_U16_tokens3)throw('Compiler');
 native_jit_support.ext_str=&NativeSystemLexExtStr;native_jit_support.lex=&NativeSystemLex;
 while(*s)OutU8(0xE9,*s++);
}
if(native_jit_support.lex_stage!=11)throw('LexLoad');
NativeSystemLexPublish;
native_jit_support.lex_stage=12;
