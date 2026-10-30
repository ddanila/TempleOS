I64 AutoCompleteStateContract()
{
  CAutoCompleteGlbls a;CAutoCompleteDictGlbls d;CHashAC word;I64 mask=0;
  MemSet(&a,0,sizeof(a));MemSet(&d,0,sizeof(d));MemSet(&word,0,sizeof(word));
  a.num_words=19;a.flags=3;a.partial_len=7;a.num_fillins=2;
  a.fillin_hits[0]=11;a.fillin_hits[10]=29;a.fillin_matches[0]=&word;
  word.num=123;word.hits=456;
  d.word_lst_size=99;d.num_words=23;d.num_fillins=3;d.has_words=TRUE;d.has_defs=TRUE;
  d.fillins[0]="alpha";d.fillins[9]="omega";
  if(a.num_words==19 && a.flags==3 && a.partial_len==7 && a.num_fillins==2)mask|=1;
  if(a.fillin_hits[0]==11 && a.fillin_hits[10]==29 && a.fillin_matches[0]==&word && word.num==123 && word.hits==456)mask|=2;
  if(d.word_lst_size==99 && d.num_words==23 && d.num_fillins==3 && d.has_words && d.has_defs && !StrCmp(d.fillins[0],"alpha") && !StrCmp(d.fillins[9],"omega"))mask|=4;
  if(&ac && &acd && AC_FILLINS_NUM==10 && ACD_FILLINS_NUM==10 && ACf_INIT_IN_PROGRESS==0)mask|=8;
  if(ac.num_words>=0 && acd.word_lst_size>=0)mask|=16;
  return mask;
}
