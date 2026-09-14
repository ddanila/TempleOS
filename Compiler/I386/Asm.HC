//Inline assembly remains target code, never executable on the compiler host.
#include "/Compiler/I386/Emit.HC"
U0 I386Asm(CCmpCtrl *cc,CI386Out *out,CAOT *aot,I64 pass)
{
  CAOTImportExport *ie;
  CCodeMisc *label;
  I64 begin=out->count,width,delta;
  U8 *ptr;
  if(!aot || aot->abss || aot->heap_glbls || aot->aot_U8s<0 ||
      (aot->aot_U8s && !aot->buf)) {
    PrintErr("i386 inline asm absolute/storage relocation not supported\n");
    throw('Compiler');
  }
  I386Bytes(out,aot->buf,aot->aot_U8s);
  for(ie=aot->next_ie;ie!=&aot->next_ie;ie=ie->next) {
    width=0;
    if(ie->type==IET_REL_I8) width=1;
    if(ie->type==IET_REL_I16) width=2;
    if(ie->type==IET_REL_I32) width=4;
    if(!width || !ie->str || !(ie->flags&IEF_GOTO_LABEL) ||
        ie->rip<0 || ie->rip>aot->aot_U8s-width ||
        !(label=COCGoToLabelFind(cc,ie->str))) {
      PrintErr("i386 inline asm relocation %X not supported\n",ie->type);
      throw('Compiler');
    }
    label=OptLabelFwd(label);
    if(!pass) label->use_cnt++;
    if(pass) {
      ptr=out->data+begin+ie->rip;
      //Unresolved assembler expressions retain their numeric addend in-place.
      if(width==1) delta=*ptr(I8 *);
      else if(width==2) delta=*ptr(I16 *);
      else delta=*ptr(I32 *);
      delta+=label->addr-begin-ie->rip-width;
      if(width==1) {
        if(delta<I8_MIN || delta>I8_MAX) throw('Compiler');
        *ptr(U8 *)=delta;
      } else if(width==2) {
        if(delta<I16_MIN || delta>I16_MAX) throw('Compiler');
        *ptr(U16 *)=delta;
      } else {
        if(delta<I32_MIN || delta>I32_MAX) throw('Compiler');
        *ptr(U32 *)=delta;
      }
    }
  }
}
U0 I386AsmFree(CAOT *aot)
{
  CAOTImportExport *ie,*next;
  for(ie=aot->next_ie;ie!=&aot->next_ie;ie=next) {
    next=ie->next;
    QueRem(ie); Free(ie->str); Free(ie->src_link); Free(ie);
  }
  Free(aot->buf);
  QueRem(aot); Free(aot);
}

U8 *I386AsmExpression(CCmpCtrl *cc,I64 *_size,I64 *_type)
{//Assembler expressions execute on the host and may reread unresolved symbol values.
 //Validate the IR first. No calls, target-memory reads, stores or target execution.
  CIntermediateCode *ic;
  CAsmUndefHash *reference;
  Bool found;
  I64 flags=cc->flags;
  U8 *result=NULL;
  //Resolve target-size arithmetic before changing symbol operands to host I64.
  cc->pass=0;
  OptPass012(cc);
  for(ic=cc->coc.coc_head.next;ic!=&cc->coc.coc_head;ic=ic->next) {
    switch(ic->ic_code) {
      case IC_ABS_ADDR:
        ic->ic_code=IC_IMM_I64;
        break;
      case IC_IMM_I64:
      case IC_NOP1: case IC_NOP2:
      case IC_ADD: case IC_SUB: case IC_MUL: case IC_DIV: case IC_MOD:
      case IC_SHL: case IC_SHR: case IC_SHL_CONST: case IC_SHR_CONST: case IC_AND: case IC_OR: case IC_XOR:
      case IC_UNARY_MINUS: case IC_NOT: case IC_COM:
      case IC_RETURN_VAL: case IC_RETURN_VAL2: case IC_RET:
        break;
      case IC_DEREF:
        found=FALSE;
        if(ic->last->ic_code==IC_IMM_I64)
          for(reference=cc->asm_undef_hash;reference;reference=reference->next)
            if(ic->last->ic_data==&reference->hash(CHashExport *)->val) found=TRUE;
        if(!found) {
          PrintErr("i386 asm expression may only read host symbol values
");
          throw('Compiler');
        }
        break;
      default:
        PrintErr("i386 asm expression opcode %X not supported
",ic->ic_code);
        throw('Compiler');
    }
    //Assembler symbol values and addresses of their host fields are full I64.
    ic->ic_class=ic->ic_class2=cmp.internal_types[RT_I64];
  }
  cc->flags&=~(CCF_TARGET_I386|CCF_TARGET_HOST_CONST|CCF_AOT_COMPILE);
  try { result=COCCompile(cc,_size,NULL,_type); }
  catch { cc->flags=flags; }
  cc->flags=flags;
  return result;
}
