//Explicitly loaded test support; operational callbacks remain in the console.
#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#define NULL 0
#include "/Kernel/NumericLimits.HH"
#include "/Kernel/CharCodes.HH"
#include "/Kernel/I386/DocDiagnosticContext.HH"
#include "/Kernel/I386/Memory.HH"
#include "/Kernel/I386/Intrinsic.HH"
#include "/Kernel/I386/Queue.HH"
public _intern 0x15 CTask *Fs();
import U0 SysTry(U8 *catch_start,U8 *untry_start);
import U0 SysUntry();
import U0 throw(I64 ch=0,Bool no_log=FALSE);
CI386DocDiagnosticContext *doc_diag_context;
U8 *MAlloc(I64 n,CTask *t=NULL){return (*doc_diag_context->alloc)(n,t);}
U8 *CAlloc(I64 n,CTask *t=NULL){return (*doc_diag_context->calloc)(n,t);}
U0 Free(U8 *p){(*doc_diag_context->free)(p);}
U8 *StrNew(U8 *p,CTask *t=NULL){return (*doc_diag_context->str_new)(p,t);}
I64 StrCmp(U8 *a,U8 *b){return (*doc_diag_context->str_cmp)(a,b);}
CDoc *DocNew(U8 *n=NULL,CTask *t=NULL){return (*doc_diag_context->doc_new)(n,t);}
U0 DocDel(CDoc *d){(*doc_diag_context->doc_del)(d);}
U0 DocPutKey(CDoc *d,I64 ch=0,I64 sc=0){(*doc_diag_context->put_key)(d,ch,sc);}
U0 DocInsEntry(CDoc *d,CDocEntry *e){(*doc_diag_context->ins_entry)(d,e);}
U8 *DocSave(CDoc *d,I64 *n=NULL){return (*doc_diag_context->save)(d,n);}
U8 *NativeDocRecordSaveCore(CDoc *d,I64 *n=NULL){return DocSave(d,n);}
Bool NativeDocRecordLoadCore(CDoc *d,U8 *p,I64 n){return (*doc_diag_context->load)(d,p,n);}
Bool DocWrite(CDoc *d,Bool p=FALSE){return (*doc_diag_context->write)(d,p);}
CDoc *DocRead(U8 *n=NULL,I64 f=0){return (*doc_diag_context->read)(n,f);}
U0 NativeDocAllocArm(I64 n){(*doc_diag_context->arm)(n);}
Bool NativeDocClipCopy(CDoc *d,Bool clear=TRUE){return (*doc_diag_context->copy_clip)(d,clear);}
Bool NativeDocClipPaste(CDoc *d){return (*doc_diag_context->paste_clip)(d);}
#define native_clip_doc (*doc_diag_context->clipboard)
#define native_doc_alloc_count (*doc_diag_context->alloc_count)
Bool NativeDocAllocationCaught(U0 (*action)(CDoc *doc),CDoc *doc)
{
  Bool caught=FALSE;
  try { (*action)(doc); }
  catch {
    if(Fs->except_ch=='OutMem') { Fs->catch_except=TRUE; caught=TRUE; }
  }
  NativeDocAllocArm(0);
  return caught;
}

U0 NativeDocAllocationPut(CDoc *doc) { DocPutKey(doc,'X',0); }

U0 NativeDocAllocationNewLine(CDoc *doc) { DocPutKey(doc,'\n',0); }

U0 NativeDocAllocationSave(CDoc *doc) { U8 *text=DocSave(doc); Free(text); }

