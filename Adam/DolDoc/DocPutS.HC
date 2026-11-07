#help_index "DolDoc/Output;StdOut/DolDoc"

#include "/Adam/DolDoc/DocPutSCore.HC"

#include "/Adam/DolDoc/DocPrintPartialCore.HC"

Bool KDDocPutS(U8 *st)
{
  CDoc *doc;
  if (doc=DocPut)
    DocPrintPartial(doc,"%s",st);
  return FALSE;
}

public U0 DocPrintAtomic(CDoc *doc=NULL,U8 *fmt,...)
{//Prints multiple whole cmds all-at-once. Might need this when printing trees.
  U8 *buf;
  Bool unlock;
  I64 old_flags;
  if (!doc && !(doc=DocPut))
    return;
  buf=StrPrintJoin(NULL,fmt,argc,argv);
  unlock=DocLock(doc);
  old_flags=doc->flags;
  doc->flags|=DOCF_NO_CURSOR;
  DocPrint(doc,"%s",buf);
  DocRecalc(doc);
  doc->flags=old_flags;
  if (unlock)
    DocUnlock(doc);
  Free(buf);
}

#include "/Adam/DolDoc/DocDumpCore.HC"

#include "/Adam/DolDoc/DocPutLineCore.HC"

#help_index "Debugging/Dump;DolDoc/Cmd Line (Typically);"\
	"Cmd Line (Typically);DolDoc/Output;StdOut/DolDoc"
public U0 DocDm(U8 *buf,I64 cnt=0x80)
{//Dump live chunk of mem showing addresses. Can be edited.
  CDocEntry *doc_e;
  CDoc *doc=DocPut;
  Bool unlock=DocLock(doc);
  doc_e=DocPrint(doc,"$$HX-Z,%d,16$$",cnt);
  doc_e->data=buf;
  doc->cur_entry=doc_e->next;
  DocRecalc(doc);
  if (unlock)
    DocUnlock(doc);
}

public U0 DocD(U8 *buf,I64 cnt=0x80)
{//Dump live chunk of mem showing offsets. Can be edited.
  CDocEntry *doc_e;
  CDoc *doc=DocPut;
  Bool unlock=DocLock(doc);
  doc_e=DocPrint(doc,"$$HX,%d,16$$",cnt);
  doc_e->data=buf;
  doc->cur_entry=doc_e->next;
  DocRecalc(doc);
  if (unlock)
    DocUnlock(doc);
}
