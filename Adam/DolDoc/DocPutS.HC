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

U0 DocDump(CDoc *doc,I64 uS_delay=0)
{
  U8 *st;
  CDocEntry *doc_e,*doc_e2;
  Bool unlock=DocLock(doc);
  doc_e=doc->head.next;
  while (doc_e!=doc) {
    st=DocScanLine(doc,doc_e,NULL,&doc_e2);
    "%s",st;
    Free(st);
    doc_e=doc_e2;
    if (doc_e->type_u8==DOCT_NEW_LINE) {
      '\n';
      Busy(uS_delay);
      doc_e=doc_e->next;
    }
  }
  if (unlock)
    DocUnlock(doc);
}

public CDocEntry *DocPutLine(CDoc *doc=NULL,CDocEntry *doc_e)
{//Send line from other doc to StdOut $LK,"DocPut",A="MN:DocPut"$.
  I64 ch;
  U8 *ptr,*ptr2;
  Bool unlock;
  if (!doc && !(doc=DocPut) || doc->doc_signature!=DOC_SIGNATURE_VAL)
    return NULL;
  unlock=DocLock(doc);
  while (doc_e!=doc && doc_e->type_u8!=DOCT_NEW_LINE) {
    if (doc_e->de_flags&DOCEF_TAG) {
      ptr=doc_e->tag;
      do {
	ptr2=ptr;
	while (ch=*ptr)
	  if (ch=='$$')
	    break;
	  else
	    ptr++;
	*ptr=0;
	"%s",ptr2;
	*ptr=ch;
	if (ch=='$$') {
	  "$$$$";
	  ptr++;
	}
      } while (ch);
    } else if (doc_e->type_u8==DOCT_TAB)
      '\t';
    doc_e=doc_e->next;
  }
  '\n';
  if (doc_e!=doc)
    doc_e=doc_e->next;
  if (unlock)
    DocUnlock(doc);
  return doc_e;
}

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
