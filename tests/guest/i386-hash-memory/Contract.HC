#include "/Kernel/SymbolTypes.HH"
class CHashMemoryLedger {U8 *blocks[128];I64 count,expected;};
U8 *HMAlloc(CHashMemoryLedger *ledger,I64 size,Bool counted=TRUE)
{
  U8 *block=CAlloc(size);
  if(!block || ledger->count>=128)throw('HMLedger',TRUE);
  ledger->blocks[ledger->count++]=block;
  if(counted)ledger->expected+=MSize2(block);
  return block;
}
U8 *HMString(CHashMemoryLedger *ledger,U8 *text,Bool counted=TRUE)
{
  U8 *result=HMAlloc(ledger,StrLen(text)+1,counted);StrCpy(result,text);return result;
}
U8 **HMLinks(CHashMemoryLedger *ledger)
{
  U8 **one=HMAlloc(ledger,128),**two=HMAlloc(ledger,160);
  *one=two;return one;
}
U0 HMSource(CHashMemoryLedger *ledger,CHashSrcSym *entry,I64 type,U8 *name)
{
  entry->type=type;entry->str=HMString(ledger,name);
  entry->src_link=HMString(ledger,"FI:::/Probe.HC");
  entry->idx=HMString(ledger,"index");entry->import_name=HMString(ledger,"import");
  entry->ie_lst=HMLinks(ledger)(CAOTImportExport *);
}
U0 HMDebug(CHashMemoryLedger *ledger,CHashSrcSym *entry,Bool code)
{
  CDbgInfo *info=HMAlloc(ledger,16);
  info->min_line=info->max_line=0;info->body[0]=100;info->body[1]=137;
  entry->dbg_info=info;if(code)ledger->expected+=37;
}
CHashFun *HMFunction(CHashMemoryLedger *ledger,Bool pointers=FALSE)
{
  CHashFun *function=HMAlloc(ledger,sizeof(CHashFun)*(1+2*pointers));
  HMSource(ledger,function,HTT_FUN,"Function");HMDebug(ledger,function,TRUE);
  if(pointers){function[2].ptr_stars_cnt=2;return function+2;}
  return function;
}
U0 HMMembers(CHashMemoryLedger *ledger,CHashClass *owner,Bool function_pointer)
{
  CMemberLst *member=HMAlloc(ledger,sizeof(CMemberLst));
  CMemberLstMeta *meta=HMAlloc(ledger,sizeof(CMemberLstMeta)),*second=HMAlloc(ledger,sizeof(CMemberLstMeta));
  owner->member_lst_and_root=member;member->str=HMString(ledger,"Member");
  member->dim.next=HMAlloc(ledger,sizeof(CArrayDim));
  member->dim.next->next=HMAlloc(ledger,sizeof(CArrayDim));
  member->flags=MLF_STR_DFT_AVAILABLE;member->dft_val=(HMString(ledger,"default")+0)(I64);
  member->meta=meta;meta->next=second;meta->str=HMString(ledger,"StringMeta");
  meta->flags=MLMF_IS_STR;meta->user_data=(HMString(ledger,"value")+0)(I64);
  second->str=HMString(ledger,"IntegerMeta");second->user_data=123;
  if(function_pointer){member->flags|=MLF_FUN;member->fun_ptr=HMFunction(ledger,TRUE);}
}
CHashGeneric *HMGeneric(CHashMemoryLedger *ledger,I64 type,U8 *name,Bool payload=FALSE,Bool counted=TRUE)
{
  CHashGeneric *entry=HMAlloc(ledger,sizeof(CHashGeneric),counted);
  entry->type=type;entry->str=HMString(ledger,name,counted);
  if(payload)entry->user_data0=(HMAlloc(ledger,79,counted && StrCmp(name,KERNEL_MODULE_NAME))+0)(I64);
  return entry;
}
I64 HashMemoryCase(I64 mode)
{
  I64 before=Fs->data_heap->used_u8s,actual=-1,mask=0,i;
  CHashMemoryLedger ledger;
  CHashSrcSym *entry=NULL;
  CHashDefineStr *define;
  CHashClass *type;
  CHashFun *function;
  CHashGlblVar *global;
  CHashGeneric *dictionary;
  CHashTable *table,*parent;
  U8 **list;
  MemSet(&ledger,0,sizeof(CHashMemoryLedger));
  switch(mode) {
    case 0:actual=HashTableSize2(NULL)+LinkedLstSize(NULL);break;
    case 1:list=HMLinks(&ledger);actual=LinkedLstSize(list);break;
    case 2:entry=HMGeneric(&ledger,HTT_KEYWORD,"Keyword");break;
    case 3:entry=HMGeneric(&ledger,HTT_WORD,"Word");break;
    case 4:
      dictionary=HMAlloc(&ledger,sizeof(CHashGeneric)+16);dictionary->type=HTT_DICT_WORD;
      dictionary->str=dictionary+1;StrCpy(dictionary->str,"Embedded");entry=dictionary;break;
    case 5:
      define=HMAlloc(&ledger,sizeof(CHashDefineStr));HMSource(&ledger,define,HTT_DEFINE_STR,"Define");
      define->data=HMString(&ledger,"definition");
      define->sub_idx=HMAlloc(&ledger,3*sizeof(U8 *),FALSE);entry=define;break;
    case 6:entry=HMGeneric(&ledger,HTT_FILE,"File",TRUE);break;
    case 7:entry=HMGeneric(&ledger,HTT_MODULE,"/Modules/Other",TRUE);break;
    case 8:entry=HMGeneric(&ledger,HTT_MODULE,KERNEL_MODULE_NAME,TRUE);break;
    case 9:
      entry=HMAlloc(&ledger,sizeof(CHashExport));HMSource(&ledger,entry,HTT_EXPORT_SYS_SYM,"Export");
      HMDebug(&ledger,entry,FALSE);break;
    case 10:entry=HMAlloc(&ledger,sizeof(CHashSrcSym));HMSource(&ledger,entry,HTT_HELP_FILE,"Help");break;
    case 11:
      type=HMAlloc(&ledger,sizeof(CHashClass));HMSource(&ledger,type,HTT_CLASS,"Class");
      HMMembers(&ledger,type,TRUE);entry=type;break;
    case 12:
      function=HMFunction(&ledger);HMMembers(&ledger,function,FALSE);entry=function;break;
    case 13:
    case 14:
    case 15:
      global=HMAlloc(&ledger,sizeof(CHashGlblVar));HMSource(&ledger,global,HTT_GLBL_VAR,"Global");
      global->dim.next=HMAlloc(&ledger,sizeof(CArrayDim));
      if(mode==14)global->flags=GVF_ALIAS;
      global->data_addr=HMAlloc(&ledger,95,mode!=14);
      if(mode==15)global->fun_ptr=HMFunction(&ledger,TRUE);
      entry=global;break;
    case 16:
      type=HMAlloc(&ledger,sizeof(CHashClass));type->type=HTT_INTERNAL_TYPE;
      type->str=HMString(&ledger,"Internal");entry=type;break;
    case 17:
      table=HMAlloc(&ledger,sizeof(CHashTable));table->mask=7;
      table->body=HMAlloc(&ledger,8*sizeof(U8 *));
      parent=HMAlloc(&ledger,sizeof(CHashTable),FALSE);parent->mask=7;
      parent->body=HMAlloc(&ledger,8*sizeof(U8 *),FALSE);table->next=parent;
      HashAdd(HMGeneric(&ledger,HTT_WORD,"ExcludedParent",FALSE,FALSE),parent);
      HashAdd(HMGeneric(&ledger,HTT_WORD,"One"),table);
      HashAdd(HMGeneric(&ledger,HTT_FILE,"Two",TRUE),table);
      HashAdd(HMGeneric(&ledger,HTT_MODULE,"Three",TRUE),table);
      actual=HashTableSize2(table);break;
  }
  if(entry)actual=HashEntrySize2(entry);
  if(actual==ledger.expected)mask|=1;
  for(i=ledger.count-1;i>=0;i--)Free(ledger.blocks[i]);
  if(Fs->data_heap->used_u8s==before)mask|=2;
  return mask;
}
