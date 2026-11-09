#ifndef CMP_JOIN_CODE_ABORT
#define CMP_JOIN_CODE_ABORT CmpCodeAbort
#endif
U0 CmpJoinUnresolvedDel(CAsmUnresolvedRef *ref)
{
  CAsmUnresolvedRef *next;
  while(ref) {
    next=ref->next; Free(ref->machine_code); LinkedLstDel(ref->asm_undef_hash);
    Free(ref->str); Free(ref); ref=next;
  }
}
#ifndef CMP_JOIN_IMPL
#define CMP_JOIN_IMPL CmpJoin
#endif
CAOT *CMP_JOIN_IMPL(CCmpCtrl *cc,I64 cmp_flags,U8 *map_name=NULL,U8 mapfile_drv_let=0)
{
  CAOTCtrl *aotc,*old_aot=cc->aotc;
  I64 i,j,l;
  CCodeCtrl *code_boundary=cc->coc.coc_next;
  CHashTable *owned_globals;
  CHashFun *fun;
  CLexHashTableContext *nested;
  CStreamBlk *stream;
  CAOT *child;
  U8 *buf;
  CAOTBinBlk *tmpbin;
  CAOTImportExport *tmpie;
  Bool okay=TRUE,propagate=FALSE;
  CLexHashTableContext *htc=MAlloc(sizeof(CLexHashTableContext));
  CAOT *res=CAlloc(sizeof(CAOT)),*parent;
  if (parent=cc->aot) {
    res->parent_aot=parent;
    QueIns(res,parent->last);
  } else
    QueInit(res);
  cc->aot=res;

  res->next_ie=res->last_ie=&res->next_ie;
  cc->aotc=aotc=CAlloc(sizeof(CAOTCtrl));
  cc->aot_depth++;

  aotc->bin=CAlloc(sizeof(CAOTBinBlk));
  aotc->max_align_bits=0;
  aotc->org=INVALID_PTR;

  MemCpy(htc,&cc->htc,sizeof(CLexHashTableContext));
  if (cc->htc.fun)
    cc->htc.glbl_hash_table=HashTableNew(128);
  else
    cc->htc.glbl_hash_table=HashTableNew(1024);
  owned_globals=cc->htc.glbl_hash_table;
  if (cc->flags&CCF_AOT_COMPILE) {
    cc->htc.define_hash_table=cc->htc.glbl_hash_table;
    if (cc->aot_depth<=1)
      cc->htc.glbl_hash_table->next=cmp.asm_hash;
    else
      cc->htc.glbl_hash_table->next=htc->glbl_hash_table;
  } else
    cc->htc.glbl_hash_table->next=Fs->hash_table;
  cc->htc.hash_table_lst=cc->htc.local_hash_table=HashTableNew(16);
  cc->htc.local_hash_table->next=cc->htc.glbl_hash_table;
  cc->htc.local_var_lst=cc->htc.fun; //HolyC local vars
  cc->htc.fun=NULL;
  try {
    if (cmp_flags&CMPF_LEX_FIRST)
      Lex(cc);
    if (!(cmp_flags&CMPF_ONE_ASM_INS))
      cmp_flags|=CMPF_PRS_SEMICOLON;
    if (cc->flags&CCF_AOT_COMPILE) {
      while (cc->token!=TK_EOF) {
	buf=LexStmt2Bin(cc,NULL,cmp_flags);
	if (buf!=INVALID_PTR) {
	  tmpie=CAlloc(sizeof(CAOTImportExport));
	  tmpie->type=IET_MAIN;
	  tmpie->rip=buf;
	  QueIns(tmpie,res->last_ie);
	}
	if (cmp_flags&CMPF_ASM_BLK)
	  break;
      }
    } else
      PrsStmt(cc,,,cmp_flags);
    AOTGlblsResolve(cc,res);
  } catch {
    if (Fs->except_ch=='Compiler') {
      //Catch an inner assembly error long enough to restore its owned scope.
      //The enclosing join still receives the same Compiler exception.
      Fs->catch_except=TRUE;
      if(cmp_flags&CMPF_ASM_BLK) propagate=TRUE;
      else LexPutPos(cc);
    }
    okay=FALSE;
  }
  if (!okay) {
    if (cc->error_cnt<1)
      cc->error_cnt=1;
    CMP_JOIN_CODE_ABORT(cc,code_boundary,!parent);
    //A failed #exe can leave borrowed task tables installed above our scope.
    while(cc->htc.next!=htc->next) {
      nested=cc->htc.next;
      MemCpy(&cc->htc,nested,sizeof(CLexHashTableContext)); Free(nested);
    }
    CmpJoinUnresolvedDel(aotc->local_unresolved);
    CmpJoinUnresolvedDel(aotc->glbl_unresolved);
    //Unresolved function call sites belong to this temporary symbol table.
    for(i=0;i<=owned_globals->mask;i++) {
      fun=owned_globals->body[i];
      while(fun) {
        if(fun->type&HTT_FUN) { LinkedLstDel(fun->ext_lst); fun->ext_lst=NULL; }
        fun=fun->next;
      }
    }
    HashTableDel(cc->htc.local_hash_table);
    HashTableDel(owned_globals);
    if(!parent) {
      while(cc->next_stream_blk!=&cc->next_stream_blk) {
        stream=cc->next_stream_blk; QueRem(stream); Free(stream->body); Free(stream);
      }
    }
    //Code graph destruction unlinks any inline-assembly packets it owns.
    if(!parent) while(res->next!=res) {
      //As in Cmp's QueDel: consumed children are borrowed header views.
      //Their bytes/records have already moved to the function/parent packet.
      child=res->next; QueRem(child); Free(child);
    }
    QueRem(res);
    res->abss=aotc->abss; res->heap_glbls=aotc->heap_glbls;
    CmpAbortPacketDel(res,FALSE); //Packing has not allocated a result buffer yet.
    LinkedLstDel(aotc->bin);
    res=NULL;
  } else {
    if (map_name)
      MapFileWrite(cc->htc.glbl_hash_table,map_name,mapfile_drv_let);
    HashTableDel(cc->htc.local_hash_table);
    HashTableDel(cc->htc.glbl_hash_table);

    if (!aotc->num_bin_U8s)
      res->buf=NULL;
    else {
      if (cc->flags&CCF_AOT_COMPILE)
	res->buf=MAlloc(aotc->num_bin_U8s);
      else {
	if (aotc->org==INVALID_PTR)
	  res->buf=MAlloc(aotc->num_bin_U8s,Fs->code_heap);
	else
	  res->buf=aotc->org;
      }
      res->aot_U8s=aotc->num_bin_U8s;
      tmpbin=aotc->bin;
      j=0;
      l=aotc->num_bin_U8s;
      while (tmpbin) {
	i=l;
	if (i>AOT_BIN_BLK_SIZE)
	  i=AOT_BIN_BLK_SIZE;
	MemCpy(res->buf+j,tmpbin->body,i);
	j+=i;
	l-=i;
	tmpbin=tmpbin->next;
      }
    }
    LinkedLstDel(aotc->bin);
    res->abss=aotc->abss;
    res->heap_glbls=aotc->heap_glbls;
    res->max_align_bits=aotc->max_align_bits;
    res->org=aotc->org;
  }
  cc->aot=parent;
  MemCpy(&cc->htc,htc,sizeof(CLexHashTableContext));
  Free(htc);
  Free(aotc);
  cc->aotc=old_aot;
  cc->aot_depth--;
  if(propagate) throw('Compiler');
  return res;
}
