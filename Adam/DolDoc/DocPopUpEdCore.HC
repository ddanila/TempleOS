public I64 PopUpEd(U8 *filename,CTask *parent=NULL,CTask **_pu_task=NULL)
{//Create PopUp win task and edit a doc.
  U8 *st=MStrPrint("Ed(\"%Q\");",filename);
  I64 res=PopUp(st,parent,_pu_task);
  Free(st);
  return res;
}
