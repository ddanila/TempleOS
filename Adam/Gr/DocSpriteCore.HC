public CDocEntry *DocSprite(CDoc *doc=NULL,U8 *elems,U8 *fmt=NULL)
{//Put a sprite into a document.  You can, optionally, supply a fmt string
//for $LK,"DolDoc",A="FI:::/Doc/DolDocOverview.DD"$ cmd with a %d for the bin_num.
  I64 size;
  U8 *st;
  Bool unlock;
  CDocEntry *doc_e;
  CDocBin *tmpb;
  if (!doc && !(doc=DocPut)) return NULL;
  unlock=DocLock(doc);
  size=SpriteSize(elems);
  tmpb=CAlloc(sizeof(CDocBin),doc->mem_task);
  tmpb->size=size;
  tmpb->data=MAlloc(size,doc->mem_task);
  MemCpy(tmpb->data,elems,size);
  tmpb->num=doc->cur_bin_num;
  tmpb->use_cnt=1;
  QueIns(tmpb,doc->bin_head.last);
  if (fmt)
    st=MStrPrint(fmt,doc->cur_bin_num++);
  else
    st=MStrPrint("$$SP,\"\",BI=%d$$",doc->cur_bin_num++);
  doc_e=DocPrint(doc,"%s",st);
  Free(st);
  doc_e->bin_data=tmpb;
  if (doc_e && doc_e->de_flags&DOCEF_TAG && doc_e->tag && *doc_e->tag)
    tmpb->tag=StrNew(doc_e->tag,doc->mem_task);
  if (unlock)
    DocUnlock(doc);
  return doc_e;
}
