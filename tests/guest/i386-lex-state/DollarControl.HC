I64 dollar_calls,dollar_releases,dollar_fail;
U8 *DollarFormat(CI386Heap *heap,CDoc *doc,CDocEntry *entry)
{//Binding/ownership probe; payload serialization is checked against the real OS.
  U8 *result;I64 i;
  dollar_calls++;
  if(heap!=&state_heap || doc->doc_signature!=DOC_SIGNATURE_VAL ||
      entry->attr<0 || entry->attr>1) {state_free_errors++;return 0;}
  if(dollar_fail)return I386HeapAlloc(heap,0x10000000,FALSE);
  result=I386HeapAlloc(heap,1025,FALSE);
  if(result) {for(i=0;i<1024;i++)result[i]='A'+entry->attr;result[1024]=0;}
  return result;
}
U0 DollarDocument(U8 *context,CDoc *doc)
{
  CDocEntry *entry=doc->head.next,*next;
  if(context!=&dollar_releases)state_free_errors++;
  while(entry!=doc){next=entry->next;StateFree(entry);entry=next;}
  dollar_releases++;StateFree(doc);
}
I64 NativeDollarControlTest()
{
  CCmpCtrl *cc;CDoc *doc;CDocEntry *first,*second;
  I64 enabled,mode,i,lines,expected,flags=GetRFlags;
  for(enabled=0;enabled<2;enabled++)for(mode=0;mode<4;mode++) {
    SetRFlags((flags&~0x200)|(enabled*0x200));
    dollar_calls=dollar_releases=0;dollar_fail=mode==2;
    if(mode==3)I386LexDocFormatProvider(0);
    else I386LexDocFormatProvider(&DollarFormat);
    if((GetRFlags&0x200)!=enabled*0x200)return 160;
    cc=I386CmpCtrlNew(&state_heap,"R",CCF_DONT_FREE_BUF|CCF_IN_QUOTES,"Dollar",0,char_bmp_alpha_numeric);
    doc=StateAlloc(sizeof(CDoc));first=StateAlloc(sizeof(CDocEntry));second=StateAlloc(sizeof(CDocEntry));
    if(!cc || !doc || !first || !second)return 161;
    doc->doc_signature=DOC_SIGNATURE_VAL;doc->head.next=first;first->next=second;second->next=doc;
    first->type=DOCT_LINK;first->attr=0;
    second->type=DOCT_TEXT;second->de_flags=DOCEF_TAG|DOCEF_AUX_STR;second->tag="metadata";second->attr=1;
    if(mode==0) {if(!I386LexAttachDocRoot(&state_heap,cc,doc))return 162;}
    else if(!I386LexIncludeDocTake(&state_heap,cc,"child.HC",doc,&DollarDocument,&dollar_releases))return 163;
    lines=0;
    if(mode>=2) {
      if(I386LexRawChar(&state_heap,cc,&lines)!=-1 || dollar_calls!=(mode==2))return 164;
    } else {
      for(i=0;i<2048;i++) {
        expected='A';if(i>=1024)expected='B';
        if(I386LexRawChar(&state_heap,cc,&lines)!=expected)return 165;
      }
      if(dollar_calls!=2 || !cc->dollar_buf)return 166;
      if(mode==1 && I386LexRawChar(&state_heap,cc,&lines)!='R')return 167;
      if(I386LexRawChar(&state_heap,cc,&lines)!=TK_EOF)return 168;
    }
    if(!I386CmpCtrlDel(&state_heap,cc))return 169;
    if(mode==0)DollarDocument(&dollar_releases,doc);
    if(dollar_releases!=1 || state_free_errors || state_heap.used || state_heap.allocations ||
        !I386HeapValid(&state_heap) || (GetRFlags&0x200)!=enabled*0x200)return 170;
  }
  I386LexDocFormatProvider(0);I386IrqRestore(flags);
  return 0;
}
