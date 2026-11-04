//Original autocomplete action branches. Callers retain key-description handling.
U0 DocAutoCompleteSymbolCore(CDoc *doc,I64 sc,Bool (*enable)(Bool value),
  U0 (*fill)(I64 n),U0 (*source)(I64 n,CTask *parent))
{
  DocUnlock(doc);
  if ((*enable)(ON)) {
    if (sc&SCF_SHIFT)
      (*source)(sc.u8[0]-SC_F1+1,Fs);
    else
      (*fill)(sc.u8[0]-SC_F1+1);
  }
  DocLock(doc);
}

U0 DocAutoCompleteWordCore(CDoc *doc,I64 ch,I64 sc,Bool (*enable)(Bool value),
  U0 (*fill)(I64 n),U0 (*definition)(I64 n,CTask *parent))
{
  if ((*enable)(ON)) {
    DocUnlock(doc);
    if (sc&SCF_SHIFT)
      (*definition)(ch-'0',Fs);
    else
      (*fill)(ch-'0');
    DocLock(doc);
  }
}
