U8 word_oracle[ROWS_NUM*COLS_NUM*8][DIM_MAX+1];
U0 WordSearchProbe()
{
  I64 x,y,n=0,i;
  U8 line[80];
  MemSet(word_oracle,0,sizeof(word_oracle));
  for(y=0;y<ROWS_NUM;y++)
    for(x=0;x<COLS_NUM;x++)
      m[y][x]='A'+(x*3+y*5)%26;
  CollectWords(1,0,&n);
  CollectWords(0,1,&n);
  CollectWords(-1,0,&n);
  CollectWords(0,-1,&n);
  CollectWords(1,1,&n);
  CollectWords(-1,-1,&n);
  CollectWords(1,-1,&n);
  CollectWords(-1,1,&n);
  QSortI64(word_ptrs,n,&WordsCompare);
  for(i=0;i<n;i++)
    StrCpy(&word_oracle[i],word_ptrs[i](U8 *));
  StrPrint(line,"EXPORT words.bin %X %X\n",word_oracle,sizeof(word_oracle));
  for(i=0;line[i];i++)OutU8(0xE9,line[i]);
  U8 *s="WORD SEARCH sorted\n";
  while(*s)OutU8(0xE9,*s++);
}
