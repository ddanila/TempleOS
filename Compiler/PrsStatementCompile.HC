U8 *LexStmt2Bin(CCmpCtrl *cc,I64 *_type,I64 cmp_flags=CMPF_PRS_SEMICOLON)
{//Compile one cc stmt to bin code.
  I64 size,i,j,k,*res=INVALID_PTR;
  CCodeCtrl *tmpcbh,*native_asm;
  if (_type) *_type=RT_I64;
  Btr(&cc->flags,CCf_PASS_TRACE_PRESENT);
  if (cc->aot_depth==2)
    COCPush(cc);
  COCInit(cc);
  if (!PrsStmt(cc,,,cmp_flags)) {
    if (cc->coc.coc_head.next!=&cc->coc.coc_head) {
      cc->coc.coc_head.last->ic_flags&=~ICF_RES_NOT_USED;
      ICAdd(cc,IC_RETURN_VAL2,0,0);
      ICAdd(cc,IC_RET,0,0);
      if (res=COCCompile(cc,&size,NULL,_type)) {
	if (cc->flags&CCF_AOT_COMPILE) {
	  j=cc->aotc->rip;
	  k=(size+7)>>3;
	  for (i=0;i<k;i++)
	    AOTStoreCodeU64(cc,res[i]);
	  Free(res);
	  res=j;
	}
      }
    } //TODO: else del misc?
  } else //Keep native inline-assembly labels for the enclosing function.
    if (!(cc->flags&CCF_TARGET_I386 && cc->aot_depth==2 && cmp_flags&CMPF_ASM_BLK))
      QueDel(&cc->coc.coc_head.next);
  if (cc->aot_depth==2) {
    if(cc->flags&CCF_TARGET_I386 && cmp_flags&CMPF_ASM_BLK) {
      native_asm=MAlloc(sizeof(CCodeCtrl));
      MemCpy(native_asm,&cc->coc,sizeof(CCodeCtrl));
      tmpcbh=COCPopNoFree(cc);
      Free(tmpcbh);
      COCAppend(cc,native_asm);
    } else {
      tmpcbh=COCPopNoFree(cc);
      COCAppend(cc,tmpcbh);
    }
  }
  return res;
}

