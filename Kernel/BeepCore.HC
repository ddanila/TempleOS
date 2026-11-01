U0 Beep(I8 ona=62,Bool busy=FALSE)
{//Make beep at given ona freq.
  Snd(ona);
  if (busy)
    Busy(500000);
  else
    Sleep(500);
  Snd;
  if (busy)
    Busy(200000);
  else
    Sleep(200);
}
