#include "/Kernel/SymbolDelete.HH"
#include "/Kernel/SymbolVisit.HC"
U0 SymbolLinkedLstDel(CSymbolRelease *owner,U8 **node)
{ SymbolLinkedLstVisit(owner,node); }
U0 SymbolMemberLstDel(CSymbolRelease *owner,CMemberLst *members)
{ SymbolMemberLstVisit(owner,members); }
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

U0 SymbolHashDel(CSymbolRelease *owner,CHashSrcSym *symbol)
{ SymbolHashVisit(owner,symbol); }
