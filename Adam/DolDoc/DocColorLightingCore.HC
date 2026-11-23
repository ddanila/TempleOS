public I64 PopUpColorLighting(U8 *header=NULL)
{//Chooser for std TempleOS $LK,"DCLighting",A="MN:DCLighting"$() color.
  I64 i;
  CDoc *doc=DocNew;
  if (header)
    DocPrint(doc,"%s",header);
  DocPrint(doc,"\nSingle-Sided means front and back different."
	"\nDouble-Sided means front and back same."
	"\n"
	"\nHalf-Range means 0 to [0,7]"
	"\n                 [8,15]-8 to [8,15]"
	"\nFull-Range means 0 to [0,7] to [0,7]+8"
	"\n");
  DocPrint(doc,
	"\n$$LTPURPLE$$Single-Sided Full-Range Double-Sided Full-Range\n$$BLACK$$");
  for (i=0;i<COLORS_NUM/2;i++) {
    DocPrint(doc,"$$BG,%d$$$$MU,\"__%-19Z__\",LE=%d$$$$BG$$ ",i,i,"ST_COLORS",i);
    DocPrint(doc,"$$BG,%d$$$$MU,\"__%-19Z__\",LE=%d$$$$BG$$\n",i,i,"ST_COLORS",
	  ROPF_TWO_SIDED+i);
  }
  DocPrint(doc,
	"\n$$LTPURPLE$$Single-Sided Half-Range Double-Sided Half-Range\n$$BLACK$$");
  for (i=0;i<COLORS_NUM;i++) {
    DocPrint(doc,"$$BG,%d$$$$MU,\"__%-19Z__\",LE=%d$$$$BG$$ ",
	  i,i,"ST_COLORS",ROPF_HALF_RANGE_COLOR+i);
    DocPrint(doc,"$$BG,%d$$$$MU,\"__%-19Z__\",LE=%d$$$$BG$$\n",
	  i,i,"ST_COLORS",ROPF_TWO_SIDED+ROPF_HALF_RANGE_COLOR+i);
  }
  i=PopUpMenu(doc);
  DocDel(doc);
  return i;
}
