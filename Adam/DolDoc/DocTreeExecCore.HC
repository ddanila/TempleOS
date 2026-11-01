#help_index "DolDoc/Tree;DolDoc/Compiler;Compiler"
public I64 DocTreeExe(CDoc *doc,U8 *path)
{//Execute doc tree branch.
  CDoc *doc2;
  Bool unlock_doc=DocLock(doc);
  CDocEntry *tree_branch,*start_indent,*end_indent;
  I64 res=0;
  if (DocTreeFind(doc,path,&tree_branch,&start_indent,&end_indent)) {
    doc2=DocCopy(doc,tree_branch,end_indent);
    res=ExeDoc(doc2);
    DocDel(doc2);
  }
  if (unlock_doc)
    DocUnlock(doc);
  return res;
}

public I64 DocTreeFExe(U8 *name,U8 *path)
{//Execute doc tree branch in file.
  I64 res;
  CDoc *doc=DocRead(name);
  res=DocTreeExe(doc,path);
  DocDel(doc);
  return res;
}
