U8 *delete_allocations[128];
Bool delete_live[128];
I64 delete_count,delete_errors;
U8 *DeleteNew(I64 size)
{
  U8 *res=DeleteAllocRaw(size);
  if(!res || delete_count>=128) { delete_errors++; return 0; }
  delete_allocations[delete_count]=res; delete_live[delete_count]=TRUE;
  delete_count++; return res;
}
U0 DeleteRelease(U8 *context,U8 *allocation)
{
  I64 i;
  if(context!=&delete_count) delete_errors++;
  if(!allocation) return;
  //Search backwards because a real allocator may reuse released addresses.
  for(i=delete_count-1;i>=0;i--) if(delete_allocations[i]==allocation && delete_live[i]) {
    delete_live[i]=FALSE; DeleteFreeRaw(allocation); return;
  }
  delete_errors++;
}
I64 SymbolDeleteTest()
{
  CSymbolRelease owner;
  CHashFun *fun,*nested;
  CHashClass *cl;
  CHashGlblVar *var;
  CHashDefineStr *def;
  CHashExport *exp;
  CHashGeneric *generic;
  CMemberLst *member,*second;
  CMemberLstMeta *meta;
  CArrayDim *dim;
  U8 *borrowed;
  I64 i;
  delete_count=0; delete_errors=0;
  owner.context=&delete_count; owner.release=&DeleteRelease;
  borrowed=DeleteNew(32);
  fun=DeleteNew(sizeof(CHashFun)*5); PrsFunInit(fun);
  fun->str=DeleteNew(8); fun->src_link=DeleteNew(8); fun->idx=DeleteNew(8);
  fun->import_name=DeleteNew(8); fun->dbg_info=DeleteNew(sizeof(CDbgInfo));
  dim=DeleteNew(sizeof(CArrayDim)); dim->next=DeleteNew(sizeof(CArrayDim)); fun->ie_lst=dim;
  fun->exe_addr=borrowed; fun->ext_lst=borrowed; fun->return_class=borrowed;
  member=DeleteNew(sizeof(CMemberLst)); second=DeleteNew(sizeof(CMemberLst));
  member->next=second; member->str=DeleteNew(8); second->str=DeleteNew(8);
  member->member_class=borrowed; member->static_data=borrowed;
  member->flags=MLF_STR_DFT_AVAILABLE|MLF_FUN;
  member->dft_val=(DeleteNew(8)+0)(U64);
  dim=DeleteNew(sizeof(CArrayDim)); dim->next=DeleteNew(sizeof(CArrayDim)); member->dim.next=dim;
  nested=DeleteNew(sizeof(CHashFun)*5); PrsFunInit(nested); nested->str=DeleteNew(8);
  member->fun_ptr=nested+3;
  meta=DeleteNew(sizeof(CMemberLstMeta)); member->meta=meta;
  meta->str=DeleteNew(8); meta->flags=MLMF_IS_STR; meta->user_data=(DeleteNew(8)+0)(U64);
  meta->next=DeleteNew(sizeof(CMemberLstMeta)); meta=meta->next;
  meta->str=DeleteNew(8); meta->user_data=0xFEDCBA9876543210;
  second->dft_val=0xFEDCBA9876543210;
  fun->member_lst_and_root=member; fun->member_class_base_root=member;
  fun->last_in_member_lst=second; fun->size=123; fun->member_cnt=2; fun->arg_cnt=2;
  SymbolClassMemberLstDel(&owner,fun);
  if(fun->size || fun->member_cnt || fun->arg_cnt || fun->member_lst_and_root ||
      fun->member_class_base_root || fun->last_in_member_lst!=&fun->member_lst_and_root ||
      fun->exe_addr!=borrowed || fun->return_class!=borrowed) return 60;
  SymbolHashDel(&owner,fun);
  cl=DeleteNew(sizeof(CHashClass)*5); PrsClassInit(cl);
  cl->str=DeleteNew(8); cl->dbg_info=borrowed; cl->base_class=borrowed;
  SymbolHashDel(&owner,cl);
  for(i=0;i<2;i++) {
    var=DeleteNew(sizeof(CHashGlblVar)); var->type=HTT_GLBL_VAR;
    var->str=DeleteNew(8); var->dim.next=DeleteNew(sizeof(CArrayDim));
    if(i) { var->flags=GVF_ALIAS; var->data_addr=borrowed; }
    else var->data_addr=DeleteNew(16);
    nested=DeleteNew(sizeof(CHashFun)*5); PrsFunInit(nested); var->fun_ptr=nested+2;
    SymbolHashDel(&owner,var);
  }
  def=DeleteNew(sizeof(CHashDefineStr)); def->type=HTT_DEFINE_STR;
  def->str=DeleteNew(8); def->data=DeleteNew(16); SymbolHashDel(&owner,def);
  exp=DeleteNew(sizeof(CHashExport)); exp->type=HTT_EXPORT_SYS_SYM;
  exp->str=DeleteNew(8); exp->dbg_info=DeleteNew(sizeof(CDbgInfo)); SymbolHashDel(&owner,exp);
  generic=DeleteNew(sizeof(CHashGeneric)); generic->type=HTT_FILE;
  generic->str=DeleteNew(8); generic->user_data0=(DeleteNew(16)+0)(U64);
  SymbolHashDel(&owner,generic);
  generic=DeleteNew(sizeof(CHashGeneric)); generic->type=HTT_DICT_WORD;
  generic->str=borrowed; SymbolHashDel(&owner,generic);
  SymbolHashDel(&owner,0); SymbolMemberLstDel(&owner,0);
  if(delete_errors || !delete_live[0]) return 61;
  for(i=1;i<delete_count;i++) if(delete_live[i]) return 62;
  DeleteRelease(&delete_count,borrowed);
  if(delete_errors || delete_live[0]) return 63;
  return 0;
}
