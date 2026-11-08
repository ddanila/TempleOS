#ifndef CMP_JOIN_IMPL
#define CMP_JOIN_IMPL CmpJoin
#endif
CAOT *CMP_JOIN_IMPL(CCmpCtrl *cc,I64 cmp_flags,U8 *map_name=NULL,U8 mapfile_drv_let=0)
{
  CAOTCtrl *aotc,*old_aot=cc->aotc;
  I64 i,j,l;
  U8 *buf;
  CAOTBinBlk *tmpbin;
  CAOTImportExport *tmpie;
  Bool okay=TRUE;
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
    if (Fs->except_ch=='Compiler' && !(cmp_flags&CMPF_ASM_BLK)) {
      LexPutPos(cc);
      Fs->catch_except=TRUE;
    }
    okay=FALSE;
  }
  if (!okay) {
    if (cc->error_cnt<1)
      cc->error_cnt=1;
    cc->aot=res->parent_aot;
    Free(res);
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
  return res;
}

