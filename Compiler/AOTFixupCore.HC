#ifndef AOT_FIXUP_IMPL
#define AOT_FIXUP_IMPL CmpFixUpAOTAsm
#endif
#ifndef COC_LABEL_IMPL
#define COC_LABEL_IMPL COCGoToLabelFind
#endif
#ifndef OPT_LABEL_IMPL
#define OPT_LABEL_IMPL OptLabelFwd
#endif
U0 AOT_FIXUP_IMPL(CCmpCtrl *cc,CAOT *tmpaot)
{
  CAOTCtrl *aotc=cc->aotc;
  I64 i,patch_address,rip2=tmpaot->rip+cc->aotc->rip;
  U8 *ptr;
  CCodeMisc *g_lb=NULL;
  CAOTAbsAddr *tmpa,*tmpa1;
  CAOTImportExport *tmpie,*tmpie1;

  tmpa=tmpaot->abss;
  while (tmpa) {
    tmpa1=tmpa->next;
    tmpa->next=aotc->abss;
    ptr=tmpaot->buf+tmpaot->rip+tmpa->rip;
    switch [tmpa->type] {
      case AAT_ADD_U8:	*ptr(U8 *)+=rip2;	break;
      case AAT_SUB_U8:	*ptr(U8 *)-=rip2;	break;
      case AAT_ADD_U16:	*ptr(U16 *)+=rip2;	break;
      case AAT_SUB_U16:	*ptr(U16 *)-=rip2;	break;
      case AAT_ADD_U32:	*ptr(U32 *)+=rip2;	break;
      case AAT_SUB_U32:	*ptr(U32 *)-=rip2;	break;
      case AAT_ADD_U64:	*ptr(I64 *)+=rip2;	break;
      case AAT_SUB_U64:	*ptr(I64 *)-=rip2;	break;
    }
    aotc->abss=tmpa;
    tmpa->rip+=rip2;
    tmpa=tmpa1;
  }

  tmpie=tmpaot->next_ie;
  while (tmpie!=&tmpaot->next_ie) {
    tmpie1=tmpie->next;
    QueRem(tmpie);
    if (IET_REL_I0<=tmpie->type<=IET_IMM_I64) {
      if (tmpie->str) {
	if (tmpie->flags&IEF_GOTO_LABEL) {
	  if(!(g_lb=COC_LABEL_IMPL(cc,tmpie->str)))
	    "Unresolved Reference:%s\n",tmpie->str;
	  else {
	    g_lb->use_cnt++;
	    g_lb=OPT_LABEL_IMPL(g_lb);
	  }
	} else
	  g_lb=NULL;
      }
    } else
      g_lb=NULL;

    patch_address=tmpaot->buf;patch_address+=tmpaot->rip+tmpie->rip;
    ptr=patch_address;
    if (g_lb) {
      i=g_lb->addr;i+=tmpaot->buf;
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
      Free(tmpie->str);
      Free(tmpie->src_link);
      Free(tmpie);
    } else {
      switch (tmpie->type) {
	start:
	  case IET_REL32_EXPORT:
	  case IET_IMM32_EXPORT:
	  case IET_REL64_EXPORT:
	  case IET_IMM64_EXPORT:
	  case IET_IMM_U0:
	  case IET_IMM_U8:
	  case IET_IMM_U16:
	  case IET_IMM_U32:
	  case IET_IMM_I64:
	  case IET_REL_I0:
	    break;
	  case IET_REL_I8:	    *ptr(U8 *) -=rip2;	    break;
	  case IET_REL_I16:	    *ptr(U16 *)-=rip2;	    break;
	  case IET_REL_I32:	    *ptr(U32 *)-=rip2;	    break;
	  case IET_REL_I64:	    *ptr(I64 *)-=rip2;	    break;
	end:
	  tmpie->rip+=rip2;
	  break;
      }
      tmpie->aot=NULL;
      QueIns(tmpie,tmpaot->parent_aot->last_ie);
    }
    tmpie=tmpie1;
  }
}
