//Shared HolyC type, array-dimension and variadic-argument parsing.
#include "/Compiler/PrsType.HH"
#include "/Compiler/PrsArrayDimsCore.HC"

CHashClass *PrsTypeCore(CPrsTypeServices *services,CCmpCtrl *cc,CHashClass **_tmpc1,
  I64 *_mode,CMemberLst *tmpm,U8 **_ident,CHashFun **_fun_ptr,
  CHashExport **_tmpex,CArrayDim *tmpad,I64 fsp_flags)
{
  I64 k,ptr_stars_cnt,mode=*_mode;
  CHashClass *tmpc1=*_tmpc1,*tmpc2;
  CHashFun *fun_ptr=NULL;
  CHashExport *tmpex=NULL;

  pt_start:
  if (!tmpc1 || !(tmpc1->type & (HTT_CLASS|HTT_INTERNAL_TYPE)))
    (*services->report)(services->context,cc,0,"Invalid class at ");

  ptr_stars_cnt=0;
  while (cc->token=='*') {
    if (mode.u8[1]) {
      (*services->snapshot_drop)(services->context,cc);
      (*services->snapshot_push)(services->context,cc);
    }
    (*services->lex)(services->context,cc);
    tmpc1++;
    if (++ptr_stars_cnt>PTR_STARS_NUM)
      (*services->report)(services->context,cc,0,"Too many *'s at ");
  }

  k=PrsKeyWord(cc);
  if (k==KW_UNION || k==KW_CLASS) {
    (*services->lex)(services->context,cc);
    tmpc2=(*services->class_join)(services->context,cc,k,fsp_flags,mode&255==PRS0_EXTERN);
    tmpc2->fwd_class=tmpc1;
    tmpc1=tmpc2;
    if (_tmpc1) *_tmpc1=tmpc1;
    mode=PRS0_NULL|PRS1_NULL;
    goto pt_start;
  }

  if (cc->token=='(') {
    if ((*services->lex)(services->context,cc)!='*')
      (*services->report)(services->context,cc,0,"Expecting '*' at ");
    ptr_stars_cnt=1; //fun_ptr
    while ((*services->lex)(services->context,cc)=='*')
      ptr_stars_cnt++; //fun_ptr
    if (ptr_stars_cnt>PTR_STARS_NUM)
      (*services->report)(services->context,cc,0,"Too many *'s at ");
  } else
    ptr_stars_cnt=-1; //fun_ptr

  if (_ident) {
    if (cc->token==TK_IDENT) {
      tmpex=cc->hash_entry;
      *_ident=cc->cur_str;
      cc->cur_str=NULL;
      (*services->lex)(services->context,cc);
    } else {
      if (!mode.u8[1])
	*_ident=NULL;
      else if (cc->token==',' || cc->token==';' || cc->token==')') {
	tmpex=NULL;
	*_ident=(*services->duplicate)(services->context,"_anon_");
	tmpm->flags|=MLF_NO_UNUSED_WARN;
      } else
	(*services->report)(services->context,cc,0,"Expecting identifier at ");
    }
  }

  if (ptr_stars_cnt>=0) { //fun_ptr
    if (cc->token!=')')
      (*services->report)(services->context,cc,0,"Missing ')' at ");
    if ((*services->lex)(services->context,cc)!='(')
      (*services->report)(services->context,cc,0,"Expecting '(' at ");
    fun_ptr=(*services->fun_join)(services->context,cc,tmpc1,NULL,fsp_flags)+ptr_stars_cnt;
    tmpc1=services->types[RT_PTR]+ptr_stars_cnt;
  }
  PrsArrayDimsCore(services,cc,mode,tmpad);

  tmpc2=OptClassFwd(tmpc1);
  if (tmpc2->ptr_stars_cnt) {
    tmpc2-=tmpc2->ptr_stars_cnt;
    if (tmpc2->type&HTT_INTERNAL_TYPE && !tmpc2->size)
      (*services->report)(services->context,cc,1,"use \"U8 *\" instead of \"U0 *\" at ");
  }

  if (_mode)	*_mode=mode;
  if (_fun_ptr)	*_fun_ptr=fun_ptr;
  if (_tmpex)	*_tmpex=tmpex;
  return tmpc1;
}

U0 PrsDotDotDotCore(CPrsTypeServices *services,CCmpCtrl *cc,CHashFun *tmpf,I64 _reg)
{
  CMemberLst *tmpm;
  CArrayDim *tmpad;

  Bts(&tmpf->flags,Ff_DOT_DOT_DOT);

  (*services->lex)(services->context,cc);
  tmpm=(*services->member_new)(services->context,_reg);
  tmpm->flags=MLF_DOT_DOT_DOT;
  tmpm->member_class=services->types[RT_I64];
  tmpm->str=(*services->duplicate)(services->context,"argc");
  tmpm->offset=tmpf->size;
  tmpm->size=8;
  tmpf->size+=8;
  (*services->member_add)(services->context,cc,tmpm,tmpf,PRS1B_FUN_ARG);

  tmpm=(*services->member_new)(services->context,_reg);
  tmpm->flags=MLF_DOT_DOT_DOT;
  tmpm->member_class=services->types[RT_I64];
  tmpm->str=(*services->duplicate)(services->context,"argv");
  tmpm->dim.total_cnt=127; //arbitrary
  tmpm->dim.next=tmpad=(*services->allocate)(services->context,sizeof(CArrayDim));
  tmpad->next=NULL;
  tmpad->cnt=127; //arbitrary
  tmpad->total_cnt=1;
  tmpm->offset=tmpf->size;
  tmpm->size=8; //Close enough
  tmpf->size+=8;//Close enough
  (*services->member_add)(services->context,cc,tmpm,tmpf,PRS1B_FUN_ARG);

  if (cc->token==')')
    (*services->lex)(services->context,cc);
}
