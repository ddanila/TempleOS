#include "/Compiler/CodeCtrl.HH"
U0 COCSeed(CCodeCtrl *coc)
{
  coc->coc_head.next=coc->coc_head.last=&coc->coc_head.next;
  coc->coc_next_misc=coc->coc_last_misc=&coc->coc_next_misc;
  coc->coc_head.ic_code=0; //IC_END
}
U0 ICSeed(CCmpCtrl *cc,CIntermediateCode *node,I64 opcode,I64 arg,CHashClass *type,I64 flags)
{
  node->ic_code=opcode.u16[0]; node->ic_precedence=opcode.u16[1];
  node->ic_data=arg; node->ic_class=type;
  if(cc->pass_trace) { cc->flags|=1<<CCf_PASS_TRACE_PRESENT; flags|=ICF_PASS_TRACE; }
  if(cc->lock_cnt) flags|=ICF_LOCK;
  node->ic_flags=flags; node->ic_line=cc->last_line_num;
  node->next=&cc->coc.coc_head.next; node->last=cc->coc.coc_head.last;
  node->last->next=node; cc->coc.coc_head.last=node;
}
U0 COCMiscSeed(CCmpCtrl *cc,CCodeMisc *node,I64 type)
{//A fresh zeroed record, including the original invalid address marker.
  node->addr=0x7FFFFFFFFFFFFFFF; node->type=type;
  node->next=&cc->coc.coc_next_misc; node->last=cc->coc.coc_last_misc;
  node->last->next=node; cc->coc.coc_last_misc=node;
}
Bool COCRelease(CCmpCtrl *cc,CCodeCtrl *coc,CSymbolRelease *owner,
  U0 (*label)(U8 *context,CCmpCtrl *cc,U8 *name,Bool undefined)=0)
{
  CIntermediateCode *ic=coc->coc_head.next,*next_ic;
  CCodeMisc *cm=coc->coc_next_misc,*next_cm;
  CArrayDim *dim,*next_dim;
  U8 *undef=0;
  Bool undefined=FALSE;
  while(ic!=&coc->coc_head.next) {
    next_ic=ic->next; (*owner->release)(owner->context,ic); ic=next_ic;
  }
  while(cm!=&coc->coc_next_misc) {
    next_cm=cm->next;
    switch(cm->type) {
      case CMT_GOTO_LABEL:
      case CMT_ASM_LABEL:
        if(!(cm->flags&CMF_DEFINED)) {
          //Keep the last undefined-label diagnostic, reclaim every earlier name.
          (*owner->release)(owner->context,undef);
          undef=cm->str; cm->str=0;
        } else if(!cm->use_cnt && label) (*label)(owner->context,cc,cm->str,FALSE);
        break;
      case CMT_JMP_TABLE: (*owner->release)(owner->context,cm->jmp_table); break;
      case CMT_FLOAT_CONSTS: (*owner->release)(owner->context,cm->float_consts); break;
      case CMT_ARRAY_DIM:
        dim=cm->dim;
        while(dim) {
          next_dim=dim->next; (*owner->release)(owner->context,dim); dim=next_dim;
        }
        break;
      case CMT_HASH_ENTRY: SymbolHashDel(owner,cm->h); break;
    }
    (*owner->release)(owner->context,cm->str);
    (*owner->release)(owner->context,cm);
    cm=next_cm;
  }
  COCSeed(coc);
  if(undef) {
    undefined=TRUE;
    if(label) (*label)(owner->context,cc,undef,TRUE);
    (*owner->release)(owner->context,undef);
  }
  return undefined;
}
