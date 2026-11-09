I64 pc_rows[12];
U8 *PCResult(I64 value){return value;}
U0 PCCheck()
{
  U8 *p=PCResult(-1),*q=-1;
  pc_rows[0]=sizeof(U8 *);pc_rows[1]=(p+0)(U64);
  pc_rows[2]=p>=0;pc_rows[3]=p==-1;pc_rows[4]=p==(-1)(U8 *);
  pc_rows[5]=p==q;pc_rows[6]=(p+0)(I32)==-1;
  pc_rows[7]=p==PCResult(-1);pc_rows[8]=PCResult(0x1234)>=0;
  pc_rows[9]=(PCResult(0x1234)+0)(U64);
  pc_rows[10]=((-1)(U8 *)+0)(U64);pc_rows[11]=((0x100001234)(U8 *)+0)(U64);
  U8 *s=MStrPrint("EXPORT pointer-cancel.bin %X 60\n",pc_rows);while(*s)OutU8(0xE9,*s++);
  s="POINTER CANCEL DONE\n";while(*s)OutU8(0xE9,*s++);
}PCCheck;
