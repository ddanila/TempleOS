//Original public compilation supplies the metadata oracle for internal parser calls.
U0 PCRLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
CMemberLst *PCRMember(CHashClass *type,U8 *name)
{
  CMemberLst *member=type->member_lst_and_root;
  while(member){if(!StrCmp(member->str,name))return member;member=member->next;}
  return NULL;
}
Bool PCRDelete(CHash *symbol)
{//Lookup traverses parents; deletion must name the actual owning table.
  CHashTable *table=Fs->hash_table;
  while(table) {
    if(HashSingleTableFind(symbol->str,table,symbol->type&~HTG_FLAGS_MASK)==symbol)
      return HashRemDel(symbol,table);
    table=table->next;
  }
  return FALSE;
}
U0 PCRCheck()
{
  I64 *r=CAlloc(12*8),used=Fs->data_heap->used_u8s,code_used=Fs->code_heap->used_u8s;U8 *s;
  CHashClass *type,*integer=HashFind("I64",Fs->hash_table,HTG_TYPE_MASK);
  CHashFun *fun;CMemberLst *value,*bytes,*first,*second;
  ExePutS("class ProbeRecord {I64 value;U8 bytes[3];};");
  type=HashFind("ProbeRecord",Fs->hash_table,HTT_CLASS);
  if(type && integer) {
    r[0]=1;r[1]=type->size==11 && type->member_cnt==2;
    value=PCRMember(type,"value");bytes=PCRMember(type,"bytes");
    r[2]=value && value->offset==0 && value->size==8 && value->member_class->raw_type==RT_I64;
    r[3]=bytes && bytes->offset==8 && bytes->size==3 && bytes->dim.total_cnt==3 &&
      bytes->dim.next && bytes->dim.next->cnt==3 && !bytes->dim.next->next;
    r[4]=HashFind("ProbeRecord",Fs->hash_table,HTT_CLASS)==type && PCRMember(type,"value")==value;
    ExePutS("I64 ProbeFunction(I64 first,I64 second=7);");
    fun=HashFind("ProbeFunction",Fs->hash_table,HTT_FUN);
    if(fun) {
      first=PCRMember(fun,"first");second=PCRMember(fun,"second");
      r[5]=fun->arg_cnt==2 && first && second && first->offset==2*sizeof(U8 *) &&
        second->offset==2*sizeof(U8 *)+8 && second->flags&MLF_DFT_AVAILABLE && second->dft_val==7;
      r[6]=fun->return_class==integer && fun->exe_addr && second->dft_val==7;
      r[10]=PCRDelete(fun) && !HashFind("ProbeFunction",Fs->hash_table,HTT_FUN);
    }
    r[11]=PCRDelete(type) && !HashFind("ProbeRecord",Fs->hash_table,HTT_CLASS);
    r[8]=Fs->data_heap->used_u8s-used;r[9]=Fs->code_heap->used_u8s-code_used;
    r[7]=!r[8] && !r[9];
  }
  s=MStrPrint("EXPORT public-classes.bin %X 60\n",r);PCRLog(s);Free(s);
  PCRLog("PUBLIC CLASSES DONE\n");Sleep(1000);
}
PCRCheck;
