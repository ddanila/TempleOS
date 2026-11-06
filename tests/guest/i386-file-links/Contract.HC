U8 *fl_output;
I64 fl_size;
U0 FileLinksCheck(U8 *root)
{
  CDoc *old=Fs->put_doc,*doc=DocNew;
  U8 *cwd=DirCur,*s,*p;
  Bool raw=Raw(OFF);
  Cd(root);Fs->put_doc=doc;
  PutFileLink(NULL);
  PutFileLink("short","C:/fixed/name.HC");"\n";
  PutFileLink("short","C:/fixed/name.HC",7);"\n";
  PutFileLink("short","C:/fixed/name.HC",0,TRUE);"\n";
  PutFileLink("short","C:/fixed/name.HC",23,TRUE);"\n";
  PutFileLink("A1:Sprite");"\n";
  PutFileLink("A1:Sprite",,9);"\n";
  PutFileLink("F.HC");"\n";
  fl_output=DocSave(doc,&fl_size);
  Fs->put_doc=old;DocDel(doc);Cd(cwd);Free(cwd);Raw(raw);
  s=MStrPrint("EXPORT links.DD %X %X\nFILE LINKS DONE\n",fl_output,fl_size);
  p=s;while(*p)OutU8(0xE9,*p++);Free(s);
}
