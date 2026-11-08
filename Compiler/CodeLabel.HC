#ifndef COC_LABEL_IMPL
#define COC_LABEL_IMPL COCGoToLabelFind
#endif
CCodeMisc *COC_LABEL_IMPL(CCmpCtrl *cc,U8 *name)
{
  CCodeMisc *cm=cc->coc.coc_next_misc;
  while (cm!=&cc->coc.coc_next_misc) {
    if ((cm->type==CMT_GOTO_LABEL||cm->type==CMT_ASM_LABEL) &&
	  !StrCmp(cm->str,name))
      return cm;
    cm=cm->next;
  }
  return 0;
}
