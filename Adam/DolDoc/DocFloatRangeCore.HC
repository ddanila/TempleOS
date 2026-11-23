public F64 PopUpRangeF64(F64 lo,F64 hi,F64 step,
    U8 *fmt="%9.4f",U8 *header=NULL,U8 *footer=NULL)
{//Evenly-spaced F64 range chooser in PopUp win task.
  F64 d;
  I64 i;
  U8 buf[STR_LEN];
  CDoc *doc=DocNew;
  if (header)
    DocPrint(doc,"%s",header);
  DocPrint(doc,"$$LTBLUE$$");
  for (d=lo;d<=hi;d+=step) {
    StrPrint(buf,fmt,d);
    DocPrint(doc,"$$MU,\"%s\",LE=0x%X$$\n",buf,d);
  }
  if (footer)
    DocPrint(doc,"%s",footer);
  i=PopUpMenu(doc);
  DocDel(doc);
  return i(F64);
}

