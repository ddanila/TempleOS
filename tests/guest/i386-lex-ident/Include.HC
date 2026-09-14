I64 NativeIncludeTest()
{
  CCmpCtrl cc; CLexFile parent,*child; CI386Heap small;
  U8 input[4],name[8],source[8]; I64 size,lines=0,failures=0,successes=0,result,mode;
  U32 flags,after;
  input[0]=59; input[1]=0; name[0]='N'; name[1]=0; source[0]='a'; source[1]=0;
  IdentSeed(&cc,&parent,input); cc.flags|=CCF_USE_LAST_U16; cc.last_U16=59; cc.cur_buf_ptr=input+1;
  if(I386LexIncludeCopy(&ident_heap,0,name,source) ||
      I386LexIncludeCopy(&ident_heap,&cc,0,source) || I386LexIncludeCopy(&ident_heap,&cc,name,0) ||
      ident_heap.used || cc.lex_include_stk!=&parent || cc.cur_buf_ptr!=input+1) return 140;
  if(!I386LexIncludeCopy(&ident_heap,&cc,name,source,TRUE)) return 141;
  child=cc.lex_include_stk; name[0]='X'; source[0]='z';
  if(child==&parent || child->next!=&parent || child->depth!=parent.depth+1 ||
      child->full_name==name || child->buf==source || child->full_name[0]!='N' || child->buf[0]!='a' ||
      child->line_num!=1 || !(child->flags&LFSF_DEFINE) || cc.flags&CCF_USE_LAST_U16 ||
      parent.buf_ptr!=input+1 || parent.last_U16!=59 || ident_heap.allocations!=3) return 142;
  if(I386LexRawChar(&ident_heap,&cc,&lines)!='a' || I386LexRawChar(&ident_heap,&cc,&lines)!=59 ||
      cc.lex_include_stk!=&parent || cc.cur_buf_ptr!=input+1 || ident_heap.used || ident_heap.allocations ||
      source[0]!='z' || name[0]!='X') return 143;
  //Nested copies and an empty child return through the parent's cached character.
  IdentSeed(&cc,&parent,input); cc.cur_buf_ptr=input+1; cc.flags|=CCF_USE_LAST_U16; cc.last_U16=0x10041;
  if(!I386LexIncludeCopy(&ident_heap,&cc,"first","a",TRUE) ||
      !I386LexIncludeCopy(&ident_heap,&cc,"second","b") ||
      !I386LexIncludeCopy(&ident_heap,&cc,"empty","")) return 144;
  if(I386LexRawChar(&ident_heap,&cc,&lines)!='b' || I386LexRawChar(&ident_heap,&cc,&lines)!='a' ||
      I386LexRawChar(&ident_heap,&cc,&lines)!='A' || cc.lex_include_stk!=&parent ||
      ident_heap.used || ident_heap.allocations) return 145;
  //Saved positions remain live; EOF pop still requires their explicit release.
  IdentSeed(&cc,&parent,input); cc.cur_buf_ptr=input+1; cc.flags|=CCF_USE_LAST_U16; cc.last_U16=59;
  cc.lex_prs_stk=&parent;
  if(!I386LexIncludeCopy(&ident_heap,&cc,"pending","a",TRUE)) return 146;
  child=cc.lex_include_stk;
  if(I386LexRawChar(&ident_heap,&cc,&lines)!='a' || I386LexRawChar(&ident_heap,&cc,&lines)!=-1 ||
      cc.lex_include_stk!=child || ident_heap.allocations!=3) return 147;
  cc.lex_prs_stk=0;
  if(I386LexRawChar(&ident_heap,&cc,&lines)!=59 || ident_heap.used || ident_heap.allocations) return 148;
  //Arena sizes span failure of the record, name and source allocations.
  for(size=32;size<=224;size+=8) {
    if(!I386HeapInit(&small,0x50000,size)) return 149;
    IdentSeed(&cc,&parent,input); cc.cur_buf_ptr=input+1; cc.last_U16=59;
    cc.flags|=CCF_USE_LAST_U16; parent.last_U16=66;
    if(I386LexIncludeCopy(&small,&cc,"name","source",TRUE)) {
      successes++;
      if(!I386LexFilePop(&small,&cc)) return 150;
    } else {
      failures++;
      if(cc.lex_include_stk!=&parent || cc.cur_buf_ptr!=input+1 || cc.last_U16!=59 ||
          !(cc.flags&CCF_USE_LAST_U16) || parent.buf_ptr!=input || parent.last_U16!=66) return 151;
    }
    if(small.used || small.allocations || !I386HeapValid(&small)) return 152;
  }
  if(!successes || !failures) return 153;
  //This runner has no hardware IRQ gates; isolate IF preservation from delivery.
  OutU8(0x21,255); OutU8(0xA1,255);
  for(mode=0;mode<2;mode++) {
    IdentSeed(&cc,&parent,input); flags=I386IrqSave;
    I386IrqRestore((flags&~0x200)|(mode<<9));
    result=I386LexIncludeCopy(&ident_heap,&cc,"flags","a"); after=GetRFlags;
    I386IrqRestore(flags);
    if(!result || (after&0x200)!=(mode<<9)) return 154;
    if(!I386LexFilePop(&ident_heap,&cc)) return 155;
  }
  return 0;
}
