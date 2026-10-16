public Bool DocType(CDoc *doc=NULL,U8 *filename,I64 trailing_new_lines=1)
{//Output txt or graphic file to document.
  Bool res=FALSE;
  CDoc *doc2;
  if (!doc && !(doc=DocPut) || doc->doc_signature!=DOC_SIGNATURE_VAL)
    return FALSE;
  if (FilesFindMatch(filename,FILEMASK_TXT)) {
    doc2=DocRead(filename);
    DocInsDoc(doc,doc2);
    if (IsRaw)
      DocDump(doc2,100000);
    DocDel(doc2);
    res=TRUE;
  } else if (FilesFindMatch(filename,"*.GR*")) {
    DocGR(doc,filename);
    res=TRUE;
  }
  if (res)
    DocPrint(doc,"%h*c",trailing_new_lines,'\n');
  return res;
}

#help_index "Graphics/GR Files;"\
	"File/Cmd Line (Typically);DolDoc/Cmd Line (Typically);"\
	"StdOut;Cmd Line (Typically)"
public Bool Type(U8 *filename,I64 trailing_new_lines=1)
{//Output txt or graphic file to command line.
  return DocType(,filename,trailing_new_lines);
}
