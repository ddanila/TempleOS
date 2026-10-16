#define LA_BOUND 13
#define LA_EXPR 2+3
class LALiteral {U8 bytes[7];};
class LAHex {U8 bytes[0xB];};
class LAChar {U8 bytes['A'];};
class LASpace {U8 bytes[17 ];};
class LAComment {U8 bytes[19/* delimiter after comment */];};
class LAMacro {U8 bytes[LA_BOUND];};
class LAExpressionMacro {U8 bytes[LA_EXPR];};
class LAExpression {U8 bytes[2+3*4];};
class LAParenthesis {U8 bytes[(23)];};
class LAUnsigned {U8 bytes[0xFFFFFFFFFFFFFFFF&31];};
class LAFloat {U8 bytes[3.75];};
class LAMatrix {U8 bytes[3][5];};
class LANewline {U8 bytes[29
];};
class LANegativeExpression {U8 bytes[-(-31)];};
I64 la_calls=0;
I64 LABound(){la_calls++;return 37;}
class LACall {U8 bytes[LABound];};
I64 LALocal(){U8 bytes[41];return sizeof(bytes);}
I64 LAContract()
{
  I64 mask=0;
  if(sizeof(LALiteral)==7 && sizeof(LAHex)==11 && sizeof(LAChar)==65)mask|=1;
  if(sizeof(LASpace)==17 && sizeof(LAComment)==19 && sizeof(LANewline)==29)mask|=2;
  if(sizeof(LAMacro)==13 && sizeof(LAExpressionMacro)==5)mask|=4;
  if(sizeof(LAExpression)==14 && sizeof(LAParenthesis)==23)mask|=8;
  if(sizeof(LAUnsigned)==31 && sizeof(LAFloat)==3)mask|=16;
  if(sizeof(LAMatrix)==15 && sizeof(LANegativeExpression)==31)mask|=32;
  if(sizeof(LACall)==37 && la_calls==1)mask|=64;
  if(LALocal==41)mask|=128;
  return mask;
}
