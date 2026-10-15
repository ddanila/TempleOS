#help_index "DolDoc"

#include "/Adam/DolDoc/DocDollarServices.HH"
I64 DocDollarHostLex(U8 *context,CCmpCtrl *cc){return Lex(cc);}
I64 DocDollarHostExpression(U8 *context,CCmpCtrl *cc){return LexExpression(cc);}
I64 DocDollarHostInteger(U8 *context,CCmpCtrl *cc){return LexExpressionI64(cc);}
U8 *DocDollarHostString(U8 *context,CCmpCtrl *cc){return LexExtStr(cc);}
U0 DocDollarHostServices(CDocDollarServices *services)
{
  services->context=NULL; services->lex=&DocDollarHostLex;
  services->expression=&DocDollarHostExpression;
  services->integer_expression=&DocDollarHostInteger;
  services->string=&DocDollarHostString;
}
#include "/Adam/DolDoc/DocDollarFlagsCore.HC"
I64 PrsDocFlagSingle(CCmpCtrl *cc,I64 *_de_flags,U32 *_type,Bool turn_on)
{
  CDocDollarServices services;DocDollarHostServices(&services);
  return PrsDocFlagSingleCore(&services,cc,_de_flags,_type,turn_on);
}
I64 PrsDocFlags(CCmpCtrl *cc,I64 *_de_flags,U32 *_type)
{
  CDocDollarServices services;DocDollarHostServices(&services);
  return PrsDocFlagsCore(&services,cc,_de_flags,_type);
}

#include "/Adam/DolDoc/DocPlainTextCore.HC"

#include "/Adam/DolDoc/DocDollarParseCore.HC"
CDocEntry *PrsDollarCmd(CDoc *doc,U8 *st)
{
  CDocDollarServices services;
  CCmpCtrl *cc=CmpCtrlNew(st,CCF_DONT_FREE_BUF);
  CDocEntry *result;
  DocDollarHostServices(&services);
  try { result=PrsDollarCmdCore(&services,cc,doc,st); }
  catch { CmpCtrlDel(cc); }
  CmpCtrlDel(cc);
  return result;
}

U0 DocEntryToggle(CDoc *doc)
{
  Bool unlock=DocLock(doc),old_color_names;
  CDocEntry *doc_ce=doc->cur_entry,*cl1,*doc_ce2;
  U8 ch,*st,*st2;
  I64 i,j,k;
  if (doc_ce!=doc &&
	!(doc->flags&(DOCF_PLAIN_TEXT|DOCF_PLAIN_TEXT_TABS))) {
    if (doc_ce->type_u8==DOCT_TEXT && !(doc_ce->de_flags &
	  ~(DOCEF_TAG|DOCG_BL_IV_UL|DOCEF_WORD_WRAP|DOCEF_HIGHLIGHT|
	  DOCEF_SKIP|DOCEF_FILTER_SKIP)) &&
	  !(doc_ce->type&DOCG_BL_IV_UL)) {
      doc_ce2=doc_ce->last;
      for (k=0;k<20;k++) {
	if (doc_ce2!=doc) {
	  cl1=doc_ce2->last;
	  if (doc_ce2->type_u8==DOCT_TEXT &&
		doc_ce->de_flags==doc_ce2->de_flags &&
		doc_ce->type==doc_ce2->type) {
	    i=StrLen(doc_ce2->tag);
	    j=StrLen(doc_ce->tag);
	    st=MAlloc(i+j+1,doc->mem_task);
	    MemCpy(st,doc_ce2->tag,i);
	    MemCpy(st+i,doc_ce->tag,j+1);
	    Free(doc_ce->tag);
	    doc_ce->tag=st;
	    doc_ce->max_col=i+j;
	    doc->cur_col+=i;
	    DocEntryDel(doc,doc_ce2);
	  } else if (doc_ce2->type_u8==DOCT_SOFT_NEW_LINE)
	    DocEntryDel(doc,doc_ce2);
	  else
	    break;
	  doc_ce2=cl1;
	} else
	  break;
      }
      doc_ce2=doc_ce->next;
      for (k=0;k<20;k++) {
	if (doc_ce2!=doc) {
	  cl1=doc_ce2->next;
	  if (doc_ce2->type_u8==DOCT_TEXT &&
		doc_ce->de_flags==doc_ce2->de_flags &&
		doc_ce->type==doc_ce2->type) {
	    i=StrLen(doc_ce->tag);
	    j=StrLen(doc_ce2->tag);
	    st=MAlloc(i+j+1,doc->mem_task);
	    MemCpy(st,doc_ce->tag,i);
	    MemCpy(st+i,doc_ce2->tag,j+1);
	    Free(doc_ce->tag);
	    doc_ce->tag=st;
	    doc_ce->max_col=i+j;
	    DocEntryDel(doc,doc_ce2);
	  } else if (doc_ce2->type_u8==DOCT_SOFT_NEW_LINE)
	    DocEntryDel(doc,doc_ce2);
	  else
	    break;
	  doc_ce2=cl1;
	} else
	  break;
      }
      i=doc->cur_col;
      while (i>doc_ce->min_col && doc_ce->tag[i]!='$$')
	i--;
      j=doc->cur_col+1;
      while (j<doc_ce->max_col && doc_ce->tag[j]!='$$')
	j++;
      if (i<j-1 && doc_ce->min_col<=i<j<doc_ce->max_col &&
	    doc_ce->tag[i]=='$$' && doc_ce->tag[j]=='$$') {
	ch=doc_ce->tag[j+1];
	doc_ce->tag[j+1]=0;
	st=StrNew(doc_ce->tag+i);
	doc_ce->tag[j+1]=ch;
	StrCpy(doc_ce->tag+i,doc_ce->tag+j+1);
	doc->cur_col=i;
	st2=MStrPrint("%q",st);
	if (doc_ce=DocPrint(doc,st2)) {
	  doc->cur_entry=doc_ce;
	  doc->cur_col=doc_ce->min_col;
	}
	Free(st);
	Free(st2);
      }
    } else {
      old_color_names=LBts(&doc->flags,DOCf_COLOR_NAMES);
      st=Doc2PlainText(doc,doc_ce);
      LBEqu(&doc->flags,DOCf_COLOR_NAMES,old_color_names);
      DocEntryDel(doc,doc_ce);
      DocPrint(doc,"$$$$%$$Q$$$$",st);
    }
    DocRecalc(doc);
  }
  if (unlock)
    DocUnlock(doc);
}

U0 DocFlagsToggle(CDoc *doc,I64 tog_flags)
{
  Bool	unlock=DocLock(doc);
  I64 size,flags=doc->flags^tog_flags;
  U8 *st;
  CDocUndo *u_next,*u_last;

  doc->flags=doc->flags&~DOCF_NO_CURSOR|DOCF_COLOR_NAMES;
  st=DocSave(doc,&size);

  u_next=doc->undo_head.next;
  u_last=doc->undo_head.last;
  doc->undo_head.next=doc->undo_head.last=&doc->undo_head;

  DocRst(doc,TRUE);
  doc->undo_head.next=u_next;
  doc->undo_head.last=u_last;
  DocUndoCntSet(doc);
  doc->flags=flags&~(DOCF_NO_CURSOR|DOCG_BL_IV_UL|DOCF_WORD_WRAP);
  DocLoad(doc,st,size);
  doc->flags|=flags&DOCF_NO_CURSOR;
  DocCenter(doc);
  if (unlock)
    DocUnlock(doc);
  Free(st);
}
