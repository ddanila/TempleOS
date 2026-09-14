U0 OptFixSizeOf(CCmpCtrl *cc,CIntermediateCode *tmpi1,
	CIntermediateCode *tmpi_push,CHashClass *tmpcc)
{
  if (tmpi1->ic_code==IC_MUL && tmpi1->t.arg2_tree->ic_code==IC_SIZEOF) {
    tmpi1->t.arg2_tree->ic_code=IC_IMM_I64;
    tmpi1->t.arg2_tree->ic_class=tmpcc;
    tmpi_push->ic_class=tmpcc;
    if (tmpcc->ptr_stars_cnt) {
      tmpcc--;
      if (CmpTargetSize(cc,tmpcc)==1)
	goto here;
      tmpi1->t.arg2_tree->ic_data=CmpTargetSize(cc,tmpcc);
    } else {
here:
      if (tmpi_push==tmpi1)
	tmpi1->t.arg2_tree->ic_data=1;
      else {
	OptSetNOP1(tmpi1->t.arg2_tree);
	OptSetNOP1(tmpi1);
      }
    }
  }
}
