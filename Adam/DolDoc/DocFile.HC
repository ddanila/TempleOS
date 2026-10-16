#help_index "DolDoc/File"

#include "/Adam/DolDoc/DocLoadCore.HC"

public CDoc *DocRead(U8 *name=NULL,I64 flags=0)
{//Fetch doc from disk. See $LK,"flags",A="MN:DOCF_PLAIN_TEXT"$.
  CDoc *doc=DocNew;
  U8 *src,*name2;
  I64 size=0;
  CDirContext *dirc;
  if (!name) name=blkdev.tmp_filename;
  doc->flags|=flags;
  name2=FileNameAbs(name);
  StrCpy(doc->filename.name,name2);
  if (src=FileRead(name2,&size,&doc->file_attr)) {
    if (dirc=DirContextNew(name2)) {
      DocLoad(doc,src,size);
      DirContextDel(dirc);
    }
    Free(src);
  }
  Free(name2);
  return doc;
}

#include "/Adam/DolDoc/DocSaveCore.HC"

public Bool DocWrite(CDoc *doc,Bool prompt=FALSE)
{//Store doc to disk.
  I64 size;
  U8 *buf;
  if (prompt && !DocForm(&doc->filename) ||
	doc->filename.name[0]=='A' && doc->filename.name[2]==':')
    return FALSE;  //CANCEL || LK_DOC,LK_DOC_ANCHOR,LK_DOC_FIND,LK_DOC_LINE?
  buf=DocSave(doc,&size);
  FileWrite(doc->filename.name,buf,size,0,doc->file_attr);
  Free(buf);
  return TRUE;
}

#help_index "DolDoc"
#include "/Adam/DolDoc/DocInsertDocumentCore.HC"

#help_index "DolDoc/Compiler;Compiler/Directive"
public U0 StreamDoc(CDoc *doc)
{//Inject doc into compile stream. Use inside #exe{}.
//TODO: $LK,"DocRst",A="MN:DocRst"$
  Bool unlock_doc=DocLock(doc);
  CDocEntry *doc_e=doc->head.next;
  while (doc_e!=doc) {
    if (doc_e->type_u8==DOCT_TEXT)
      StreamPrint("%s",doc_e->tag);
    else if (doc_e->type_u8==DOCT_NEW_LINE)
      StreamPrint("\n");
    else if (doc_e->type_u8==DOCT_TAB)
      StreamPrint("\t");
    doc_e=doc_e->next;
  }
  if (unlock_doc)
    DocUnlock(doc);
}

#help_index "DolDoc"
#include "/Adam/DolDoc/DocUndoCore.HC"

#help_index "Graphics/GR Files;DolDoc/Output;StdOut/DolDoc"
#include "/Adam/DolDoc/DocTypeCore.HC"

#help_index "DolDoc/File"

public U8 *DocLineRead(U8 *filename,I64 line,CTask *mem_task=NULL)
{//Extract line from stored doc file. (Slow.)
  U8 *res=NULL;
  CDoc *doc=DocRead(filename,DOCF_PLAIN_TEXT_TABS|DOCF_NO_CURSOR);
  if (DocGoToLine(doc,line) && doc->cur_entry->type_u8==DOCT_TEXT)
    res=StrNew(doc->cur_entry->tag,mem_task);
  DocDel(doc);
  return res;
}

public U8 *DocLineWrite(U8 *filename,I64 line,U8 *st)
{//Write line to stored doc file. (Slow.)
  U8 *res=NULL;
  CDoc *doc=DocRead(filename,DOCF_PLAIN_TEXT_TABS|DOCF_NO_CURSOR);
  if (DocGoToLine(doc,line)) {
    if (doc->cur_entry->type_u8==DOCT_TEXT) {
      Free(doc->cur_entry->tag);
      doc->cur_entry->tag=StrNew(st);
    } else
      DocPrint(doc,"%s",st);
    DocTop(doc);
    DocWrite(doc);
  }
  DocDel(doc);
  return res;
}
