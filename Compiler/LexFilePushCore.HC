CLexFile *LexFilePush(CCmpCtrl *cc)
{
  return LexFileAttach(cc,CAlloc(sizeof(CLexFile)));
}
