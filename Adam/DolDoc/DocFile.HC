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
Bool DocCaptureUndo(CDoc *doc,Bool force=FALSE)
{
  Bool res=FALSE,unlock;
  I64 time_stamp,flags;
  CDocUndo *u;
  if (doc->flags&DOCF_ALLOW_UNDO) {
    unlock=DocLock(doc);
    time_stamp=GetTSC;
    if (doc->flags&DOCF_UNDO_DIRTY &&
	  time_stamp>doc->undo_head.last->time_stamp+cnts.time_stamp_freq<<4 ||
	  force) {
      u=CAlloc(sizeof(CDocUndo),doc->mem_task);
      u->time_stamp=time_stamp;
      flags=doc->flags;
      doc->flags&=~DOCF_NO_CURSOR;
      u->body=DocSave(doc,&u->size);
      doc->flags=flags;
      QueIns(u,doc->undo_head.last);
      doc->flags&=~DOCF_UNDO_DIRTY;
      doc->undo_cnt++;
      u->doc_flags=doc->flags;
      res=TRUE;
      if (doc->flags&DOCF_AUTO_SAVE)
	DocWrite(doc);
    }
    if (unlock)
      DocUnlock(doc);
  }
  return res;
}
 
U0 DocUndoRestore(CDoc *doc)
{
  Bool unlock=DocLock(doc);
  CDocUndo *u=doc->undo_head.last,*u_next,*u_last;
  if (u!=&doc->undo_head) {
    QueRem(u);
    u_next=doc->undo_head.next;
    u_last=doc->undo_head.last;
    QueInit(&doc->undo_head);
    DocRst(doc,TRUE);
    doc->flags=u->doc_flags&~DOCF_NO_CURSOR;
    DocLoad(doc,u->body,u->size);
    doc->flags=u->doc_flags;
    DocUndoDel(doc,u);
    doc->undo_head.next=u_next;
    doc->undo_head.last=u_last;
  }
  DocUndoCntSet(doc);
  doc->flags&=~DOCF_UNDO_DIRTY;
  if (unlock)
    DocUnlock(doc);
}

#help_index "Graphics/GR Files;DolDoc/Output;StdOut/DolDoc"
public Bool DocType(CDoc *doc=NULL,U8 *filename,I64 trailing_new_lines=1)
{//Output txt or graphic file to document.
  Bool res=FALSE;
  CDoc *doc2;
  if (!doc && !(doc=DocPut) || doc->doc_signature!=DOC_SIGNATURE_VAL)
    return FALSE;
  if (FilesFindMatch(filename,FILEMASK_TXT)) {
    doc2=DocRead(filename);
    DocInsDoc(doc,doc2);
    if (IsRaw)
      DocDump(doc2,100000);
    DocDel(doc2);
    res=TRUE;
  } else if (FilesFindMatch(filename,"*.GR*")) {
    DocGR(doc,filename);
    res=TRUE;
  }
  if (res)
    DocPrint(doc,"%h*c",trailing_new_lines,'\n');
  return res;
}

#help_index "Graphics/GR Files;"\
	"File/Cmd Line (Typically);DolDoc/Cmd Line (Typically);"\
	"StdOut;Cmd Line (Typically)"
public Bool Type(U8 *filename,I64 trailing_new_lines=1)
{//Output txt or graphic file to command line.
  return DocType(,filename,trailing_new_lines);
}

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
