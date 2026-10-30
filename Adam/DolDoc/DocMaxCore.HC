//Original maximum-entry setting.
public I64 DocMax(I64 i=I64_MAX)
{//Set max document entries. (Cmd line buffer size.)
//Adjusts the size of the cmd line buf.
  //Normally, the cmd line deletes entries
  //when more are added and the old scroll up.
  //See $LK,"max_entries",A="FF:::/Adam/DolDoc/DocTerm.HC,max_entries"$.
  I64 res;
  CDoc *doc;
  if (doc=DocPut) {
    res=doc->max_entries;
    doc->max_entries=i;
    return res;
  } else
    return 0;
}

