//Ordered normal shared-parser stage.
U0 NativeSystemPrsPublish()
{
  U8 *s="PUBLIC PARSER loaded\n";
  native_jit_support.expression_i64=&NativeSystemLexExpressionI64;
  native_jit_support.expression_f64=&NativeSystemLexExpressionF64;
  native_jit_support.expression_bin=&NativeSystemLexExpression2Bin;
  native_jit_support.is_expression_bin=&NativeSystemIsLexExpression2Bin;
  native_jit_support.stream=&NativeSystemPrsStreamBlk;
  native_jit_support.expression=&NativeSystemLexExpression;
  while(*s)OutU8(0xE9,*s++);
}
if(native_jit_support.prs_stage!=11)throw('PrsLoad');
NativeSystemPrsPublish;

native_jit_support.prs_stage=12;
