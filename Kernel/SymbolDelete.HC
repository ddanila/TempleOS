#include "/Kernel/SymbolDelete.HH"
//Live acyclic ownership graph; detach external references before destruction.
//The release callback accepts zero. Shared/borrowed fields follow legacy policy.
U0 SymbolLinkedLstDel(CSymbolRelease *owner,U8 **node)
{
  U8 **next;
  while(node) {
    next=*node;
    (*owner->release)(owner->context,node);
    node=next;
  }
}
U0 SymbolMemberLstDel(CSymbolRelease *owner,CMemberLst *tmpm)
{
  CMemberLst *tmpm1;
  CMemberLstMeta *tmp_meta,*tmp_meta1;
  while (tmpm) {
    tmpm1=tmpm->next;
    (*owner->release)(owner->context,tmpm->str);
    SymbolLinkedLstDel(owner,tmpm->dim.next);
    if (tmpm->flags & MLF_STR_DFT_AVAILABLE)
      (*owner->release)(owner->context,tmpm->dft_val);
    if (tmpm->flags & MLF_FUN)
      SymbolHashDel(owner,tmpm->fun_ptr-tmpm->fun_ptr->ptr_stars_cnt);
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

U0 SymbolClassMemberLstDel(CSymbolRelease *owner,CHashClass *tmpc)
{
  SymbolMemberLstDel(owner,tmpc->member_lst_and_root);
  tmpc->size=0;
  tmpc->last_in_member_lst=&tmpc->member_lst_and_root;
  tmpc->member_lst_and_root=0;
  tmpc->member_class_base_root=0;
  tmpc->member_cnt=0;
  if (tmpc->type&HTT_FUN)
    tmpc(CHashFun *)->arg_cnt=0;
}

U0 SymbolHashDel(CSymbolRelease *owner,CHashSrcSym *tmph)
{//Free a std TempleOS system hash entry.
  if (!tmph) return;
  if (!(tmph->type&HTT_DICT_WORD))
    (*owner->release)(owner->context,tmph->str);
  if (tmph->type & HTG_SRC_SYM) {
    (*owner->release)(owner->context,tmph->src_link);
    (*owner->release)(owner->context,tmph->idx);
    (*owner->release)(owner->context,tmph->import_name);
    SymbolLinkedLstDel(owner,tmph->ie_lst);
    if (tmph->type & (HTT_FUN | HTT_EXPORT_SYS_SYM))
      (*owner->release)(owner->context,tmph->dbg_info);
    if (tmph->type & (HTT_FUN | HTT_CLASS))
//Assumes code not on heap, so doesn't Free.
      SymbolClassMemberLstDel(owner,tmph);
    else if (tmph->type&HTT_DEFINE_STR)
      (*owner->release)(owner->context,tmph(CHashDefineStr *)->data);
    else if (tmph->type & HTT_GLBL_VAR) {
      if (!(tmph(CHashGlblVar *)->flags&GVF_ALIAS))
	(*owner->release)(owner->context,tmph(CHashGlblVar *)->data_addr);
      SymbolLinkedLstDel(owner,tmph(CHashGlblVar *)->dim.next);
      if (tmph(CHashGlblVar *)->fun_ptr)
	SymbolHashDel(owner,tmph(CHashGlblVar *)->fun_ptr
	      -tmph(CHashGlblVar *)->fun_ptr->ptr_stars_cnt);
    }
  } else if (tmph->type & HTT_FILE)
    (*owner->release)(owner->context,tmph(CHashGeneric *)->user_data0);
  (*owner->release)(owner->context,tmph);
}

