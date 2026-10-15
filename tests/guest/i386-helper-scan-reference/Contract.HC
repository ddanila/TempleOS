I64 HelperScanContract()
{
 CCmpCtrl*cc=CAlloc(sizeof(CCmpCtrl));
 CIntermediateCode*node=CAlloc(sizeof(CIntermediateCode)),*fake=CAlloc(sizeof(CIntermediateCode));
 I64 m=0;
 QueInit(&cc->coc.coc_head);QueIns(node,&cc->coc.coc_head);
 node->ic_code=IC_ADD;node->ic_class=cmp.internal_types[RT_I64];
 fake->ic_class=cmp.internal_types[RT_F64];
 //Before OptPass012, this union is not a tree. A stale valid pointer must not
 //turn an integer operation into an F64 helper requirement.
 node->t.arg1_tree=fake;node->t.arg2_tree=fake;
 if(!I386FrontendNeedsHelpers(cc,cmp.internal_types[RT_I64],cmp.internal_types)){
  m|=1;
  //Exact shape observed in the native fault: stale bytes include -9.
  node->t.arg1_tree=-9;node->t.arg2_tree=-9;
  if(!I386FrontendNeedsHelpers(cc,cmp.internal_types[RT_I64],cmp.internal_types))m|=2;
 }
 node->ic_class=cmp.internal_types[RT_F64];
 if(I386FrontendNeedsHelpers(cc,cmp.internal_types[RT_I64],cmp.internal_types))m|=4;
 node->ic_class=cmp.internal_types[RT_I64];node->ic_code=IC_IMM_F64;
 if(I386FrontendNeedsHelpers(cc,cmp.internal_types[RT_I64],cmp.internal_types))m|=8;
 node->ic_code=IC_ADD;node->ic_flags=ICF_RES_TO_F64;
 if(I386FrontendNeedsHelpers(cc,cmp.internal_types[RT_I64],cmp.internal_types))m|=16;
 node->ic_flags=0;
 if(I386FrontendNeedsHelpers(cc,cmp.internal_types[RT_F64],cmp.internal_types))m|=32;
 Free(fake);Free(node);Free(cc);return m;
}
