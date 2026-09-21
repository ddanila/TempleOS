#include "/Adam/DolDoc/DocBinLife.HC"

I64 DocBinPtrRst(CDoc *doc,CDocEntry *doc_e)
{
  U8 *st,*st2;
  CDoc *doc2;
  CDocBin *tmpb,*tmpb2;
  I64 i,bin_num=0;
  if (doc_e->de_flags&DOCEF_HAS_BIN &&
	doc_e->bin_ptr_link && StrLen(doc_e->bin_ptr_link)) {
    bin_num=doc_e->bin_num;
    st=StrNew(doc_e->bin_ptr_link);
    st2=StrNew(st);
    StrLastRem(st,",",st2);
    i=Str2I64(st2);
    if (i>0||*st2) {
      doc2=DocRead(st);
      if (i>0  && (tmpb2=DocBinFindNum(doc2,i)) ||
	    i==0 && (tmpb2=DocBinFindTag(doc2,st2))) {
	i=1;
	if (bin_num>0) {
	  if (tmpb=DocBinFindNum(doc,bin_num)) {
	    i=tmpb->use_cnt;
	    DocBinDel(doc,tmpb);
	  }
	} else
	  bin_num=doc->cur_bin_num++;
	tmpb=MAllocIdent(tmpb2,doc->mem_task);
	tmpb->use_cnt=i;
	tmpb->data=MAllocIdent(tmpb2->data,doc->mem_task);
	tmpb->num=bin_num;
	doc_e->bin_data=tmpb;
	if (doc_e->de_flags&DOCEF_TAG && doc_e->tag && *doc_e->tag)
	  tmpb->tag=StrNew(doc_e->tag,doc->mem_task);
	else
	  tmpb->tag=NULL;
	QueIns(tmpb,doc->bin_head.last);
      } else
	bin_num=0;
      DocDel(doc2);
    } else
      bin_num=0;
    Free(st2);
    Free(st);
    doc_e->bin_num=bin_num;
  }
  return bin_num;
}
