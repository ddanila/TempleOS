U0 CDEntryContract()
{
  CDirEntry root,other,alpha,alphabet,nested,file;
  I64 rows[12];U8 *s,*p;
  MemSet(&root,0,sizeof(CDirEntry));MemSet(&other,0,sizeof(CDirEntry));
  MemSet(&alpha,0,sizeof(CDirEntry));MemSet(&alphabet,0,sizeof(CDirEntry));
  MemSet(&nested,0,sizeof(CDirEntry));MemSet(&file,0,sizeof(CDirEntry));
  root.full_name="C:/";other.full_name="D:/";
  alpha.full_name="C:/Alpha";alphabet.full_name="C:/Alphabet";
  nested.full_name="C:/Alpha/Nested";file.full_name="C:/Alpha/Nested/Leaf.TXT";
  root.next=&other;root.sub=&alpha;alpha.next=&alphabet;
  alpha.sub=&nested;nested.sub=&file;
  rows[0]=Cd2DirEntry(NULL,"C:/")==NULL;
  rows[1]=Cd2DirEntry(&root,"C:/")==&root;
  rows[2]=Cd2DirEntry(&root,"D:/")==&other;
  rows[3]=Cd2DirEntry(&root,"C:/Alpha")==&alpha;
  rows[4]=Cd2DirEntry(&root,"C:/Alphabet")==&alphabet;
  rows[5]=Cd2DirEntry(&root,"C:/Alpha/Nested")==&nested;
  rows[6]=Cd2DirEntry(&root,"C:/Alpha/Nested/Leaf.TXT")==&file;
  rows[7]=Cd2DirEntry(&root,"C:/Alpha/Missing")==NULL;
  rows[8]=Cd2DirEntry(&root,"C:/Alphab")==NULL;
  rows[9]=Cd2DirEntry(&root,"c:/Alpha")==NULL;
  rows[10]=Cd2DirEntry(&root,"C:/Alpha/")==NULL;
  rows[11]=root.next==&other && root.sub==&alpha && alpha.next==&alphabet &&
    alpha.sub==&nested && nested.sub==&file && !StrCmp(file.full_name,"C:/Alpha/Nested/Leaf.TXT");
  s=MStrPrint("EXPORT lookup.bin %X %X\n",rows,sizeof(rows));
  p=s;while(*p)OutU8(0xE9,*p++);Free(s);
  p="CD ENTRY DONE\n";while(*p)OutU8(0xE9,*p++);
  Sleep(1000);
}
