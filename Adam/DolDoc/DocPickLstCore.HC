public I64 PopUpPickLst(U8 *lst)
{//Prompt for lst entry in PopUp win task.
  I64 res,i=0;
  CDoc *doc=DocNew;
  DocPrint(doc,"$$LTBLUE$$");
  while (*lst) {
    if (*lst=='@') {//Check for '@' alias lst entry
      i--;
      lst++;
    }
    DocPrint(doc,"$$MU,\"%s\",LE=%d$$\n",lst,i++);
    lst+=StrLen(lst)+1;
  }
  DocPrint(doc,"\n$$MU,\"CANCEL\",LE=DOCM_CANCEL$$\n");
  res=PopUpMenu(doc);
  DocDel(doc);
  return res;
}

