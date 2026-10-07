U0 DocDataFmt(CDoc *doc,CDocEntry *doc_e,I64 d=DOCM_CANCEL)
{
  I64 i;
  U8 *ptr,*ptr2;
  CHashDefineStr *tmph;
  if (doc_e->type_u8==DOCT_DATA && doc_e->de_flags&DOCEF_AUX_STR ||
	doc_e->type_u8==DOCT_CHECK_BOX || doc_e->de_flags & DOCEF_LST) {
    if (d==DOCM_CANCEL) {
      if (doc_e->de_flags&DOCEF_DEREF_DATA &&
	    !(doc_e->de_flags&DOCEF_REMALLOC_DATA)) {
	if (!(ptr=doc_e->data)) return;
      } else
	ptr=&doc_e->data;
      switch (doc_e->raw_type) {
	case RT_I0:
	case RT_U0:	d=0;		break;
	case RT_I8:	d=*ptr(I8 *);	break;
	case RT_U8:	d=*ptr(U8 *);	break;
	case RT_I16:	d=*ptr(I16 *);	break;
	case RT_U16:	d=*ptr(U16 *);	break;
	case RT_I32:	d=*ptr(I32 *);	break;
	case RT_U32:	d=*ptr(U32 *);	break;
	default:	d=*ptr(I64 *);
      }
    }
    if (doc_e->type_u8==DOCT_DATA) {
      if (doc_e->de_flags & DOCEF_REMALLOC_DATA) {
	ptr=MStrPrint(doc_e->aux_str,d,doc_e->my_fmt_data);
	i=StrLen(ptr);
	if (!doc_e->data) {
	  doc_e->data=CAlloc(2,doc->mem_task);
	  doc_e->len=MSize(doc_e->data)-2;
	}
	if (doc_e->len+doc_e->min_col>i)
	  MemCpy(doc_e->tag,ptr,i+1);
	else {
	  ptr2=MAlloc(i+8,doc->mem_task);
	  doc_e->len=MSize(ptr2)-doc_e->min_col-2;	 //See $LK,"DataTagWidth",A="FA:::/Adam/DolDoc/DocPlain.HC,DataTagWidth"$
	  MemCpy(ptr2,ptr,i+1);
	  Free(doc_e->tag);
	  doc_e->tag=ptr2;
	}
	Free(ptr);
      } else {
	StrPrint(doc_e->tag,doc_e->aux_str,d,doc_e->my_fmt_data);
	i=StrLen(doc_e->tag);
      }
      if (doc_e->de_flags & DOCEF_HAS_TERMINATOR) {
	doc_e->tag[i++]='_';
	doc_e->tag[i]=0;
      }
      doc_e->max_col=i;
    } else if (doc_e->de_flags & DOCEF_LST) {
      if (doc_e->de_flags & DOCEF_DEFINE && (tmph=HashFind(doc_e->define_str,
	    doc->win_task->hash_table,HTT_DEFINE_STR)) && 0<=d<tmph->cnt) {
	ptr=MStrPrint("[%s]",tmph->sub_idx[d]);
	Free(doc_e->tag);
	doc_e->tag=StrNew(ptr,doc->mem_task);
	Free(ptr);
      } else {
	Free(doc_e->tag);
	doc_e->tag=StrNew("[]",doc->mem_task);
      }
    } else {
      if (d)
	doc_e->de_flags|=DOCEF_CHECKED_COLLAPSED;
      else
	doc_e->de_flags&=~DOCEF_CHECKED_COLLAPSED;
    }
  }
}

U0 DocDataScan(CDoc *doc,CDocEntry *doc_e)
{
  I64 i,d;
  U8 *ptr,*ptr1,*ptr2;
  CHashDefineStr *tmph;
  if (doc_e->type_u8==DOCT_DATA && doc_e->de_flags&DOCEF_AUX_STR ||
	doc_e->type_u8==DOCT_CHECK_BOX || doc_e->de_flags & DOCEF_LST) {
    if (doc_e->de_flags&DOCEF_DEREF_DATA &&
	  !(doc_e->de_flags&DOCEF_REMALLOC_DATA)) {
      if (!(ptr=doc_e->data)) return;
    } else
      ptr=&doc_e->data;
    if (doc_e->type_u8==DOCT_DATA) {
      i=StrLen(doc_e->tag);
      if (doc_e->de_flags & DOCEF_HAS_TERMINATOR)
	doc_e->tag[--i]=0;
      if (i>doc_e->len+doc_e->min_col)
	doc_e->tag[doc_e->len+doc_e->min_col]=0;
      if (RT_I8<=doc_e->raw_type<=RT_U32) {
	StrScan(doc_e->tag,doc_e->aux_str,&d,doc_e->my_fmt_data);
	if (doc_e->de_flags & DOCEF_HAS_TERMINATOR)
	  doc_e->tag[i]='_';
      } else if (RT_I64<=doc_e->raw_type<=RT_UF64) {
	if (doc_e->de_flags & DOCEF_REMALLOC_DATA) {
	  ptr=MAlloc(i-doc_e->min_col+8,doc->mem_task);
	  MemCpy(ptr,doc_e->tag+doc_e->min_col,i-doc_e->min_col+1);
	  Free(doc_e->data);
	  doc_e->data=ptr;
	  doc_e->len=MSize(ptr)-1;
	} else
	  StrScan(doc_e->tag,doc_e->aux_str,ptr,doc_e->my_fmt_data);
	if (doc_e->de_flags & DOCEF_HAS_TERMINATOR)
	  doc_e->tag[i]='_';
	return;
      }
    } else if (doc_e->de_flags & DOCEF_LST) {
      d=0;
      if (doc_e->tag && doc_e->de_flags & DOCEF_DEFINE &&
	    (tmph=HashFind(doc_e->define_str,
	    doc->win_task->hash_table,HTT_DEFINE_STR))) {
	ptr1=ptr2=StrNew(doc_e->tag);
	if (*ptr2=='[') {
	  ptr2++;
	  i=StrLen(ptr2);
	  if (ptr2[i-1]==']')
	    ptr2[i-1]=0;
	}
	d=LstMatch(ptr2,tmph->data);
	Free(ptr1);
      }
    } else {
      if (doc_e->de_flags & DOCEF_CHECKED_COLLAPSED)
	d=TRUE;
      else
	d=FALSE;
    }
    switch (doc_e->raw_type) {
      case RT_I8:
      case RT_U8:
	*ptr(U8 *)=d;
      case RT_I0:
      case RT_U0:
	break;
      case RT_I16:
      case RT_U16:
	*ptr(U16 *)=d;
	break;
      case RT_I32:
      case RT_U32:
	*ptr(U32 *)=d;
	break;
      default:
	*ptr(I64 *)=d;
    }
  }
}

