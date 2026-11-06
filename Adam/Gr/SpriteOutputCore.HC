public CDocEntry *Sprite(U8 *elems,U8 *fmt=NULL)
{//Put sprite to the command-line, $LK,"DocPut",A="MN:DocPut"$.
//If you set fmt, then include dollars ("$$SP ...$$") and leave %d for num.
  CDoc *doc;
  if (doc=DocPut)
    return DocSprite(doc,elems,fmt);
  return NULL;
}
