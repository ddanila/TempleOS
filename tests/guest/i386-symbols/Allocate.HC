I64 SymbolAllocTest()
{
  CI386Heap heap,tiny;
  CHashClass *base,*derived,*small;
  CHashFun *function;
  CHashTable *table;
  CMemberLst member;
  U32 flags=I386IrqSave;
  I64 used,result;
  U8 *all;
  OutU8(0x21,255); OutU8(0xA1,255);
  if(!I386HeapInit(&heap,0x40000,65536) || !I386HeapInit(&tiny,0x51000,512)) return 30;
  SetRFlags(GetRFlags|0x200);
  if(I386PrsClassNew(0) || I386PrsFunNew(0) || !(GetRFlags&0x200)) return 31;
  small=I386PrsClassNew(&tiny);
  if(!small || I386PrsFunNew(&tiny) || I386PrsClassNew(&tiny) ||
      tiny.allocations!=1 || !I386HeapFree(&tiny,small) || tiny.used ||
      I386PrsFunNew(&tiny) || tiny.used || tiny.allocations || !(GetRFlags&0x200)) return 32;
  base=I386PrsClassNew(&heap); function=I386PrsFunNew(&heap);
  if(!base || !function || !(GetRFlags&0x200)) return 33;
  I386IrqSave;
  if(I386HeapSize(&heap,base)!=sizeof(CHashClass)*5 ||
      I386HeapSize(&heap,function)!=sizeof(CHashFun)*5) return 34;
  result=SymbolSeedCheck(base,function,4);
  if(result) return 40+result;
  used=heap.used;
  if(I386HeapFree(&heap,base+1) || I386HeapFree(&heap,function+1) || heap.used!=used) return 35;
  derived=I386PrsClassNew(&heap); table=I386HashTableNew(&heap,8);
  if(!derived || !table) return 36;
  base->str="Base"; derived->str="Derived"; function->str="Function";
  derived->base_class=base;
  member.str="field"; member.left=0; member.right=0; member.next=0;
  member.use_cnt=0; member.offset=0x100000008; member.member_class=base+2;
  //Exercise the real constructor's member-list tail sentinel as the parser does.
  base->last_in_member_lst->next=&member; base->last_in_member_lst=&member;
  if(base->member_lst_and_root!=&member || MemberFind("field",derived)!=&member ||
      member.offset!=0x100000008 || member.member_class->ptr_stars_cnt!=2) return 37;
  function->return_class=derived+1; function->exe_addr=0xF1234567;
  HashAdd(base,table); HashAdd(derived,table); HashAdd(function,table);
  if(HashFind("Base",table,HTT_CLASS)!=base || HashFind("Derived",table,HTT_CLASS)!=derived ||
      HashFind("Function",table,HTT_FUN)!=function || HashVal(function)!=0xF1234567 ||
      function->return_class-function->return_class->ptr_stars_cnt!=derived) return 38;
  if(!I386HashTableRemove(&heap,table,base) || !I386HashTableRemove(&heap,table,derived) ||
      !I386HashTableRemove(&heap,table,function) || !I386HashTableDelete(&heap,table)) return 39;
  //Nested records/names here are borrowed; detach them before releasing root arrays.
  base->member_lst_and_root=0; base->str=0; derived->base_class=0; derived->str=0;
  function->str=0; function->return_class=0;
  if(!I386HeapFree(&heap,function) || !I386HeapFree(&heap,derived) ||
      !I386HeapFree(&heap,base) || heap.used || heap.allocations || !I386HeapValid(&heap)) return 46;
  all=I386HeapAlloc(&heap,65520);
  if(!all || !I386HeapFree(&heap,all)) return 47;
  I386IrqRestore(flags);
  return 0;
}
