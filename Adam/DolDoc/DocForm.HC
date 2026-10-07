#help_index "DolDoc/Form"

#include "/Adam/DolDoc/DocFormNav.HC"

#include "/Adam/DolDoc/DocFormDataCore.HC"

#help_index "DolDoc/Input;StdIn/DolDoc"
public Bool DocForm(U8 *_d,U8 *class_name=lastclass,
    I64 dof_flags=0,U8 *header=NULL,U8 *footer=NULL)
{//User input. Supply a class name that has format definitions.
//See $LK,"::/Demo/DolDoc/Form.HC"$ and $LK,"::/Demo/LastClass.HC"$.
  CMemberLst *ml;
  CDocEntry *doc_e;
  U8 *format;
  CHashClass *tmpc,*tmpc2;
  CDoc *doc;
  Bool res=FALSE;
  I64 old_border_src=Fs->border_src,has_action;
  if (!(tmpc=HashFind(class_name,Fs->hash_table,HTT_CLASS)))
    return FALSE;
  doc=DocNew;
  doc->desc='Form';
  if (header) DocPrint(doc,"%s",header);
  doc->flags|=DOCF_OVERSTRIKE|DOCF_FORM;
  if (dof_flags&DOF_SIZE_MIN)
    doc->flags|=DOCF_SIZE_MIN;
  ml=tmpc->member_lst_and_root;
  while (ml) {
    if ((format=MemberMetaData("format",ml)) &&
	  (doc_e=DocPrint(doc,"%s",format))) {
      tmpc2=ml->member_class;
      if ((doc_e->type_u8==DOCT_DATA || doc_e->type_u8==DOCT_LST ||
	    doc_e->type_u8==DOCT_CHECK_BOX) && !tmpc2->ptr_stars_cnt) {
	tmpc2=OptClassFwd(tmpc2);
	tmpc2-=tmpc2->ptr_stars_cnt;
	if (tmpc2->type & HTT_INTERNAL_TYPE) {
	  if (ml->dim.next) { //Array
	    if (tmpc2->raw_type==RT_U8 &&
		  LBtr(&doc_e->de_flags,&DOCEf_DFT_LEN)) {
	      doc_e->len=ml->dim.total_cnt;
	      if (doc_e->de_flags&DOCEF_HAS_TERMINATOR)
		doc_e->len--;
	      Free(doc_e->tag);  //See $LK,"DataTagWidth",A="FA:::/Adam/DolDoc/DocPlain.HC,DataTagWidth"$
	      doc_e->tag=MAlloc(doc_e->len+doc_e->min_col+2,
		    doc->mem_task); //+2 because "_\0"
	    }
	  } else if (LBtr(&doc_e->de_flags,DOCEf_DFT_RAW_TYPE))
	    doc_e->raw_type=tmpc2->raw_type;
	}
      }
      if (doc_e->de_flags&DOCEF_REMALLOC_DATA) {
	doc_e->user_data=_d+ml->offset;
	doc_e->data=*doc_e->user_data(U8 **);
      } else
	doc_e->data=_d+ml->offset;
      doc_e->my_fmt_data=MemberMetaData("data",ml);
      DocDataFmt(doc,doc_e);
    }
    ml=ml->next;
  }
  if (footer) DocPrint(doc,"%s",footer);
  if (doc->head.next!=doc)	{
    Fs->border_src=BDS_CONST;
    DocRecalc(doc);
    if (DocEd(doc,dof_flags)) {
      doc_e=doc->cur_entry;
      res=TRUE;
      if (doc_e!=doc) {
	if (DocEntryRun(doc,doc_e,TRUE,&has_action)==DOCM_CANCEL && has_action)
	  res=FALSE;
	DocUnlock(doc);
      }
    }
  }
  doc_e=doc->head.next;
  while (doc_e!=doc) {
    if (doc_e->de_flags&DOCEF_REMALLOC_DATA) {
      *doc_e->user_data(U8 **)=doc_e->data;
      doc_e->data=NULL;
    }
    doc_e=doc_e->next;
  }
  DocDel(doc);
  Fs->border_src=old_border_src;
  return res;
}

#include "/Adam/DolDoc/DocMenuCore.HC"

public I64 PopUpMenu(CDoc *doc,I64 dof_flags=0)
{//Run menu chooser doc in PopUp win task.
  doc->flags|=DOCF_SIZE_MIN | DOCF_FORM;
  return PopUpPrint("DocMenu(0x%X,0x%X);",doc,dof_flags);
}

public Bool PopUpForm(U8 *_d,U8 *class_name=lastclass,
	I64 dof_flags=DOF_SIZE_MIN,U8 *header=NULL,U8 *footer=NULL)
{//See $LK,"::/Demo/DolDoc/Form.HC"$ and $LK,"::/Demo/LastClass.HC"$.
  return PopUpPrint("DocForm(0x%X,0x%X,0x%X,0x%X,0x%X);",_d,class_name,
	dof_flags,header,footer);
}
