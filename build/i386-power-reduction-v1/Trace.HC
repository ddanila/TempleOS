F64 PowerReduced(F64 base,F64 exponent)
{
  U16 saved_cw,truncate_cw;
  F64 reduced;
  asm {
    FSTCW U16 &saved_cw[RBP]
    MOV AX,U16 &saved_cw[RBP]
    OR AX,0x0C00
    MOV U16 &truncate_cw[RBP],AX
    FLDCW U16 &truncate_cw[RBP]
    FLD U64 &exponent[RBP]
    FLD U64 &base[RBP]
    FABS
    FYL2X
    FSTP U64 &reduced[RBP]
    FLDCW U16 &saved_cw[RBP]
  }
  return reduced;
}

U0 PowerReductionProbe()
{
  F64 square=PowerReduced(3,2),cube=PowerReduced(2,3),
      fraction=PowerReduced(9,0.5),inverse=PowerReduced(2,-2);
  U8 line[192],*p;
  StrPrint(line,"POWER reduced %016X %016X %016X %016X\n",
      *(&square)(U64 *),*(&cube)(U64 *),*(&fraction)(U64 *),*(&inverse)(U64 *));
  p=line;
  while (*p) OutU8(0xE9,*p++);
}
PowerReductionProbe;
