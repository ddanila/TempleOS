U0 AttrCheck(U8 *name,I64 old_attr,I64 expected)
{
  if(FileAttr(name,old_attr)!=expected)throw('FileAttr',TRUE);
}
U0 PublicFileAttrContract()
{
  I64 retained=0x40000000|RS_ATTR_DIR|RS_ATTR_CONTIGUOUS|RS_ATTR_READ_ONLY;
  AttrCheck("a.HC.Z",0,RS_ATTR_COMPRESSED);
  AttrCheck("a.HC.C",0,RS_ATTR_CONTIGUOUS);
  AttrCheck("a.HC",0,0);
  AttrCheck("a.Z",0,0);
  AttrCheck("a.C",0,0);
  AttrCheck("dir.x/name.Z",0,RS_ATTR_COMPRESSED);
  AttrCheck("dir/name.HC.z",0,0);
  AttrCheck("a..Z",0,RS_ATTR_COMPRESSED);
  AttrCheck("a.HC.C.Z",0,RS_ATTR_COMPRESSED);
  AttrCheck("a.HC.Z.C",0,RS_ATTR_CONTIGUOUS);
  AttrCheck("",0,0);
  AttrCheck("a.HC",retained|RS_ATTR_COMPRESSED,retained);
  AttrCheck("a.HC.Z",retained,retained|RS_ATTR_COMPRESSED);
  AttrCheck("a.HC.C",RS_ATTR_COMPRESSED|RS_ATTR_HIDDEN,RS_ATTR_CONTIGUOUS|RS_ATTR_HIDDEN);
}
PublicFileAttrContract;
