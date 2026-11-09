#ifndef COMPILER_ASM_NUM_LIFE_INCLUDED
#define COMPILER_ASM_NUM_LIFE_INCLUDED
U0 AsmPendingRelease(CCmpCtrl *cc)
{
  CAsmUndefHash *pending=cc->asm_undef_hash;
  cc->asm_undef_hash=NULL;
  LinkedLstDel(pending);
}
U0 AsmNumRelease(CAsmNum *num)
{
  U8 *code=num->machine_code;
  CAsmUndefHash *local=num->local_asm_undef_hash,*global=num->glbl_asm_undef_hash;
  num->machine_code=NULL;
  num->local_asm_undef_hash=num->glbl_asm_undef_hash=NULL;
  Free(code);LinkedLstDel(local);LinkedLstDel(global);
}
U0 AsmNumDetach(CAsmNum *num,U8 *code)
{//A published unresolved record acquired these pointers; keep scalar values.
  if(code && num->machine_code==code) {
    num->machine_code=NULL;
    num->local_asm_undef_hash=num->glbl_asm_undef_hash=NULL;
  }
}
#endif
