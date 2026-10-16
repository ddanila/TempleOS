#include "/Adam/DolDoc/TermRightMenuTypes.HH"
I64 PopUpTermRight(U8 *header)
{
  I64 i;
  CDoc *doc=DocNew;
  if (header) DocPrint(doc,"%s",header);
  DocPrint(doc,"\n\n"
	"TXT=%s\nDD =%s\nJIT=%s\nGR =%s"
	"$$CM+LX,1,3 $$$$BT,\"Include           JIT\",LE=RIGHT_INCLUDE$$"
	"$$CM+LX,25,0$$$$BT,\"Adam Include      JIT\",LE=RIGHT_AINCLUDE$$"
	"$$CM+LX,1,3 $$$$BT,\"Copy                 \",LE=RIGHT_COPY$$"
	"$$CM+LX,25,0$$$$BT,\"Move or Rename       \",LE=RIGHT_MOVE$$"
	"$$CM+LX,1,3 $$$$BT,\"Delete               \",LE=RIGHT_DELETE$$"
	"$$CM+LX,25,0$$$$BT,\"Type           TXT;GR\",LE=RIGHT_TYPE$$"
	"$$CM+LX,1,3 $$$$BT,\"DolDoc Edit        DD\",LE=RIGHT_ED$$"
	"$$CM+LX,25,0$$$$BT,\"Mount           ISO.C\",LE=RIGHT_MOUNT$$"
	"$$CM+LX,1,3 $$$$BT,\"Plain Text Edit   TXT\",LE=RIGHT_PLAIN$$"
	"$$CM+LX,25,0$$$$BT,\"Infile             IN\",LE=RIGHT_INFILE$$"
	"$$CM+LX,1,3 $$$$BT,\"Cancel               \",LE=DOCM_CANCEL$$\n",
	FILEMASK_TXT,FILEMASK_DD,FILEMASK_JIT,FILEMASK_GR);
  i=PopUpMenu(doc);
  DocDel(doc);
  return i;
}

