#include "/Kernel/I386/PublicCompilerContext.HH"
#include "/Kernel/I386/PublicTask.HH"
#include "/Kernel/I386/PublicWindow.HH"
U0 DBLog(U8 *text){while(*text)OutU8(0xE9,*text++);}
U0 DBWorker(U8 *data)
{
  I64 *rows=data,*r,i,used,code,flags,caught;CCmpCtrl *cc,*first,*last;
  CDoc *doc,*old_doc;CDocEntry *entry;
  for(i=0;i<10;i++) {
    r=rows+i*5;used=Fs->data_heap->used_u8s;code=Fs->code_heap->used_u8s;
    first=Fs->next_cc;last=Fs->last_cc;cc=CmpCtrlNew;flags=cc->flags;
    QueIns(cc,Fs->last_cc);old_doc=Fs->put_doc;doc=DocNew;Fs->put_doc=doc;
    entry=NULL;caught=0;
    try {
      if(i==0)entry=PrsDollarCmd(doc,"FG,RED");
      else if(i==1)entry=PrsDollarCmd(doc,"FG,(");
      else if(i==2)entry=PrsDollarCmd(doc,"BT,\"bad\",LE=1+");
      else if(i==3)entry=PrsDollarCmd(doc,"BT,\"bad\",LE");
      else if(i==4)entry=PrsDollarCmd(doc,"BT,\"bad\",A=\"aux\",D=\"def\",HTML=\"web\",LM=\"left\",RM=\"right\",LE=7");
      else if(i==5)entry=PrsDollarCmd(doc,"BT,\"bad\",A=\"aux\",D=\"def\",HTML=\"web\",LM=\"left\",RM=\"right\",LE=1+");
      else if(i==6)entry=PrsDollarCmd(doc,"BT,\"bad\",A=\"aux\",D=\"def\",HTML=\"web\",LM=\"left\",RM=\"right\",LE");
      else if(i==7)entry=PrsDollarCmd(doc,"UNKNOWN_DOC_COMMAND");
      else if(i==8)entry=PrsDollarCmd(doc,"BT,\"bad\",BI=1,LE=1+");
      else entry=PrsDollarCmd(doc,"BT,\"bad\",BI=1,LE");
    }catch{caught=Fs->except_ch;Fs->catch_except=TRUE;}
    if(i==0)r[0]=!caught && entry && entry->type_u8==DOCT_FOREGROUND && entry->attr==RED;
    else if(i==4)r[0]=!caught && entry && entry->type_u8==DOCT_BTTN && entry->left_exp==7 &&
      !StrCmp(entry->tag,"bad") && !StrCmp(entry->aux_str,"aux") && !StrCmp(entry->define_str,"def") &&
      !StrCmp(entry->html_link,"web") && !StrCmp(entry->left_macro,"left") && !StrCmp(entry->right_macro,"right");
    else r[0]=!caught && entry && entry->type_u8==DOCT_ERROR && !entry->de_flags && !entry->tag;
    if(entry){rows[53+i*3]=entry->type_u8;rows[54+i*3]=entry->de_flags;rows[55+i*3]=entry->tag!=NULL;}
    r[1]=Fs->last_cc==cc && cc->flags==flags && !cc->error_cnt && !cc->warning_cnt;
    if(entry){QueInit(entry);DocEntryDel(doc,entry);}
    Fs->put_doc=old_doc;DocDel(doc);QueRem(cc);CmpCtrlDel(cc);
    r[2]=Fs->next_cc==first && Fs->last_cc==last;
    r[3]=Fs->data_heap->used_u8s-used;r[4]=Fs->code_heap->used_u8s-code;
  }
  rows[50]=1;while(TRUE)Yield;
}
U0 DBCheck()
{
  I64 *rows=CAlloc(83*8),used,allocations,other_used=0,other_allocations=0;
  CBootBacking *backing=Fs->data_heap->bp;CBootHeap *heap=backing->heap,*fallback=backing->fallback;
  CTask *child;U8 *text;
  used=heap->used;allocations=heap->allocations;
  if(fallback){other_used=fallback->used;other_allocations=fallback->allocations;}
  child=Spawn(&DBWorker,rows,"Public DolDoc boundary",-1,Fs);
  while(!rows[50])Yield;
  rows[51]=Kill(child) && !TaskValidate(child);
  rows[52]=heap->used==used && heap->allocations==allocations && I386HeapValid(heap) &&
    (!fallback || fallback->used==other_used && fallback->allocations==other_allocations && I386HeapValid(fallback));
  text=MStrPrint("EXPORT doc-boundary.bin %X 1A8\n",rows);DBLog(text);Free(text);
  text=MStrPrint("EXPORT doc-boundary-detail.bin %X F0\n",rows+53);DBLog(text);Free(text);
  DBLog("DOC PUBLIC BOUNDARY DONE\n");Sleep(1000);
}DBCheck;
