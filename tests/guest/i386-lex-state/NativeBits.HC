I64 NativeBitIntrinsicsTest()
{
  U64 word,expected;
  U8 *base;
  I64 bit,state,result=0;
  U32 flags=I386IrqSave;
  OutU8(0x21,255); OutU8(0xA1,255);
  //The computed operand is this live stack word. A signed offset beyond
  //32 bits must reach it from a base 512 MiB higher, without dereferencing
  //that base itself or truncating the bit index before scaling it.
  base=(&word+0)(U64)+0x20000000;
  for(bit=0;bit<64;bit++) {
    word=0; expected=1; expected<<=bit;
    if(Bts(base,-0x100000000+bit) || word!=expected ||
        !Bt(base,-0x100000000+bit) || !Btr(base,-0x100000000+bit) || word) result=103;
  }
  for(state=0;state<2;state++) {
    SetRFlags((GetRFlags&~0x200)|(state<<9));
    word=0;
    if(LBts(&word,63) || !LBtc(&word,63) || LBtr(&word,63) || word ||
        (GetRFlags&0x200)!=(state<<9)) result=104;
  }
  I386IrqRestore(flags);
  return result;
}
