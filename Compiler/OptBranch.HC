extern CIntermediateCode *OptBrNotZero(CCmpCtrl *cc,CIntermediateCode *tmpi);

CIntermediateCode *OptBrZero(CCmpCtrl *cc,CIntermediateCode *tmpi)
{
  CCodeMisc *lb_true,*lb_false;
  CIntermediateCode *tmpii=OptLag(tmpi),*tmpii2;
  switch (tmpii->ic_code) {
    case IC_NOT:
      tmpi->ic_code=IC_BR_NOT_ZERO;
      tmpi->ic_class=tmpii->ic_class;
      tmpi->ic_flags|=tmpii->ic_flags;
      tmpi->t.arg1_class=tmpii->t.arg1_class;
      tmpi->t.arg1_tree=tmpii->t.arg1_tree;
      OptFree(cc,tmpii);
      return OptBrNotZero(cc,tmpi);
    case IC_EQU_EQU...IC_LESS_EQU:
      tmpi->ic_code=(tmpii->ic_code-IC_EQU_EQU)^1+IC_BR_EQU_EQU;
      break;
    case IC_OR_OR:
      tmpi->ic_code=IC_BR_OR_OR_ZERO;
      break;
    case IC_AND_AND:
      tmpi->ic_code=IC_BR_AND_AND_ZERO;
      break;
    case IC_AND:
      tmpi->ic_code=IC_BR_AND_ZERO;
      break;
    case IC_MM_:
      if (cc->pass==2 && !(tmpii->ic_flags&ICF_RES_TO_F64) &&
	    tmpii->ic_class->raw_type!=RT_F64)
	tmpi->ic_code=IC_BR_MM_ZERO;
      break;
    case IC_CALL_END:
      tmpii2=OptLag(tmpii);
      switch (tmpii2->ic_code) {
	start:
	  case IC_CARRY:
	    tmpii2->ic_code=IC_BR_NOT_CARRY;
	    break;
	  case IC_BT:
	    tmpii2->ic_code=IC_BR_NOT_BT;
	    break;
	  case IC_LBTS:
	    tmpii2->ic_flags|=ICF_LOCK;
	  case IC_BTS:
	    tmpii2->ic_code=IC_BR_NOT_BTS;
	    break;
	  case IC_LBTR:
	    tmpii2->ic_flags|=ICF_LOCK;
	  case IC_BTR:
	    tmpii2->ic_code=IC_BR_NOT_BTR;
	    break;
	  case IC_LBTC:
	    tmpii2->ic_flags|=ICF_LOCK;
	  case IC_BTC:
	    tmpii2->ic_code=IC_BR_NOT_BTC;
	    break;
	end:
	  tmpii2->ic_data=tmpi->ic_data;
	  tmpii->ic_code=IC_CALL_END2;
	  OptSetNOP1(tmpi);
	  return tmpii;
      }
      break;
  }
  if (tmpi->ic_code!=IC_BR_ZERO) {
    tmpi->ic_class=tmpii->ic_class;
    tmpi->ic_flags|=tmpii->ic_flags;
    tmpi->t.arg1_class=tmpii->t.arg1_class;
    tmpi->t.arg2_class=tmpii->t.arg2_class;
    tmpi->t.arg1_tree=tmpii->t.arg1_tree;
    tmpi->t.arg2_tree=tmpii->t.arg2_tree;
    OptFree(cc,tmpii);

    if (tmpi->ic_flags&ICF_PUSH_CMP &&
	  IC_BR_NOT_EQU<=tmpi->ic_code<=IC_BR_LESS_EQU &&
	  !(tmpi->ic_flags&ICF_USE_F64)) {
      tmpi->ic_code+=IC_BR_EQU_EQU2-IC_BR_EQU_EQU;
      tmpi->ic_flags&=~ICF_PUSH_CMP;
      tmpii=tmpi->next; //IC_PUSH_CMP inst
      while (tmpii->ic_code!=IC_PUSH_CMP)
	tmpii=tmpii->next;
      tmpii->t.arg1_tree=tmpi;
      OptSetNOP1(tmpii);
    }

    lb_true=tmpi->ic_data;
    if (tmpi->ic_code==IC_BR_AND_AND_ZERO) {
      tmpii=tmpi->t.arg1_tree->next;
      tmpii->ic_data=lb_true;
      tmpii->t.arg1_tree=tmpi->t.arg1_tree;
      tmpii->t.arg1_class=tmpi->t.arg1_class;
      tmpii->ic_code=IC_BR_ZERO;
      OptBrZero(cc,tmpii);
      tmpii=tmpi->t.arg2_tree->next;
      tmpii->t.arg1_tree=tmpi->t.arg2_tree;
      tmpii->t.arg1_class=tmpi->t.arg2_class;
      tmpii->ic_data=lb_true;
      tmpii->ic_code=IC_BR_ZERO;
      tmpii=OptBrZero(cc,tmpii);
      OptSetNOP1(tmpi);
    } else if (tmpi->ic_code==IC_BR_OR_OR_ZERO) {
      lb_false=COCMiscNew(cc,CMT_LABEL);
      tmpi->ic_code=IC_LABEL;
      tmpi->ic_flags=0;
      tmpi->ic_data=lb_false;
      tmpii=tmpi->t.arg1_tree->next;
      tmpii->t.arg1_tree=tmpi->t.arg1_tree;
      tmpii->t.arg1_class=tmpi->t.arg1_class;
      tmpii->ic_data=lb_false;
      tmpii->ic_code=IC_BR_NOT_ZERO;
      OptBrNotZero(cc,tmpii);
      tmpii=tmpi->t.arg2_tree->next;
      tmpii->t.arg1_tree=tmpi->t.arg2_tree;
      tmpii->t.arg1_class=tmpi->t.arg2_class;
      tmpii->ic_data=lb_true;
      tmpii->ic_code=IC_BR_ZERO;
      tmpii=OptBrZero(cc,tmpii);
    } else
      tmpii=tmpi;
    if (tmpi->ic_flags&ICF_POP_CMP && tmpi->t.arg1_tree->ic_code==IC_NOP1) {
      tmpi->t.arg1_tree=tmpi->t.arg1_tree->t.arg1_tree;
      tmpi->ic_flags&=~ICF_POP_CMP;
    }
    return tmpii;
  }
  return tmpi;
}