I64 NativeDocRecordSaveCheck()
{
  CDoc *doc,*loaded;
  CDocEntry *entry;
  U8 *saved,*round_trip;
  I64 before=Fs->data_heap->used_u8s,size,round_trip_size,result=4,index;
  doc=DocNew("C:/Record.DD",Fs);
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_FOREGROUND; entry->de_flags=doc_diag_context->globals->dft_de_flags[DOCT_FOREGROUND];
  entry->attr=2; DocInsEntry(doc,entry);
  DocPutKey(doc,'r'); DocPutKey(doc,'e'); DocPutKey(doc,'d');
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_FOREGROUND; entry->de_flags=doc_diag_context->globals->dft_de_flags[DOCT_FOREGROUND];
  entry->attr=DOC_DFT; DocInsEntry(doc,entry);
  DocPutKey(doc,' '); DocPutKey(doc,'p'); DocPutKey(doc,'l');
  DocPutKey(doc,'a'); DocPutKey(doc,'i'); DocPutKey(doc,'n');
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_BACKGROUND; entry->de_flags=doc_diag_context->globals->dft_de_flags[DOCT_BACKGROUND];
  entry->attr=1; DocInsEntry(doc,entry);
  DocPutKey(doc,'b'); DocPutKey(doc,'l'); DocPutKey(doc,'u'); DocPutKey(doc,'e');
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_BACKGROUND; entry->de_flags=doc_diag_context->globals->dft_de_flags[DOCT_BACKGROUND];
  entry->attr=DOC_DFT; DocInsEntry(doc,entry);
  DocPutKey(doc,' '); DocPutKey(doc,'e'); DocPutKey(doc,'n'); DocPutKey(doc,'d');
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_INVERT; entry->de_flags=doc_diag_context->globals->dft_de_flags[DOCT_INVERT];
  entry->attr=1; DocInsEntry(doc,entry);
  DocPutKey(doc,' '); DocPutKey(doc,'i'); DocPutKey(doc,'n'); DocPutKey(doc,'v');
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_INVERT; entry->de_flags=doc_diag_context->globals->dft_de_flags[DOCT_INVERT];
  entry->attr=0; DocInsEntry(doc,entry);
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_UNDERLINE; entry->de_flags=doc_diag_context->globals->dft_de_flags[DOCT_UNDERLINE];
  entry->attr=1; DocInsEntry(doc,entry);
  DocPutKey(doc,' '); DocPutKey(doc,'u'); DocPutKey(doc,'n'); DocPutKey(doc,'d');
  DocPutKey(doc,'e'); DocPutKey(doc,'r');
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_UNDERLINE; entry->de_flags=doc_diag_context->globals->dft_de_flags[DOCT_UNDERLINE];
  entry->attr=0; DocInsEntry(doc,entry);
  DocPutKey(doc,' '); DocPutKey(doc,'d'); DocPutKey(doc,'o'); DocPutKey(doc,'n');
  DocPutKey(doc,'e');
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_BLINK; entry->de_flags=doc_diag_context->globals->dft_de_flags[DOCT_BLINK];
  entry->attr=1; DocInsEntry(doc,entry);
  DocPutKey(doc,' '); DocPutKey(doc,'f'); DocPutKey(doc,'l'); DocPutKey(doc,'a');
  DocPutKey(doc,'s'); DocPutKey(doc,'h');
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_BLINK; entry->de_flags=doc_diag_context->globals->dft_de_flags[DOCT_BLINK];
  entry->attr=0; DocInsEntry(doc,entry);
  doc->flags|=DOCF_NO_CURSOR;
  saved=NativeDocRecordSaveCore(doc,&size);
  if(!saved || size!=94) result=-20;
  else {
    for(index=0;index<94;index++) {
      if(index==0 || index==5 || index==9 || index==12 || index==19 ||
          index==24 || index==29 || index==32 || index==37 || index==42 ||
          index==47 || index==52 || index==53 || index==58 || index==65 ||
          index==70 || index==76 || index==81 || index==88 || index==93) {
        if(saved[index]!=36) result=-21-index;
      }
    }
    if(saved[1]!='F' || saved[2]!='G' || saved[3]!=',' || saved[4]!='2' ||
        saved[6]!='r' || saved[7]!='e' || saved[8]!='d' ||
        saved[10]!='F' || saved[11]!='G' ||
        saved[20]!='B' || saved[21]!='G' || saved[22]!=',' || saved[23]!='1' ||
        saved[25]!='b' || saved[26]!='l' || saved[27]!='u' || saved[28]!='e' ||
        saved[30]!='B' || saved[31]!='G' ||
        saved[38]!='I' || saved[39]!='V' || saved[41]!='1' ||
        saved[48]!='I' || saved[49]!='V' || saved[51]!='0' ||
        saved[54]!='U' || saved[55]!='L' || saved[57]!='1' ||
        saved[66]!='U' || saved[67]!='L' || saved[69]!='0' ||
        saved[77]!='B' || saved[78]!='K' || saved[80]!='1' ||
        saved[89]!='B' || saved[90]!='K' || saved[92]!='0' ||
        saved[71]!=' ' || saved[72]!='d' || saved[82]!=' ' ||
        saved[83]!='f' || saved[87]!='h') result=-40;
  }
  loaded=DocNew("C:/RecordRead.DD",Fs); loaded->flags|=DOCF_NO_CURSOR;
  if(result==4 && !NativeDocRecordLoadCore(loaded,saved,size)) result=-41;
  round_trip=NativeDocRecordSaveCore(loaded,&round_trip_size);
  if(result==4 && (!round_trip || round_trip_size!=size)) result=-42;
  else if(result==4) for(index=0;index<size;index++)
    if(round_trip[index]!=saved[index]) result=-43;
  Free(round_trip); Free(saved); DocDel(loaded); DocDel(doc);
  if(Fs->data_heap->used_u8s!=before) result=-44;
  return result;
}

