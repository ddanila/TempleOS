#ifndef I386_BITS_INCLUDED
#define I386_BITS_INCLUDED
//Standalone declarations; intrinsic IDs match Compiler/CompilerA.HH.
//Bit offsets are signed I64; memory addresses have target pointer width.
//Keep the containing dword accessible, including for unaligned bit strings.
public _intern 0x77 Bool Bt(U8 *bit_field,I64 bit);
public _intern 0x78 Bool Bts(U8 *bit_field,I64 bit);
public _intern 0x79 Bool Btr(U8 *bit_field,I64 bit);
public _intern 0x7A Bool Btc(U8 *bit_field,I64 bit);
public _intern 0x7B Bool LBts(U8 *bit_field,I64 bit);
public _intern 0x7C Bool LBtr(U8 *bit_field,I64 bit);
public _intern 0x7D Bool LBtc(U8 *bit_field,I64 bit);
public _intern 0x7E I64 Bsf(I64 bit_field_val);
public _intern 0x7F I64 Bsr(I64 bit_field_val);
#endif
