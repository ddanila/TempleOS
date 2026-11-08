U0 LexSkipEol(CCmpCtrl *cc)
{//$LK,"LexGetChar",A="MN:LexGetChar"$ to NULL until end-of-line.
  I64 ch;
  do ch=$WW,0$LexGetChar(cc);
  while (Bt(char_bmp_non_eol,ch));
}
