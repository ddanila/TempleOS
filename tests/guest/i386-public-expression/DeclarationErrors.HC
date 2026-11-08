//Loaded after Errors.HC publishes the complete normal parser.
I64 de_type_detail[8];
U0 DECase(I64 *r,U8 *source,I64 mode,I64 success=0)
{
  I64 used=Fs->data_heap->used_u8s,code_used=Fs->code_heap->used_u8s;
  I64 mask=CCF_DONT_MAKE_RES|CCF_CLASS_DOL_OFFSET|CCF_HAS_MISC_DATA|(1<<CCf_PASS_TRACE_PRESENT)|CCF_TARGET_HOST_CONST;
  I64 flags=CCF_TARGET_I386|CCF_HAS_MISC_DATA|(1<<CCf_PASS_TRACE_PRESENT)|CCF_TARGET_HOST_CONST,count=0;
  CDoc *old_doc=Fs->put_doc,*doc=DocNew;
  CCmpCtrl *cc=CmpCtrlNew(StrNew(source),flags,"C:/Probe/Declaration.HC");
  CHashClass *owner=PrsClassNew;
  CHashClass *named_i64=HashFind("I64",cc->htc.hash_table_lst,HTT_CLASS|HTT_INTERNAL_TYPE);
  CMemberLst *member;
  CLexFile *snapshot;
  CIntermediateCode *outer;
  CCodeCtrl *saved;
  Fs->put_doc=doc;COCInit(cc);outer=ICAdd(cc,IC_IMM_I64,99,cmp.internal_types[RT_I64]);saved=cc->coc.coc_next;
  Lex(cc);LexPush(cc);snapshot=cc->lex_prs_stk;
  try{PrsVarLst(cc,owner,mode);}
  catch{r[0]=Fs->except_ch;Fs->catch_except=TRUE;}
  r[1]=cc->error_cnt;r[2]=(cc->flags&mask)==(flags&mask);
  r[3]=cc->coc.coc_next==saved;
  r[4]=r[3] && cc->coc.coc_head.next==outer && cc->coc.coc_head.last==outer && outer->ic_data==99;
  r[5]=cc->lex_prs_stk==snapshot;r[6]=owner->member_cnt;
  r[11]=TRUE;member=owner->member_lst_and_root;
  while(member){count++;if(MemberFind(member->str,owner)!=member)r[11]=FALSE;member=member->next;}r[7]=count;
  member=owner->member_lst_and_root;
  if(success==1)r[11]=r[11] && member && member->member_class==named_i64 && member->member_class->raw_type==RT_I64 && member->dim.total_cnt==6 && member->dim.next && member->dim.next->cnt==2 && member->dim.next->next && member->dim.next->next->cnt==3;
  if(success==1 && member && member->dim.next && member->dim.next->next) {
    de_type_detail[0]=member->member_class;de_type_detail[1]=named_i64;de_type_detail[2]=cmp.internal_types[RT_I64];
    de_type_detail[3]=member->member_class->raw_type==RT_I64;de_type_detail[4]=member->dim.total_cnt;
    de_type_detail[5]=member->dim.next->cnt;de_type_detail[6]=member->dim.next->next->cnt;de_type_detail[7]=!member->dim.next->next->next;
  }
  if(success==2)r[11]=r[11] && member && member->dft_val==42 && member->flags&MLF_DFT_AVAILABLE;
  if(success==3)r[11]=r[11] && member && member->meta && !StrCmp(member->meta->str,"meta") && member->meta->user_data==42 && !member->meta->flags;
  ClassMemberLstDel(owner);Free(owner);
  while(cc->coc.coc_next!=saved){COCDel(cc,&cc->coc);COCPop(cc);}
  COCDel(cc,&cc->coc);CmpCtrlDel(cc);Fs->put_doc=old_doc;DocDel(doc);TaskWait(adam_task);
  r[8]=Fs->data_heap->used_u8s-used;r[9]=Fs->code_heap->used_u8s-code_used;r[10]=EEGood;
}
U0 DEWarn(U8 *context,Bool warning)
{
  I64 *r=context;r[1]++;r[2]=warning;throw('MemWarn');
}
U0 DEInsert(I64 *r)
{
  I64 used=Fs->data_heap->used_u8s;
  CHashClass *owner=PrsClassNew;
  CMemberLst *kept=MemberLstNew(REG_NONE),*pending=MemberLstNew(REG_NONE);
  kept->str=StrNew("kept");kept->member_class=cmp.internal_types[RT_I64];
  pending->str=StrNew("newfield");pending->member_class=cmp.internal_types[RT_I64];
  MemberInsert(kept,owner,TRUE,FALSE,&DEWarn,r);
  try{MemberInsert(pending,owner,TRUE,TRUE,&DEWarn,r);}
  catch{r[0]=Fs->except_ch;Fs->catch_except=TRUE;}
  r[3]=owner->member_lst_and_root==kept && owner->last_in_member_lst==kept && !kept->next && !kept->left && !kept->right && owner->member_class_base_root==kept && !kept->left_class_base && !kept->right_class_base;
  r[4]=MemberFind("newfield",owner)==NULL;
  //Observe publication first. The caller still owns a failed insertion.
  MemberLstDel(pending);ClassMemberLstDel(owner);Free(owner);TaskWait(adam_task);
  r[5]=Fs->data_heap->used_u8s-used;r[6]=EEGood;
}
U0 DECheck()
{
  I64 *r=CAlloc(151*8);U8 *s;
  DECase(r,"{I64 broken[EEThrow()];}",PRS1_CLASS);
  DECase(r+12,"{I64 kept;I64 broken[2][EEThrow()];}",PRS1_CLASS);
  DECase(r+24,"{I64 broken[2);}",PRS1_CLASS);
  DECase(r+36,"{I64 kept;I64 kept[2];}",PRS1_CLASS);
  DECase(r+48,"{I64 broken[2];",PRS1_CLASS);
  DECase(r+60,"(I64 arg=EEThrow())",PRS1_FUN_ARG);
  DECase(r+72,"(I64 arg=1+)",PRS1_FUN_ARG);
  DECase(r+84,"{I64 field meta EEThrow();}",PRS1_CLASS);
  DECase(r+96,"{I64 kept[2][3];}",PRS1_CLASS,1);
  DECase(r+108,"(I64 arg=6*7)",PRS1_FUN_ARG,2);
  DECase(r+120,"{I64 kept;union {I64 broken[EEThrow()];}}",PRS1_CLASS);
  DECase(r+132,"{I64 field meta 42;}",PRS1_CLASS,3);
  DEInsert(r+144);
  s=MStrPrint("EXPORT declaration-errors.bin %X 4B8\n",r);EELog(s);Free(s);
  s=MStrPrint("EXPORT declaration-type-detail.bin %X 40\n",de_type_detail);EELog(s);Free(s);
  EELog("DECLARATION ERRORS DONE\n");Sleep(1000);
}
DECheck;
