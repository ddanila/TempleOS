I64 ball_product_steps[6];

I64 BallTruncateArgument(I64 value)
{
  return value;
}

U0 BallProductSample(F64 left,F64 right,I64 *result)
{
  F64 product=left*right;
  result[0]=BallTruncateArgument(left*right);
  result[1]=BallTruncateArgument(product);
  result[2]=product(U64);
}

U0 BallProductConversion()
{
  U8 msg[128],*p;
  BallProductSample(0x402C48C6001F0AC0(F64),0xBFE6A09E667F3BCC(F64),ball_product_steps);
  BallProductSample(0x402C48C6001F0AC0(F64),0x3FE6A09E667F3BCC(F64),ball_product_steps+3);
  StrPrint(msg,"EXPORT BallVertexMath.bin %X 30\n",ball_product_steps);
  for (p=msg;*p;p++) OutU8(0xE9,*p);
  Sleep(2000);
  for (p="BALL math ready\n";*p;p++) OutU8(0xE9,*p);
}
BallProductConversion;
