Bool I386IsF64(CHashClass *c)
{
  if(c) c=OptClassFwd(c);
  return c && !c->ptr_stars_cnt && c->raw_type==RT_F64;
}

CHashClass *I386ValueClass(CI386Backend *backend,CIntermediateCode *ic)
{
  if (ic->ic_flags&ICF_RES_TO_F64) return backend->types[RT_F64];
  if (ic->ic_flags&ICF_RES_TO_INT) return backend->types[RT_I64];
  if (ic->ic_code==IC_NOT || ic->ic_code==IC_AND_AND ||
      ic->ic_code==IC_OR_OR || ic->ic_code==IC_XOR_XOR ||
      IC_EQU_EQU<=ic->ic_code<=IC_LESS_EQU)
    return backend->types[RT_I64];
  if(ic->ic_class) return OptClassFwd(ic->ic_class);
  return 0;
}

U0 I386RestorePointerAdds(CI386Backend *backend)
{//Keep address arithmetic pointer-valued between shared optimizer folds.
  //OptFixupBinaryOp1 promotes ic_class for arithmetic; the following fold
  //copies it over ic_class2. Recover pointer-plus-integer from the operand
  //trees in IR order, so nested pointer adds also retain their logical type.
  CIntermediateCode *ic;
  CHashClass *left,*right,*type;
  for(ic=backend->cc->coc.coc_head.next;ic!=&backend->cc->coc.coc_head;ic=ic->next)
    if(ic->ic_code==IC_ADD) {
      if(!ic->t.arg1_tree || !ic->t.arg2_tree) throw('Compiler');
      left=I386ValueClass(backend,ic->t.arg1_tree);
      right=I386ValueClass(backend,ic->t.arg2_tree);
      type=0;
      if(left && right && !I386IsF64(left) && !I386IsF64(right)) {
        if(left->ptr_stars_cnt && !right->ptr_stars_cnt) type=left;
        else if(right->ptr_stars_cnt && !left->ptr_stars_cnt) type=right;
      }
      if(type) ic->ic_class=ic->ic_class2=type;
    }
}
