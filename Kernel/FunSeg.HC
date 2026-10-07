#include "/Kernel/FunSegLookupCore.HC"

CHash *FunSegFind(U8 *addr,I64 *_offset)
{//See $LK,"Hash",A="HI:Hash"$.
  CHash *res=NULL;
  Bool has_lower=FALSE;
  CTask *task;
  CHashTable *h;
  CCPU *c;
  U64 i,best=0xFFFF;
  if (!ChkCodePtr(addr)) {
    *_offset=best;
    return NULL;
  }
  if (IsDbgMode)
    for (i=0;i<mp_cnt;i++) {
      c=&cpu_structs[i];
      task=c->seth_task;
      do {
	if (!TaskValidate(task)) goto fs_abort_task;
	h=task->hash_table;
	while (h) {
	  HashFunSegFind(h,addr,&has_lower,&best,&res);
	  h=h->next;
	}
	task=task->next_task;
      } while (task!=c->seth_task);
fs_abort_task:
    }
  else {
    h=Fs->hash_table;
    while (h) {
      HashFunSegFind(h,addr,&has_lower,&best,&res);
      h=h->next;
    }
  }
  *_offset=best;
  return res;
}

#include "/Kernel/FunSegCacheCore.HC"

#include "/Kernel/StrPrintFunSegCore.HC"

#include "/Kernel/SourceLinkCore.HC"

Bool PutSrcLink(U8 *addr,I64 cnt=1,U8 *buf=NULL)
{//Put to StdOut a $LK,"DolDoc",A="FI:::/Doc/DolDocOverview.DD"$ file,line link to src of addr.
  U8 *src;
  if (src=SrcEdLink(addr,cnt)) {
    if (buf)
      StrPrint(buf,"$$LK,\"%p\",A=\"%s\"$$",addr,src);
    else
      "$$LK,\"%p\",A=\"%s\"$$",addr,src;
    Free(src);
    return TRUE;
  } else if (buf)
    *buf=0;
  return FALSE;
}

Bool E(U8 *addr,I64 cnt=512,I64 edf_dof_flags=0)
{//Edit src at addr.
  U8 *st;
  Bool res=FALSE;
  if (st=SrcEdLink(addr,cnt)) {
    if (IsRaw)
      res=EdLiteFileLine(st,edf_dof_flags);
    else
      res=Ed(st,edf_dof_flags);
    Free(st);
  }
  return res;
}

Bool Man(U8 *st,I64 edf_dof_flags=0)
{//Owner's manual for symbol.  Edit src code for symbol.
  Bool res=FALSE;
  U8 **st2;
  CHashSrcSym *tmph;
  if (IsRaw) {
    if ((tmph=HashFind(st,Fs->hash_table,HTG_SRC_SYM)) && tmph->src_link)
      res=EdLiteFileLine(tmph->src_link,edf_dof_flags);
  } else {
    st2=MStrPrint("MN:%s",st);
    res=Ed(st2,edf_dof_flags);
    Free(st2);
  }
  return res;
}
