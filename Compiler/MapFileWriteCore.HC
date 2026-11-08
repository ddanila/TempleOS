U0 MapFileWrite(CHashTable *h,U8 *map_name,U8 drv_let)
{
  CHashSrcSym *tmph;
  I64 i,size;
  U8 *src_link;
  CDoc *doc;
  CDocBin *tmpb;
  CDbgInfo *dbg_info;

  doc=DocNew(map_name);
  doc->flags|=DOCF_NO_CURSOR;
  for (i=0;i<=h->mask;i++) {
    tmph=h->body[i];
    while (tmph) {
      if (tmph->src_link && !(tmph->type & (HTF_IMPORT | HTF_PRIVATE))) {
	src_link=StrNew(tmph->src_link);
	if (drv_let && StrLen(src_link)>=4)
	  src_link[3]=drv_let;
	if (dbg_info=tmph->dbg_info) {
	  size=offset(CDbgInfo.body)+
		sizeof(U32)*(dbg_info->max_line+2-dbg_info->min_line);
	  if (size>MSize(dbg_info)) {
	    "Corrupt Map Entry\n";
	    dbg_info=NULL;
	  } else {
	    if (dbg_info->min_line<=dbg_info->max_line) {
	      tmpb=CAlloc(sizeof(CDocBin));
	      tmpb->size=size;
	      tmpb->data=MAlloc(size);
	      MemCpy(tmpb->data,dbg_info,size);
	      tmpb->num=doc->cur_bin_num++;
	      tmpb->use_cnt=1;
	      QueIns(tmpb,doc->bin_head.last);
	    } else
	      dbg_info=NULL;
	  }
	}
	if (dbg_info)
	  DocPrint(doc,"$$LK,\"%s\",A=\"%s\",BI=%d$$\n",
		tmph->str,src_link,tmpb->num);
	else
	  DocPrint(doc,"$$LK,\"%s\",A=\"%s\"$$\n",tmph->str,src_link);

	Free(src_link);
      }
      tmph=tmph->next;
    }
  }
  DocBinsValidate(doc);
  DocWrite(doc);
  DocDel(doc);
}