I64 NativeDocBinarySaveCheck()
{
  CDoc *doc,*loaded,*truncated,*failed;
  CDocEntry *entry;
  CDocBin *bin;
  U8 *first,*second;
  I64 before=Fs->data_heap->used_u8s,first_size,second_size,index,result=5,
      fail,fail_before;
  Bool caught;
  doc=DocNew("C:/BinaryRecord.DD",Fs); doc->flags|=DOCF_NO_CURSOR;
  bin=CAlloc(sizeof(CDocBin),doc->mem_task);
  bin->num=7; bin->flags=0x1234; bin->size=5; bin->use_cnt=1;
  bin->data=MAlloc(5,doc->mem_task);
  bin->data[0]=1; bin->data[1]=2; bin->data[2]=0; bin->data[3]=0xFF; bin->data[4]=42;
  QueIns(bin,doc->bin_head.last);
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_SPRITE;
  entry->de_flags=doc_diag_context->globals->dft_de_flags[DOCT_SPRITE]|DOCEF_HAS_BIN;
  entry->tag=StrNew("dot",doc->mem_task); entry->bin_num=7; entry->bin_data=bin;
  DocInsEntry(doc,entry);
  first=DocSave(doc,&first_size);
  if(!first || first_size!=37 || first[0]!=36 || first[1]!='S' || first[2]!='P' ||
      first[5]!='d' || first[7]!='t' || first[13]!='1' || first[14]!=36 ||
      first[15] || first[16]!=1 || first[20]!=0x34 || first[21]!=0x12 ||
      first[24]!=5 || first[28]!=1 || first[32]!=1 || first[33]!=2 ||
      first[34]!=0 || first[35]!=0xFF || first[36]!=42) result=-1;
  loaded=DocNew("C:/BinaryRecordRead.DD",Fs); loaded->flags|=DOCF_NO_CURSOR;
  if(result==5 && !NativeDocRecordLoadCore(loaded,first,first_size)) result=-2;
  entry=loaded->head.next; bin=loaded->bin_head.next;
  if(result==5 && (entry==loaded || entry->next!=loaded || entry->type_u8!=DOCT_SPRITE ||
      StrCmp(entry->tag,"dot") || entry->bin_num!=1 || entry->bin_data!=bin ||
      bin==&loaded->bin_head || bin->next!=&loaded->bin_head || bin->size!=5 ||
      bin->use_cnt!=1 || bin->data[0]!=1 || bin->data[4]!=42)) result=-3;
  second=DocSave(loaded,&second_size);
  if(result==5 && (!second || second_size!=first_size)) result=-4;
  else if(result==5) for(index=0;index<first_size;index++)
    if(first[index]!=second[index]) result=-5;
  for(fail=1;fail<=4 && result==5;fail++) {
    fail_before=Fs->data_heap->used_u8s;
    failed=DocNew("C:/BinaryRecordFail.DD",Fs); caught=FALSE;
    NativeDocAllocArm(fail);
    try { NativeDocRecordLoadCore(failed,first,first_size); }
    catch {
      if(Fs->except_ch=='OutMem') { Fs->catch_except=TRUE; caught=TRUE; }
    }
    NativeDocAllocArm(0); DocDel(failed);
    if(!caught || Fs->data_heap->used_u8s!=fail_before) result=-8-fail;
  }
  truncated=DocNew("C:/BinaryRecordBad.DD",Fs);
  if(result==5 && NativeDocRecordLoadCore(truncated,first,first_size-1)) result=-6;
  Free(second); Free(first); DocDel(truncated); DocDel(loaded); DocDel(doc);
  if(Fs->data_heap->used_u8s!=before) result=-7;
  return result;
}

