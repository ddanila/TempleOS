I64 TGBSave(CDoc *doc,I64 drive,I64 n)
{
  I64 size,result;U8 *bytes=DocSave(doc,&size),*name=MStrPrint("%c:/tree-bytes%d.DD",drive,n);
  result=bytes&&FileWrite(name,bytes,size);Free(bytes);Free(name);return ToBool(result);
}
I64 TGB(I64 drive)
{
  CDoc *doc=DocNew;I64 mask=0;
  DocTreeWrite(doc,"Alpha/One",FALSE,"value=1;\n");
  if(TGBSave(doc,drive,0))mask|=1;
  DocTreeAppend(doc,"Alpha/One",FALSE,"value+=2;\n");
  DocTreeWrite(doc,"Alpha/Two",FALSE,"other=9;\n");
  if(TGBSave(doc,drive,1))mask|=2;
  DocTreeWrite(doc,"Alpha/One",FALSE,"value=7;\n");
  if(TGBSave(doc,drive,2))mask|=4;
  DocDel(doc);return mask;
}
