#ifndef I386_PUBLIC_DOCUMENT_INCLUDED
#define I386_PUBLIC_DOCUMENT_INCLUDED
#include "/Kernel/DocTypes.HH"
#help_index "DolDoc"
public _extern _DOC_LOCK Bool DocLock(CDoc *doc);
public _extern _DOC_UNLOCK Bool DocUnlock(CDoc *doc);
public _extern _DOC_PUT CDoc *DocPut(CTask *task=0);
public _extern _DOC_DISPLAY CDoc *DocDisplay(CTask *task=0);
public _extern _DOC_BORDER CDoc *DocBorder(CTask *task=0);
#endif
