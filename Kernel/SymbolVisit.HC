#include "/Kernel/SymbolVisit.HH"
//Visit the owned payloads of a live acyclic graph, in destruction order.
//The callback may observe, transfer or release storage; borrowed fields are skipped.
//No graph fields are rewritten. Detach external references before freeing.
U0 SymbolLinkedLstVisit(CSymbolRelease *owner,U8 **node)
{
  U8 **next;
  while(node) {
    next=*node;
    (*owner->release)(owner->context,node);
    node=next;
  }
}
U0 SymbolMemberLstVisit(CSymbolRelease *owner,CMemberLst *tmpm)
{
  CMemberLst *tmpm1;
  CMemberLstMeta *tmp_meta,*tmp_meta1;
  while (tmpm) {
    tmpm1=tmpm->next;
    (*owner->release)(owner->context,tmpm->str);
    SymbolLinkedLstVisit(owner,tmpm->dim.next);
    if (tmpm->flags & MLF_STR_DFT_AVAILABLE)
      (*owner->release)(owner->context,tmpm->dft_val);
    if (tmpm->flags & MLF_FUN)
      SymbolHashVisit(owner,tmpm->fun_ptr-tmpm->fun_ptr->ptr_stars_cnt);
    tmp_meta=tmpm->meta;
    while (tmp_meta) {
      tmp_meta1=tmp_meta->next;
      (*owner->release)(owner->context,tmp_meta->str);
      if (tmp_meta->flags&MLMF_IS_STR)
	(*owner->release)(owner->context,tmp_meta->user_data);
      (*owner->release)(owner->context,tmp_meta);
      tmp_meta=tmp_meta1;
    }
    (*owner->release)(owner->context,tmpm);
    tmpm=tmpm1;
  }
}

U0 SymbolHashVisit(CSymbolRelease *owner,CHashSrcSym *tmph)
{//Visit storage owned by a standard TempleOS hash entry.
  if (!tmph) return;
  if (!(tmph->type&HTT_DICT_WORD))
    (*owner->release)(owner->context,tmph->str);
  if (tmph->type & HTG_SRC_SYM) {
    (*owner->release)(owner->context,tmph->src_link);
    (*owner->release)(owner->context,tmph->idx);
    (*owner->release)(owner->context,tmph->import_name);
    SymbolLinkedLstVisit(owner,tmph->ie_lst);
    if (tmph->type & (HTT_FUN | HTT_EXPORT_SYS_SYM))
      (*owner->release)(owner->context,tmph->dbg_info);
    if (tmph->type & (HTT_FUN | HTT_CLASS))
//Executable storage follows its separate lifetime policy.
      SymbolMemberLstVisit(owner,tmph(CHashClass *)->member_lst_and_root);
    else if (tmph->type&HTT_DEFINE_STR)
      (*owner->release)(owner->context,tmph(CHashDefineStr *)->data);
    else if (tmph->type & HTT_GLBL_VAR) {
      if (!(tmph(CHashGlblVar *)->flags&GVF_ALIAS))
	(*owner->release)(owner->context,tmph(CHashGlblVar *)->data_addr);
      SymbolLinkedLstVisit(owner,tmph(CHashGlblVar *)->dim.next);
      if (tmph(CHashGlblVar *)->fun_ptr)
	SymbolHashVisit(owner,tmph(CHashGlblVar *)->fun_ptr
	      -tmph(CHashGlblVar *)->fun_ptr->ptr_stars_cnt);
    }
  } else if (tmph->type & HTT_FILE)
    (*owner->release)(owner->context,tmph(CHashGeneric *)->user_data0);
  (*owner->release)(owner->context,tmph);
}
