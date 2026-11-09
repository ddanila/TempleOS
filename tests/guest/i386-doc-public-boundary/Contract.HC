#include "/Kernel/I386/PublicCompilerContext.HH"
#include "/Kernel/I386/PublicTask.HH"
#include "/Kernel/I386/PublicWindow.HH"
U0 DBLog(U8 *text){while(*text)OutU8(0xE9,*text++);}
U0 DBWorker(U8 *data)
{
  I64 *rows=data,*r,i,used,code,flags,caught;CCmpCtrl *cc,*first,*last;
  CDoc *doc,*old_doc;CDocEntry *entry;
  for(i=0;i<3;i++) {
    r=rows+i*5;used=Fs->data_heap->used_u8s;code=Fs->code_heap->used_u8s;
    first=Fs->next_cc;last=Fs->last_cc;cc=CmpCtrlNew;flags=cc->flags;
    QueIns(cc,Fs->last_cc);old_doc=Fs->put_doc;doc=DocNew;Fs->put_doc=doc;
    entry=NULL;caught=0;
    try {
      if(i==0)entry=PrsDollarCmd(doc,"FG,RED");
      else if(i==1)entry=PrsDollarCmd(doc,"FG,(");
      else entry=PrsDollarCmd(doc,"BT,\"bad\",LE=1+");
    }catch{caught=Fs->except_ch;Fs->catch_except=TRUE;}
    if(i==0)r[0]=!caught && entry && entry->type_u8==DOCT_FOREGROUND && entry->attr==RED;
    else r[0]=!caught && entry && entry->type_u8==DOCT_ERROR;
    if(entry){rows[18+i*3]=entry->type_u8;rows[19+i*3]=entry->de_flags;rows[20+i*3]=entry->tag!=NULL;}
    r[1]=Fs->last_cc==cc && cc->flags==flags && !cc->error_cnt && !cc->warning_cnt;
    if(entry){QueInit(entry);DocEntryDel(doc,entry);}
    Fs->put_doc=old_doc;DocDel(doc);QueRem(cc);CmpCtrlDel(cc);
    r[2]=Fs->next_cc==first && Fs->last_cc==last;
    r[3]=Fs->data_heap->used_u8s-used;r[4]=Fs->code_heap->used_u8s-code;
  }
  rows[15]=1;while(TRUE)Yield;
}
U0 DBCheck()
{
  I64 *rows=CAlloc(27*8),used,allocations,other_used=0,other_allocations=0;
  CBootBacking *backing=Fs->data_heap->bp;CBootHeap *heap=backing->heap,*fallback=backing->fallback;
  CTask *child;U8 *text;
  used=heap->used;allocations=heap->allocations;
  if(fallback){other_used=fallback->used;other_allocations=fallback->allocations;}
  child=Spawn(&DBWorker,rows,"Public DolDoc boundary",-1,Fs);
  while(!rows[15])Yield;
  rows[16]=Kill(child) && !TaskValidate(child);
  rows[17]=heap->used==used && heap->allocations==allocations && I386HeapValid(heap) &&
    (!fallback || fallback->used==other_used && fallback->allocations==other_allocations && I386HeapValid(fallback));
  text=MStrPrint("EXPORT doc-boundary.bin %X 90\n",rows);DBLog(text);Free(text);
  text=MStrPrint("EXPORT doc-boundary-detail.bin %X 48\n",rows+18);DBLog(text);Free(text);
  DBLog("DOC PUBLIC BOUNDARY DONE\n");Sleep(1000);
}DBCheck;
