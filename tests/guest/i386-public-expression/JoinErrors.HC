//Loaded after Errors.HC publishes the complete normal compiler services.
I64 fj_warning_kind;
Bool FJOption(U8 *context,I64 option){return !context && option==OPTf_WARN_HEADER_MISMATCH;}
U0 FJWarning(U8 *context,CCmpCtrl *cc,I64 kind,CHashSrcSym *symbol)
{if(context || !cc || !symbol)throw('BadJoin');fj_warning_kind=kind;throw('JoinWarn');}
U0 FJTable(CCmpCtrl *cc,CHashTable *table)
{cc->htc.glbl_hash_table=cc->htc.local_hash_table=cc->htc.hash_table_lst=table;}
CHashFun *FJSeed(CHashTable *table)
{
  CCmpCtrl *cc=CmpCtrlNew(StrNew("(I64 kept=7)"),CCF_TARGET_I386,"C:/Probe/OldHeader.HC");
  CHashFun *fun;
  FJTable(cc,table);Free(cc->cur_help_idx);cc->cur_help_idx=StrNew("Join/Old");Lex(cc);fun=PrsFunJoin(cc,cmp.internal_types[RT_I64],StrNew("JoinProbe"),0);CmpCtrlDel(cc);
  fun->use_cnt=3;return fun;
}
Bool FJContains(CHashTable *table,CHash *wanted)
{
  I64 bucket;CHash *entry;
  for(bucket=0;bucket<=table->mask;bucket++)for(entry=table->body[bucket];entry;entry=entry->next)if(entry==wanted)return TRUE;
  return FALSE;
}
U0 FJCase(I64 *r,U8 *source,I64 kind)
{
  I64 used=Fs->data_heap->used_u8s,code_used=Fs->code_heap->used_u8s;
  I64 flags=CCF_TARGET_I386|CCF_HAS_MISC_DATA|(1<<CCf_PASS_TRACE_PRESENT)|CCF_TARGET_HOST_CONST;
  I64 mask=CCF_DONT_MAKE_RES|CCF_CLASS_DOL_OFFSET|CCF_HAS_MISC_DATA|(1<<CCf_PASS_TRACE_PRESENT)|CCF_TARGET_HOST_CONST;
  I64 mode=PRS0_TYPECAST,bucket,count=0;
  CDoc *old_doc=Fs->put_doc,*doc=DocNew;
  CHashTable *table=HashTableNew(16);
  CHashFun *fun=NULL,*old_fun=NULL,*saved=NULL,*out=NULL;
  CHash *entry;
  CMemberLst *orphan=NULL;
  CHashClass *base=cmp.internal_types[RT_I64],*type=NULL;
  CArrayDim dim;
  CCmpCtrl *cc=CmpCtrlNew(StrNew(source),flags,"C:/Probe/Join.HC");
  CLexFile *snapshot;
  CCodeCtrl *graph;
  CIntermediateCode *outer;
  Bool detached=FALSE;
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsSymbolServices symbols;
  table->next=Fs->hash_table;Fs->put_doc=doc;FJTable(cc,table);
  if(kind>=7){old_fun=FJSeed(table);if(kind==11)old_fun->use_cnt=0;saved=MAlloc(sizeof(CHashFun));MemCpy(saved,old_fun,sizeof(CHashFun));}
  COCInit(cc);outer=ICAdd(cc,IC_IMM_I64,99,base);graph=cc->coc.coc_next;
  Lex(cc);LexPush(cc);snapshot=cc->lex_prs_stk;fj_warning_kind=-1;
  try{
    if(3<=kind<=6)type=PrsType(cc,&base,&mode,NULL,NULL,&out,NULL,&dim,0);
    else if(kind>=10){
      PrsHostServices(&expression);PrsHostTypeServices(&types);PrsHostDeclarationServices(&declarations,&expression,&types);PrsHostSymbolServices(&symbols,&declarations);
      symbols.option=&FJOption;symbols.warning=&FJWarning;
      if(kind==10)base=cmp.internal_types[RT_F64];
      fun=PrsFunJoinCore(&symbols,cc,base,StrNew("JoinProbe"),0);
    }else if(kind>=7)fun=PrsFunJoin(cc,base,StrNew("JoinProbe"),0);
    else fun=PrsFunJoin(cc,base,NULL,0);
  }catch{r[0]=Fs->except_ch;Fs->catch_except=TRUE;}
  r[1]=cc->error_cnt;r[2]=(cc->flags&mask)==(flags&mask);r[3]=cc->lex_prs_stk==snapshot;
  r[4]=cc->coc.coc_next==graph;r[5]=r[4] && cc->coc.coc_head.next==outer && cc->coc.coc_head.last==outer && outer->ic_data==99;
  if(kind>=7){
    //The callee's single-table lookup increments use_cnt; observation must not.
    saved->use_cnt++;
    if(r[0])r[6]=FJContains(table,old_fun) && !MemCmp(old_fun,saved,sizeof(CHashFun)) && old_fun->idx && !StrCmp(old_fun->idx,"Join/Old") && old_fun->src_link && !StrCmp(old_fun->src_link,"FL:C:/Probe/OldHeader.HC,1");
    else r[6]=fun==old_fun && fun->arg_cnt==1 && fun->member_lst_and_root && fun->member_lst_and_root->dft_val==9;
    detached=r[0] && old_fun->member_lst_and_root!=saved->member_lst_and_root;
  }else if(r[0])r[6]=!fun && !out;
  else if(kind==2)r[6]=fun && fun->arg_cnt==1 && fun->member_lst_and_root && fun->member_lst_and_root->dft_val==42;
  else r[6]=out && out->ptr_stars_cnt==1 && (out-1)->arg_cnt==1 && type==cmp.internal_types[RT_PTR]+1 && dim.total_cnt==6 && dim.next && dim.next->cnt==2 && dim.next->next && dim.next->next->cnt==3;
  for(bucket=0;bucket<=table->mask;bucket++)for(entry=table->body[bucket];entry;entry=entry->next)count++;
  r[10]=fj_warning_kind;r[11]=count;
  if(kind<3 && fun)HashDel(fun);
  if(3<=kind<=6 && out){LinkedLstDel(dim.next);HashDel(out-out->ptr_stars_cnt);}
  HashTableDel(table);
  while(cc->coc.coc_next!=graph){COCDel(cc,&cc->coc);COCPop(cc);}
  COCDel(cc,&cc->coc);CmpCtrlDel(cc);Fs->put_doc=old_doc;DocDel(doc);TaskWait(adam_task);
  //The saved list is still live only when a failed implementation detached it.
  if(detached)orphan=saved->member_lst_and_root;
  Free(saved);r[7]=Fs->data_heap->used_u8s-used;r[8]=Fs->code_heap->used_u8s-code_used;
  if(orphan)MemberLstDel(orphan);
  r[9]=EEGood;
}
U0 FJCheck()
{
  I64 *r=CAlloc(156*8);U8 *s;
  FJCase(r,"(I64 arg=EEThrow())",0);
  FJCase(r+12,"(I64 arg,I64 arg)",1);
  FJCase(r+24,"(I64 arg=42)",2);
  FJCase(r+36,"(*)(I64 arg=EEThrow());",3);
  FJCase(r+48,"(*)(I64 arg)[2][EEThrow()];",4);
  FJCase(r+60,"(*)(I64 arg)[2);",5);
  FJCase(r+72,"(*)(I64 arg)[2][3];",6);
  FJCase(r+84,"(I64 arg=EEThrow())",7);
  FJCase(r+96,"(I64 arg,I64 arg)",8);
  FJCase(r+108,"(I64 kept=9)",9);
  FJCase(r+120,"(I64 kept=9)",10);
  FJCase(r+132,"(I64 kept=9)",11);
  FJCase(r+144,"(I64 changed=9)",12);
  s=MStrPrint("EXPORT join-errors.bin %X 4E0\n",r);EELog(s);Free(s);
  EELog("JOIN ERRORS DONE\n");Sleep(1000);
}
FJCheck;