I64 NativeDocAllocationCoreCheck()
{
  CDoc *doc=NULL;
  U8 *text;
  I64 before=Fs->data_heap->used_u8s,base,size,i,caught=0;
  for(i=1;i<=3;i++) {
    NativeDocAllocArm(i);
    try { doc=DocNew("C:/AllocFail.DD",Fs); }
    catch {
      if(Fs->except_ch=='OutMem') { Fs->catch_except=TRUE; caught++; }
    }
    NativeDocAllocArm(0);
    if(doc) { DocDel(doc); doc=NULL; }
    if(Fs->data_heap->used_u8s!=before) return -i;
  }
  doc=DocNew("C:/AllocFail.DD",Fs);
  base=Fs->data_heap->used_u8s;
  NativeDocAllocArm(1);
  if(!NativeDocAllocationCaught(&NativeDocAllocationPut,doc) ||
      doc->owning_task || Bt(&doc->locked_flags,DOClf_LOCKED) ||
      Fs->data_heap->used_u8s!=base || doc->head.next!=doc) return -4;
  NativeDocAllocArm(2);
  if(!NativeDocAllocationCaught(&NativeDocAllocationPut,doc) ||
      doc->owning_task || Bt(&doc->locked_flags,DOClf_LOCKED) ||
      Fs->data_heap->used_u8s!=base || doc->head.next!=doc) return -5;
  DocPutKey(doc,'a',0);
  doc->cur_entry=doc->head.next; doc->cur_col=1;
  //Fill the owned four-byte tag capacity so the fault probe needs growth.
  DocPutKey(doc,'b'); DocPutKey(doc,'c');
  base=Fs->data_heap->used_u8s;
  NativeDocAllocArm(1);
  if(!NativeDocAllocationCaught(&NativeDocAllocationPut,doc) ||
      doc->owning_task || Bt(&doc->locked_flags,DOClf_LOCKED) ||
      Fs->data_heap->used_u8s!=base || StrCmp(doc->head.next->tag,"abc")) return -6;
  NativeDocAllocArm(1);
  if(!NativeDocAllocationCaught(&NativeDocAllocationNewLine,doc) ||
      doc->owning_task || Bt(&doc->locked_flags,DOClf_LOCKED) ||
      Fs->data_heap->used_u8s!=base || doc->head.next->next!=doc) return -7;
  NativeDocAllocArm(1);
  if(!NativeDocAllocationCaught(&NativeDocAllocationSave,doc) ||
      doc->owning_task || Bt(&doc->locked_flags,DOClf_LOCKED) ||
      Fs->data_heap->used_u8s!=base) return -8;
  DocPutKey(doc,'Z',0); text=DocSave(doc,&size);
  if(!text || size!=5 || text[0]!='a' || text[1]!='b' || text[2]!='c' ||
      text[3]!='Z' || text[4]!=CH_CURSOR) {
    Free(text); DocDel(doc); return -9;
  }
  Free(text); DocDel(doc);
  if(Fs->data_heap->used_u8s!=before) return -10;
  return caught+5;
}

