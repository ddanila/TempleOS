Bool HCCheck(U8 *source,I64 wanted_type,I64 wanted_bits,Bool target=TRUE)
{
  I64 flags=CCF_DONT_FREE_BUF;
  CCmpCtrl *cc;
  if(target)flags|=CCF_TARGET_I386;
  cc=CmpCtrlNew(source,flags);
  U8 *code=NULL;
  I64 type=0,bits=0;
  Bool ok=FALSE;
  try {
    Lex(cc);
    code=LexExpression2Bin(cc,&type);
    if(code) {bits=Call(code);ok=type==wanted_type && bits==wanted_bits;}
  } catch {
    Fs->catch_except=TRUE;
  }
  if(!ok) {
    U8 *line=MStrPrint("OBS source %s type %d bits %X code %X\n",source,type,bits,code),*scan=line;
    while(*scan)OutU8(0xE9,*scan++);
    Free(line);
  }
  Free(code);
  CmpCtrlDel(cc);
  return ok;
}
Bool HCReject(U8 *source)
{
  CCmpCtrl *cc=CmpCtrlNew(source,CCF_DONT_FREE_BUF|CCF_TARGET_I386);
  U8 *code=NULL;
  try {Lex(cc);code=LexExpression2Bin(cc);}
  catch {Fs->catch_except=TRUE;}
  Bool rejected=!code;
  Free(code);CmpCtrlDel(cc);return rejected;
}
I64 JRContract(I64 unused)
{
  I64 mask=0;
  if(HCCheck("7",RT_I64,7))mask|=1;
  if(HCCheck("2.5",RT_F64,0x4004000000000000))mask|=2;
  if(HCCheck("-2.5",RT_F64,0xC004000000000000))mask|=4;
  if(HCCheck("0.0",RT_F64,0))mask|=8;
  //Preserve original decimal-expression bits, verified against the host backend.
  if(HCCheck("1.25+1.25",RT_F64,0x4004000000000001,FALSE) &&
     HCCheck("1.25+1.25",RT_F64,0x4004000000000001))mask|=16;
  if(HCCheck("1.0/8.0",RT_F64,0x3FC0000000000000))mask|=32;
  if(HCCheck("2*(0x400921FB54442D18(F64))",RT_F64,0x401921FB54442D18,FALSE) &&
     HCCheck("2*(0x400921FB54442D18(F64))",RT_F64,0x401921FB54442D18))mask|=64;
  if(HCCheck("2*(0x400921FB54442D18(F64))/2",RT_F64,0x400921FB54442D18,FALSE) &&
     HCCheck("2*(0x400921FB54442D18(F64))/2",RT_F64,0x400921FB54442D18))mask|=128;
  if(HCReject("1(U8 *)"))mask|=256;
  if(HCReject("Fs->num"))mask|=512;
  return mask;
}