CIntermediateCode *OptBrNotZero(CCmpCtrl *cc,CIntermediateCode *tmpi)
{
  CCodeMisc *lb_true,*lb_false;
  CIntermediateCode *tmpii=OptLag(tmpi),*tmpii2;
  switch (tmpii->ic_code) {
    case IC_NOT:
      tmpi->ic_code=IC_BR_ZERO;
      tmpi->ic_class=tmpii->ic_class;
      tmpi->ic_flags|=tmpii->ic_flags;
      tmpi->t.arg1_class=tmpii->t.arg1_class;
      tmpi->t.arg1_tree=tmpii->t.arg1_tree;
      OptFree(cc,tmpii);
      return OptBrZero(cc,tmpi);
    case IC_EQU_EQU...IC_LESS_EQU:
      tmpi->ic_code=tmpii->ic_code+IC_BR_EQU_EQU-IC_EQU_EQU;
      break;
    case IC_OR_OR:
      tmpi->ic_code=IC_BR_OR_OR_NOT_ZERO;
      break;
    case IC_AND_AND:
      tmpi->ic_code=IC_BR_AND_AND_NOT_ZERO;
      break;
    case IC_AND:
      tmpi->ic_code=IC_BR_AND_NOT_ZERO;
      break;
    case IC_MM_:
      if (cc->pass==2 && !(tmpii->ic_flags&ICF_RES_TO_F64) &&
	    tmpii->ic_class->raw_type!=RT_F64)
	tmpi->ic_code=IC_BR_MM_NOT_ZERO;
      break;
    case IC_CALL_END:
      tmpii2=OptLag(tmpii);
      switch (tmpii2->ic_code) {
	start:
	  case IC_CARRY:
	    tmpii2->ic_code=IC_BR_CARRY;
	    break;
	  case IC_BT:
	    tmpii2->ic_code=IC_BR_BT;
	    break;
	  case IC_LBTS:
	    tmpii2->ic_flags|=ICF_LOCK;
	  case IC_BTS:
	    tmpii2->ic_code=IC_BR_BTS;
	    break;
	  case IC_LBTR:
	    tmpii2->ic_flags|=ICF_LOCK;
	  case IC_BTR:
	    tmpii2->ic_code=IC_BR_BTR;
	    break;
	  case IC_LBTC:
	    tmpii2->ic_flags|=ICF_LOCK;
	  case IC_BTC:
	    tmpii2->ic_code=IC_BR_BTC;
	    break;
	end:
	  tmpii2->ic_data=tmpi->ic_data;
	  tmpii->ic_code=IC_CALL_END2;
	  OptSetNOP1(tmpi);
	  return tmpii;
      }
      break;
  }
  if (tmpi->ic_code!=IC_BR_NOT_ZERO) {
    tmpi->ic_class=tmpii->ic_class;
    tmpi->ic_flags|=tmpii->ic_flags;
    tmpi->t.arg1_class=tmpii->t.arg1_class;
    tmpi->t.arg2_class=tmpii->t.arg2_class;
    tmpi->t.arg1_tree=tmpii->t.arg1_tree;
    tmpi->t.arg2_tree=tmpii->t.arg2_tree;
    OptFree(cc,tmpii);

    if (tmpi->ic_flags&ICF_PUSH_CMP &&
	  IC_BR_NOT_EQU<=tmpi->ic_code<=IC_BR_LESS_EQU &&
	  !(tmpi->ic_flags&ICF_USE_F64)) {
      tmpi->ic_code+=IC_BR_EQU_EQU2-IC_BR_EQU_EQU;
      tmpi->ic_flags&=~ICF_PUSH_CMP;
      tmpii=tmpi->next; //IC_PUSH_CMP inst
      while (tmpii->ic_code!=IC_PUSH_CMP)
	tmpii=tmpii->next;
      tmpii->t.arg1_tree=tmpi;
      OptSetNOP1(tmpii);
    }

    lb_true=tmpi->ic_data;
    if (tmpi->ic_code==IC_BR_OR_OR_NOT_ZERO) {
      tmpii=tmpi->t.arg1_tree->next;
      tmpii->t.arg1_tree=tmpi->t.arg1_tree;
      tmpii->t.arg1_class=tmpi->t.arg1_class;
      tmpii->ic_data=lb_true;
      tmpii->ic_code=IC_BR_NOT_ZERO;
      OptBrNotZero(cc,tmpii);
      tmpii=tmpi->t.arg2_tree->next;
      tmpii->t.arg1_tree=tmpi->t.arg2_tree;
      tmpii->t.arg1_class=tmpi->t.arg2_class;
      tmpii->ic_data=lb_true;
      tmpii->ic_code=IC_BR_NOT_ZERO;
      tmpii=OptBrNotZero(cc,tmpii);
      OptSetNOP1(tmpi);
    } else if (tmpi->ic_code==IC_BR_AND_AND_NOT_ZERO) {
      lb_false=COCMiscNew(cc,CMT_LABEL);
      tmpi->ic_code=IC_LABEL;
      tmpi->ic_flags=0;
      tmpi->ic_data=lb_false;
      tmpii=tmpi->t.arg1_tree->next;
      tmpii->t.arg1_tree=tmpi->t.arg1_tree;
      tmpii->t.arg1_class=tmpi->t.arg1_class;
      tmpii->ic_data=lb_false;
      tmpii->ic_code=IC_BR_ZERO;
      OptBrZero(cc,tmpii);
      tmpii=tmpi->t.arg2_tree->next;
      tmpii->t.arg1_tree=tmpi->t.arg2_tree;
      tmpii->t.arg1_class=tmpi->t.arg2_class;
      tmpii->ic_data=lb_true;
      tmpii->ic_code=IC_BR_NOT_ZERO;
      tmpii=OptBrNotZero(cc,tmpii);
    } else
      tmpii=tmpi;
    if (tmpi->ic_flags&ICF_POP_CMP && tmpi->t.arg1_tree->ic_code==IC_NOP1) {
      tmpi->t.arg1_tree=tmpi->t.arg1_tree->t.arg1_tree;
      tmpi->ic_flags&=~ICF_POP_CMP;
    }
    return tmpii;
  }
  return tmpi;
}

