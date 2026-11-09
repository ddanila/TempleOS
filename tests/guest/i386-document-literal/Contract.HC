U0 DLLiteralLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 DocumentLiteralContract()
{
  U8 *s,*value;
  value=DLLiteralLink;
  s=MStrPrint("EXPORT literal-link.bin %X %X\n",value,StrLen(value)+1);DLLiteralLog(s);Free(s);
  value=DLLiteralText;
  s=MStrPrint("EXPORT literal-text.bin %X %X\n",value,StrLen(value)+1);DLLiteralLog(s);Free(s);
  DLLiteralLog("DL DONE\n");
}
DocumentLiteralContract;