I64 NativeDocDollarGrowthCheck()
{
  CDoc *doc=DocNew("C:/DollarFail.DD",Fs);
  U8 *buffer;
  I64 base,size,position,i,result=-501;
  DocPutKey(doc,36);
  while(doc->dollar_buf_ptr<doc->dollar_buf_size-2) DocPutKey(doc,'R');
  buffer=doc->dollar_buf;size=doc->dollar_buf_size;position=doc->dollar_buf_ptr;
  base=Fs->data_heap->used_u8s;
  NativeDocAllocArm(1);
  if(!NativeDocAllocationCaught(&NativeDocAllocationPut,doc)) goto dollar_done;
  result=-502;
  if(doc->dollar_buf!=buffer || doc->dollar_buf_size!=size ||
      doc->dollar_buf_ptr!=position || !(doc->flags&DOCF_IN_DOLLAR) ||
      doc->head.next!=doc || doc->owning_task ||
      Bt(&doc->locked_flags,DOClf_LOCKED) || Fs->data_heap->used_u8s!=base)
    goto dollar_done;
  result=-503;
  if(buffer[0]!=36) goto dollar_done;
  for(i=1;i<position;i++) if(buffer[i]!='R') goto dollar_done;
  DocPutKey(doc,'X');
  result=-504;
  if(doc->dollar_buf_ptr!=position+1 || doc->dollar_buf_size<=size ||
      doc->dollar_buf[position]!='X' || !(doc->flags&DOCF_IN_DOLLAR) ||
      doc->owning_task || Bt(&doc->locked_flags,DOClf_LOCKED))
    goto dollar_done;
  if(doc->dollar_buf[0]!=36) goto dollar_done;
  for(i=1;i<position;i++) if(doc->dollar_buf[i]!='R') goto dollar_done;
  result=1;
dollar_done:
  NativeDocAllocArm(0);
  DocDel(doc);
  return result;
}

I64 NativeDocClipPasteAtomicCheck()
{//Every allocation failure must preserve exact target bytes and heap ownership.
  CDoc *source=NULL,*target=NULL,*old_clip=native_clip_doc;
  CDocEntry *entry;
  U8 *before=NULL,*after=NULL;
  I64 size,after_size,index,fail,allocations=0,used,result=-1;
  native_clip_doc=NULL;
  source=DocNew("C:/PasteSource.DD",Fs);
  DocPutKey(source,'a'); DocPutKey(source,'b');
  for(entry=source->head.next;entry!=source;entry=entry->next)
    entry->type|=DOCET_SEL;
  if(!NativeDocClipCopy(source,FALSE)) goto paste_check_done;
  target=DocNew("C:/PasteProbe.DD",Fs);
  DocPutKey(target,'x'); DocPutKey(target,'y'); DocPutKey(target,'z');
  target->cur_entry=target->head.next; target->cur_col=1;
  NativeDocAllocArm(I64_MAX);
  if(!NativeDocClipPaste(target)) { NativeDocAllocArm(0); goto paste_check_done; }
  allocations=native_doc_alloc_count; NativeDocAllocArm(0); DocDel(target); target=NULL;
  for(fail=1;fail<=allocations;fail++) {
    //DocSave can change clipboard layout; repeat the baseline input each time.
    if(!NativeDocClipCopy(source,FALSE)) goto paste_check_done;
    target=DocNew("C:/PasteFail.DD",Fs);
    DocPutKey(target,'x'); DocPutKey(target,'y'); DocPutKey(target,'z');
    target->cur_entry=target->head.next; target->cur_col=1;
    before=DocSave(target,&size); used=Fs->data_heap->used_u8s;
    NativeDocAllocArm(fail);
    if(NativeDocClipPaste(target)) {
      NativeDocAllocArm(0); result=-fail; goto paste_check_done;
    }
    if(native_doc_alloc_count!=fail) {
      NativeDocAllocArm(0); result=-allocations*4-fail; goto paste_check_done;
    }
    NativeDocAllocArm(0); after=DocSave(target,&after_size);
    if(!after || after_size!=size) { result=-allocations-fail; goto paste_check_done; }
    for(index=0;index<size;index++) if(before[index]!=after[index]) {
      result=-allocations*2-fail; goto paste_check_done;
    }
    Free(after); after=NULL;
    //Discard any document-owned recalculation changes before checking leaks.
    if(!NativeDocClipCopy(source,FALSE)) goto paste_check_done;
    if(Fs->data_heap->used_u8s!=used) {
      result=-allocations*3-fail; goto paste_check_done;
    }
    Free(before); before=NULL; DocDel(target); target=NULL;
  }
  result=allocations;
paste_check_done:
  NativeDocAllocArm(0); Free(after); Free(before); DocDel(target); DocDel(source);
  DocDel(native_clip_doc); native_clip_doc=old_clip;
  return result;
}

