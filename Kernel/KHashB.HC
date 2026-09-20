#include "/Kernel/HashValue.HC"

extern U0 SysTry(U8 *catch_start,U8 *untry_start);
extern U0 SysUntry();
#include "/Kernel/HashTablePublicCore.HC"
CHashTable *HashTableNew(I64 size,CTask *mem_task=NULL)
{//New hash table, power-of-two in size.
  return HashTableNewCore(size,mem_task,&CAlloc,&Free);
}

#include "/Kernel/SymbolDelete.HC"
U0 SymbolSystemFree(U8 *context,U8 *allocation)
{
  Free(allocation);
}
U0 HashDel(CHashSrcSym *symbol)
{
  CSymbolRelease owner;
  owner.context=0; owner.release=&SymbolSystemFree;
  SymbolHashDel(&owner,symbol);
}

U0 HashTableDel(CHashTable *table)
{//Delete owned standard system entries; the chained parent remains borrowed.
  HashTableDelCore(table,&HashDel,&Free);
}

I64 HashTablePurge(CHashTable *table)
{//Eliminate ExportSysSyms that have been usurped.
  I64 i,res=0;
  CHashSrcSym *tmph,*tmph1,*tmph2;
  if (!table) return 0;
  PUSHFD
  CLI	 //Precaution
  for (i=0;i<=table->mask;i++) {
    tmph=table->body[i];
    while (tmph) {
      tmph1=tmph->next; //We delete only older ones
      if (tmph->type&(HTT_FUN|HTT_GLBL_VAR)) {
	tmph2=tmph->next; //Older always later in chain
	while (tmph2) {
	  if ((tmph2->type&HTT_EXPORT_SYS_SYM ||
		tmph2->type&HTG_TYPE_MASK==HTT_INVALID) &&
		!StrCmp(tmph2->str,tmph->str)) {
	    if (tmph2->type&HTG_TYPE_MASK==HTT_INVALID)
	      tmph2->type=HTT_KEYWORD;//Won't delete HTT_INVALID
	    HashRemDel(tmph2,table);
	    res++;
	    break;
	  }
	  tmph2=tmph2->next;
	}
      }
      tmph=tmph1;
    }
  }
  POPFD
  return res;
}

CHashGeneric *HashGenericAdd(U8 *name,I64 type,
	I64 u0=0,I64 u1=0,I64 u2=0,CTask *task=NULL)
{//Add any type to task hash_table, 3 user_data values.
  if (!task) task=Fs;
  CHashGeneric *res=CAlloc(sizeof(CHashGeneric),task);
  res->type=type;
  res->user_data0=u0;
  res->user_data1=u1;
  res->user_data2=u2;
  res->str=StrNew(name,task);
  HashAdd(res,task->hash_table);
  return res;
}

U0 HashSrcFileSet(CCmpCtrl *cc,CHashSrcSym *h,I64 line_num_offset=0)
{//Set $LK,"CHashSrcSym",A="MN:CHashSrcSym"$ link and help_index by cur cc pos.
  CLexFile *tmpf=cc->lex_include_stk;
  I64 line_num=tmpf->line_num+line_num_offset;
  if (line_num<1) line_num=1;
  Free(h->src_link);
  h->src_link=MStrPrint("FL:%s,%d",tmpf->full_name,line_num);
  if (Bt(&cc->opts,OPTf_KEEP_PRIVATE))
    h->type|=HTF_PRIVATE;
  Free(h->idx);
  if (cc->cur_help_idx && *cc->cur_help_idx)
    h->idx=StrNew(cc->cur_help_idx);
  else
    h->idx=NULL;
}

CHashGeneric *HashPublic(U8 *st,I64 mask,Bool val=TRUE)
{//Mark a hash entry as public and $LK,"HashSrcFileSet",A="MN:HashSrcFileSet"$().
  CHashGeneric *res;
  if (res=HashFind(st,Fs->hash_table,mask)) {
    if (val)
      res->type|=HTF_PUBLIC;
    else
      res->type&=~HTF_PUBLIC;
    if (res->type&HTG_SRC_SYM)
      HashSrcFileSet(Fs->last_cc,res);
    return res;
  } else
    return NULL;
}

I64 HashLstAdd(U8 *lst,I64 type,CHashTable *table)
{//Add a list; @ entries alias the previous ordinal.
  return HashLstAddCore(lst,type,table,&CAlloc,&StrNew,&Free,&HashAdd);
}

I64 HashDefineLstAdd(U8 *dname,I64 type,CHashTable *table)
{//Add define list to a hash table. See $LK,"::/Adam/DolDoc/DocInit.HC",A="FF:::/Adam/DolDoc/DocInit.HC,HashDefineLstAdd"$.
  CHashDefineStr *tmph;
  if (tmph=HashFind(dname,Fs->hash_table,HTT_DEFINE_STR))
    return HashLstAdd(tmph->data,type,table);
  else
    return 0;
}

I64 FramePtr(U8 *name,CTask *task=NULL)
{//Find entry in task->hash_table, Return user_data.
  CHashGeneric *tmph;
  if (!task) task=Fs;
  if (tmph=HashFind(name,task->hash_table,HTT_FRAME_PTR))
    return tmph->user_data0;
  else
    return 0;
}

CHashGeneric *FramePtrAdd(U8 *name,I64 val=0,CTask *task=NULL)
{//Add named value to task->hash_table.
  return HashGenericAdd(name,HTT_FRAME_PTR,val,0,0,task);
}

I64 FramePtrSet(U8 *name,I64 val,CTask *task=NULL)
{//Find hash entry in task->hash_table. Change user_data0.
  CHashGeneric *tmph;
  if (!task) task=Fs;
  if (tmph=HashFind(name,task->hash_table,HTT_FRAME_PTR))
    return LXchgI64(&tmph->user_data0,val);
  else
    return 0;
}

I64 FramePtrDel(U8 *name,CTask *task=NULL)
{//Remove entry and delete.
  CHashGeneric *tmph;
  I64 res=0;
  if (!task) task=Fs;
  if (tmph=HashFind(name,task->hash_table,HTT_FRAME_PTR)) {
    res=tmph->user_data0;
    HashRemDel(tmph,task->hash_table);
  }
  return res;
}
