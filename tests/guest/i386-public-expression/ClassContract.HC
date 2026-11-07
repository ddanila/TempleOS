//Observe actual parser-created metadata in an owned, isolated symbol table.
U0 PCLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
CMemberLst *PCMember(CHashClass *type,U8 *name)
{
  CMemberLst *member=type->member_lst_and_root;
  while(member){if(!StrCmp(member->str,name))return member;member=member->next;}
  return NULL;
}
CCmpCtrl *PCControl(U8 *source,CHashTable *table)
{
  I64 flags=0;
#ifdef CCF_TARGET_I386
  flags=CCF_TARGET_I386;
#endif
  CCmpCtrl *cc=CmpCtrlNew(StrNew(source),flags,"C:/Probe/Class.HC");
  cc->htc.glbl_hash_table=cc->htc.local_hash_table=cc->htc.hash_table_lst=table;
  return cc;
}
U0 PCCheck()
{
  CHashFun *class_entry=HashFind("PrsClass",Fs->hash_table,HTT_FUN);
  CHashFun *fun_entry=HashFind("PrsFunJoin",Fs->hash_table,HTT_FUN),*fun;
  CHashGeneric *keyword=HashFind("class",Fs->hash_table,HTT_KEYWORD);
  CHashClass *integer=HashFind("I64",Fs->hash_table,HTG_TYPE_MASK),*type;
  CHashClass *(*parse_class)(CCmpCtrl *cc,I64 keyword,I64 flags,Bool is_extern);
  CHashFun *(*parse_fun)(CCmpCtrl *cc,CHashClass *type,U8 *name,I64 flags);
  CMemberLst *value,*bytes,*first,*second;CCmpCtrl *cc;CHashTable *table;
  I64 *r=CAlloc(8*8),used=Fs->data_heap->used_u8s,code_used=Fs->code_heap->used_u8s;U8 *s;
  if(class_entry && fun_entry && keyword && integer) {
    r[0]=1;parse_class=class_entry->exe_addr;parse_fun=fun_entry->exe_addr;
    table=HashTableNew(32);table->next=Fs->hash_table;
    cc=PCControl("ProbeRecord {I64 value;U8 bytes[3];};",table);Lex(cc);
    type=(*parse_class)(cc,keyword->user_data0,0,FALSE);
    r[1]=type && type->size==11 && type->member_cnt==2 && cc->token==';' && !cc->error_cnt && !cc->warning_cnt;
    value=PCMember(type,"value");bytes=PCMember(type,"bytes");
    r[2]=value && value->offset==0 && value->size==8 && value->member_class->raw_type==RT_I64;
    r[3]=bytes && bytes->offset==8 && bytes->size==3 && bytes->dim.total_cnt==3 &&
      bytes->dim.next && bytes->dim.next->cnt==3 && !bytes->dim.next->next;
    CmpCtrlDel(cc);
    r[4]=HashFind("ProbeRecord",table,HTT_CLASS)==type && PCMember(type,"value")==value;
    cc=PCControl("(I64 first,I64 second=7);",table);Lex(cc);
    fun=(*parse_fun)(cc,integer,StrNew("ProbeFunction"),0);
    first=PCMember(fun,"first");second=PCMember(fun,"second");
    r[5]=fun && fun->arg_cnt==2 && first && second &&
      first->offset==2*sizeof(U8 *) && second->offset==2*sizeof(U8 *)+8 &&
      second->flags&MLF_DFT_AVAILABLE && second->dft_val==7 && cc->token==';' && !cc->error_cnt && !cc->warning_cnt;
    CmpCtrlDel(cc);
    r[6]=HashFind("ProbeFunction",table,HTT_FUN)==fun && fun->return_class==integer && fun->exe_addr && second->dft_val==7;
    HashTableDel(table);
    r[7]=Fs->data_heap->used_u8s==used && Fs->code_heap->used_u8s==code_used;
  }
  s=MStrPrint("EXPORT public-classes.bin %X 40\n",r);PCLog(s);Free(s);
  PCLog("PUBLIC CLASSES DONE\n");Sleep(1000);
}
PCCheck;
