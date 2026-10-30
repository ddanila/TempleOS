I64 DocMaxContract()
{
  CDoc *saved=Fs->put_doc,*doc=DocNew(NULL,Fs);I64 mask=0;
  Fs->put_doc=doc;doc->max_entries=47;
  if(DocMax(12)==47 && doc->max_entries==12)mask|=1;
  if(DocMax(0)==12 && doc->max_entries==0)mask|=2;
  if(DocMax()==0 && doc->max_entries==I64_MAX)mask|=4;
  Fs->put_doc=NULL;if(DocMax(5)==0)mask|=8;
  Fs->put_doc=saved;DocDel(doc);return mask;
}
