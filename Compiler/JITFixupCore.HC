#ifndef JIT_FIXUP_IMPL
#define JIT_FIXUP_IMPL CmpFixUpJITAsm
#endif
#ifndef COC_LABEL_IMPL
#define COC_LABEL_IMPL COCGoToLabelFind
#endif
#ifndef OPT_LABEL_IMPL
#define OPT_LABEL_IMPL OptLabelFwd
#endif
U0 JIT_FIXUP_IMPL(CCmpCtrl *cc,CAOT *tmpaot)
{
  I64 i,rip2=tmpaot->buf+tmpaot->rip,*str=NULL;
  I64 patch_address,trace_bits=64;
  U8 *ptr;
  CCodeMisc *g_lb;
  CAOTAbsAddr *tmpa,*tmpa1;
  CAOTImportExport *tmpie,*tmpie1;
  CHashExport *tmpex;

  if (cc->flags&CCF_TARGET_I386) trace_bits=32;
  tmpa=tmpaot->abss;
  while (tmpa) {
    tmpa1=tmpa->next;
    ptr=rip2+tmpa->rip;
    switch [tmpa->type] {
      case AAT_ADD_U8:	*ptr(U8 *) +=rip2; break;
      case AAT_SUB_U8:	*ptr(U8 *) -=rip2; break;
      case AAT_ADD_U16:	*ptr(U16 *)+=rip2; break;
      case AAT_SUB_U16:	*ptr(U16 *)-=rip2; break;
      case AAT_ADD_U32:	*ptr(U32 *)+=rip2; break;
      case AAT_SUB_U32:	*ptr(U32 *)-=rip2; break;
      case AAT_ADD_U64:	*ptr(I64 *)+=rip2; break;
      case AAT_SUB_U64:	*ptr(I64 *)-=rip2; break;
    }
    Free(tmpa);
    tmpa=tmpa1;
  }
  tmpie=tmpaot->next_ie;
  while (tmpie!=&tmpaot->next_ie) {
    tmpie1=tmpie->next;
    if (tmpie->str) {
      Free(str);
      str=tmpie->str;
    }
    switch (tmpie->type) {
      case IET_REL32_EXPORT:
      case IET_IMM32_EXPORT:
      case IET_REL64_EXPORT:
      case IET_IMM64_EXPORT:
	tmpex=CAlloc(sizeof(CHashExport));
	tmpex->str=str;
	str=NULL;
	tmpex->type=HTT_EXPORT_SYS_SYM|HTF_IMM;
	if (tmpie->type==IET_IMM32_EXPORT||tmpie->type==IET_IMM64_EXPORT)
	  tmpex->val=tmpie->rip;
	else
	  tmpex->val=tmpie->rip+rip2;
	tmpex->src_link=tmpie->src_link;
	tmpie->src_link=NULL;
	HashAdd(tmpex,Fs->hash_table);
	SysSymImportsResolve(tmpex->str,0);
	break;
      case IET_REL_I0...IET_IMM_I64:
	if (tmpie->str) {
	  if (tmpie->flags&IEF_GOTO_LABEL) {
	    if(!(g_lb=COC_LABEL_IMPL(cc,str)))
	      "Unresolved Reference:%s\n",str;
	    else {
	      g_lb->use_cnt++;
	      g_lb=OPT_LABEL_IMPL(g_lb);
	      i=g_lb->addr+tmpaot->buf;
	    }
	    tmpex=NULL;
	  } else {
	    if (!(tmpex=HashFind(str,Fs->hash_table,
		  HTG_ALL-HTT_IMPORT_SYS_SYM)))
	      "Unresolved Reference:%s\n",str;
	    else {
	      if (tmpex->type & HTT_FUN)
		i=tmpex(CHashFun *)->exe_addr;
	      else if (tmpex->type & HTT_GLBL_VAR)
		i=tmpex(CHashGlblVar *)->data_addr;
	      else
		i=tmpex->val;
	    }
	    g_lb=NULL;
	  }
	}
	if (tmpex || g_lb) {
	  patch_address=tmpie->rip+rip2;
	  ptr=patch_address;
	  switch [tmpie->type] {
	    case IET_REL_I0:
	    case IET_IMM_U0:
	      break;
	    case IET_REL_I8:
	      if (!(I8_MIN<=i-patch_address-1<=I8_MAX))
		LexExcept(cc,"Branch out of range at ");
	      *ptr(U8 *) =i-patch_address-1;
	      break;
	    case IET_IMM_U8:
	      *ptr(U8 *) =i;
	      break;
	    case IET_REL_I16:
	      if (!(I16_MIN<=i-patch_address-2<=I16_MAX))
		LexExcept(cc,"Branch out of range at ");
	      *ptr(U16 *)=i-patch_address-2;
	      break;
	    case IET_IMM_U16:
	      *ptr(U16 *)=i;
	      break;
	    case IET_REL_I32:
	      if (!(I32_MIN<=i-patch_address-4<=I32_MAX))
		LexExcept(cc,"Branch out of range at ");
	      *ptr(U32 *)=i-patch_address-4;
	      break;
	    case IET_IMM_U32:
	      *ptr(U32 *)=i;
	      break;
	    case IET_REL_I64:
	      *ptr(I64 *)=i-patch_address-8;
	      break;
	    case IET_IMM_I64:
	      *ptr(I64 *)=i;
	      break;
	  }
	}
	break;
    }
    Free(tmpie->src_link);
    Free(tmpie);
    tmpie=tmpie1;
  }
  Free(str);
  if (!cc->aot_depth && Bt(&cc->opts,OPTf_TRACE))
    Un(rip2,tmpaot->aot_U8s,trace_bits);
  QueRem(tmpaot);
  Free(tmpaot);
}
