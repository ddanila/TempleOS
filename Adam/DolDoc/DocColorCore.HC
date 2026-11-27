#help_index "Graphics/Input"
public I64 PopUpColor(U8 *header=NULL,
	Bool allow_transparent=TRUE,Bool allow_dft=TRUE)
{//Chooser for 16-color, default or transparent.
  I64 i;
  CDoc *doc=DocNew;
  try {
    if (header)
      DocPrint(doc,"%s",header);
    if (allow_transparent)
      DocPrint(doc,"$$MU,\"TRANSPARENT\",LE=TRANSPARENT$$\n");
    for (i=0;i<COLORS_NUM;i++)
      DocPrint(doc,"$$BG,%d$$$$MU,\"__%-8Z__\",LE=%d$$$$BG$$\n",i,i,"ST_COLORS",i);
    if (allow_dft)
      DocPrint(doc,"$$BG,WHITE$$$$MU,\"DEFAULT\",LE=DOC_DFT$$$$BG$$");
    i=PopUpMenu(doc);
  } catch { DocDel(doc); }
  DocDel(doc);
  return i;
}
