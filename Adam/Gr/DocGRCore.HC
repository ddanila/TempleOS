public U0 DocGR(CDoc *doc=NULL,U8 *filename)
{//Put a GR file into a document as asprite.
  CDC *dc=GRRead(filename);
  CSprite *elems=DC2Sprite(dc);
  DocSprite(doc,elems);
  Free(elems);
  DCDel(dc);
}
