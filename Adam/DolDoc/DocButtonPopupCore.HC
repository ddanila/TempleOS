public I64 PopUp1(U8 *b1,I64 n1,U8 *header=NULL,U8 *footer=NULL)
{//Make PopUp win task with one bttn.
  I64 i,l1=StrLen(b1);
  CDoc *doc=DocNew;
  if (header) DocPrint(doc,"%s",header);
  DocPrint(doc,"$$CM+CX,%d,4$$$$BT,\"%s\",LE=%d$$\n",-l1/2,b1,n1);
  if (footer) DocPrint(doc,"%s",footer);
  i=PopUpMenu(doc);
  DocDel(doc);
  return i;
}

public I64 PopUp2(U8 *b1,I64 n1,U8 *b2,I64 n2,U8 *header=NULL,U8 *footer=NULL)
{//Make PopUp win task with two bttns.
  I64 i,l1=StrLen(b1),l2=StrLen(b2),y;
  CDoc *doc=DocNew;
  if (header) {
    DocPrint(doc,"%s",header);
    y=4;
  } else {
    DocPrint(doc,"%*s\n",l1+l2+10,"");
    y=3;
  }
  DocPrint(doc,"$$CM+CX,%d,%d$$$$BT,\"%s\",LE=%d$$",-(l1+l2+3)>>1,y,b1,n1);
  DocPrint(doc,"$$CM+CX,%d,0$$$$BT,\"%s\",LE=%d$$\n" ,-(l1+l2+3)>>1+l1+6,b2,n2);
  if (footer) DocPrint(doc,"%s",footer);
  i=PopUpMenu(doc);
  DocDel(doc);
  return i;
}

public Bool PopUpOk(U8 *header=NULL,U8 *footer=NULL)
{//Make PopUp win task with OKAY bttn.
  return PopUp1("OKAY",1,header,footer)>0;
}

public Bool PopUpNoYes(U8 *header=NULL,U8 *footer=NULL)
{//Make PopUp win task with NO/YES bttns.
  return $WW,0$PopUp2("YES",1,"NO",0,header,footer)>0;
}

public Bool PopUpCancelOk(U8 *header=NULL,U8 *footer=NULL)
{//Make PopUp win task CANCEL/OKAY bttns.
  return PopUp2("OKAY",1,"CANCEL",0,header,footer)>0;
}

