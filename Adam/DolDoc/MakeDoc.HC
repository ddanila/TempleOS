Cd(__DIR__);;

#help_index "DolDoc"
#help_file "::/Doc/DolDoc"

/*
TempleOS DolDoc's can have "cursor movement" cmds which can move the cursor up
the scrn and layer on existing text.  It can also have callback funs which
supply live, changing text.  For these reasons, you can't assume you know
where the vis portion of the document is and must process much
of the document each time it is placed on the scrn, becoming CPU
intensive on big documents.
See $LK,"::/Doc/DolDocOverview.DD"$
*/

#include "/Kernel/DocGlobals.HH"
public CDolDocGlbls doldoc;
MemSet(&doldoc,0,sizeof(CDolDocGlbls));

#help_index "God"
#define BIBLE_FILENAME	"::/Misc/Bible.TXT.Z"

#include "DocExt"
#include "DocLock"
#include "DocBin"
#include "DocNew"
#include "DocForm"
#include "DocDblBuf"
#include "DocPlain"
#include "DocInit"
#include "DocHighlight"
#include "DocRecalcLib"
#include "DocRecalc"
#include "DocFile"
#include "DocClipBoard"
#include "DocRun"
#include "DocGet"
#include "DocChar"
#include "DocFind"
#include "DocLink"
#include "DocEd"
#include "DocPopUp"
#include "DocGr"
#include "DocMacro"
#include "DocWidgetWiz"
#include "DocPutKey"
#include "DocPutS"
#include "DocCodeTools"
#include "DocTree"
#include "DocTerm"

KeyDevAdd(&KDDocPutKey,&KDDocPutS,0x80000000,TRUE);
fp_getstr2=&DocGetStr2;
fp_doc_put=&DocPut;

Cd("..");;