public I64 DocAllocationCheck()
{
  CDoc *doc,*read_doc=NULL;
  U8 *saved;
  I64 before,caught=0,result=NativeDocRecordSaveCheck,size,fail;
  if(result!=4) return result;
  result=NativeDocBinarySaveCheck;
  if(result!=5) return result;
  result=NativeDocAllocationCoreCheck;
  if(result!=8) return result;
  before=Fs->data_heap->used_u8s;
  result=NativeDocDollarGrowthCheck;
  if(result!=1) return result;
  if(Fs->data_heap->used_u8s!=before) return -505;
  saved="DOC DOLLAR GROWTH recovery\n";
  while(*saved) OutU8(0xE9,*saved++);
  result=NativeDocClipPasteAtomicCheck;
  if(result<=0) return result;
  doc=DocNew("C:/AllocRead.DD",Fs);
  DocPutKey(doc,'r',0); DocPutKey(doc,'e',0); DocPutKey(doc,'a',0); DocPutKey(doc,'d',0);
  if(!DocWrite(doc)) { DocDel(doc); return -11; }
  DocDel(doc); before=Fs->data_heap->used_u8s;
  //Three DocNew allocations precede the text base and its tag.
  for(fail=4;fail<=5;fail++) {
    caught=0;
    NativeDocAllocArm(fail);
    try { read_doc=DocRead("C:/AllocRead.DD"); }
    catch {
      if(Fs->except_ch=='OutMem') { Fs->catch_except=TRUE; caught=1; }
    }
    NativeDocAllocArm(0);
    if(read_doc) { DocDel(read_doc); read_doc=NULL; }
    if(!caught || Fs->data_heap->used_u8s!=before) return -100-fail;
  }
  read_doc=DocRead("C:/AllocRead.DD");
  if(read_doc) saved=DocSave(read_doc,&size); else saved=NULL;
  if(!saved || size!=5 || saved[0]!='r' || saved[1]!='e' ||
      saved[2]!='a' || saved[3]!='d' || saved[4]!=CH_CURSOR) {
    Free(saved);
    DocDel(read_doc); return -13;
  }
  Free(saved);
  DocDel(read_doc);
  if(Fs->data_heap->used_u8s!=before) return -14;
  return 13;
}
I64 DocDiagnosticRun(U8 *raw,I64 bytes)
{
  CI386DocDiagnosticContext *context=raw;
  if(!context || bytes!=sizeof(CI386DocDiagnosticContext) ||
      context->version!=I386_DOC_DIAGNOSTIC_VERSION || context->bytes!=bytes)return -1;
  doc_diag_context=context;
  return DocAllocationCheck;
}
I64 Main(CI386DocDiagnosticServices *services,I64 bytes)
{
  if(!services || bytes!=sizeof(CI386DocDiagnosticServices))return 0;
  services->version=I386_DOC_DIAGNOSTIC_VERSION;services->bytes=bytes;
  services->run=&DocDiagnosticRun;
  return 1;
}
