I64 CmpTargetSize(CCmpCtrl *cc,CHashClass *c)
{//Compiler objects retain host pointers; source layouts use the target width.
  if (cc->flags&CCF_TARGET_I386 && c->ptr_stars_cnt) return 4;
  return c->size;
}
