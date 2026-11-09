#include "/Kernel/I386/PublicAssembly.HH"
#include "/Kernel/I386/PublicCompilerContext.HH"
#include "/Kernel/I386/PublicFiles.HH"
#include "/Kernel/I386/PublicTask.HH"
#include "/Kernel/I386/PublicWindow.HH"
#include "/Compiler/I386/AOTReleaseCore.HC"
U0 BCLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 BCExternal(I64 value){return value+9;}
U8 *bc_code;I64 *bc_rows,*bc_sizes,*bc_entries,*bc_meta;
I64 BCExecute(CAOT *aot,I64 entry)
{
  CHashTable *old=Fs->hash_table,*table=HashTableNew(32);
  CCmpCtrl *cc=CmpCtrlNew(NULL,CCF_TARGET_I386);U8 *code=aot->buf;I64 value;
  table->next=old;Fs->hash_table=table;
  CmpFixUpJITAsm(cc,aot);
  CmpCtrlDel(cc);value=Call(code+entry);
  Fs->hash_table=old;HashTableDel(table);Free(code);return value;
}
U0 BCCase(I64 index,U8 *source,I64 expected,U8 *map_name=NULL)
{
  I64 *r=bc_rows+index*10,used=Fs->data_heap->used_u8s,code_used=Fs->code_heap->used_u8s;
  I64 errors=-1,warnings=-1,count=0,mains=0,entry=-1,mask=0;
  U8 *text=NULL,*s,*failure_doc;I64 failure_size;Bool failed=FALSE;CAOT *aot;CAOTImportExport *ie;
  CCmpCtrl *first=Fs->next_cc,*last=Fs->last_cc;
  CDoc *old_doc=Fs->put_doc,*doc=DocNew;
  Fs->put_doc=doc;if(source)text=StrNew(source);
  BCLog("BUFFER CASE ");if(source)BCLog(source);else BCLog("<NULL>");BCLog("\n");
  try {aot=CmpBuf(text,map_name,&errors,&warnings,'D');}
  catch {failed=TRUE;Fs->catch_except=TRUE;}
  if(failed) {
    failure_doc=DocSave(doc,&failure_size);
    s=MStrPrint("EXPORT buffer-failure-doc.bin %X %X\n",failure_doc,failure_size);BCLog(s);Free(s);
    Sleep(1000);throw('Compiler');
  }
  r[0]=aot!=NULL;r[1]=errors;r[2]=warnings;r[3]=first==Fs->next_cc && last==Fs->last_cc;
  if(source)r[4]=!StrCmp(source,text);else r[4]=!text;
  if(aot) {
    for(ie=aot->next_ie;ie!=&aot->next_ie;ie=ie->next) {
      if(count<32){bc_meta[index*128+count*4]=ie->type;bc_meta[index*128+count*4+1]=ie->rip;bc_meta[index*128+count*4+2]=ie->flags;}
      count++;
      if(ie->type==IET_MAIN){mains++;entry=ie->rip;mask|=1;}
      else if(ie->type==IET_REL32_EXPORT || ie->type==IET_IMM32_EXPORT)mask|=2;
      else if(ie->type==IET_REL_I32 || ie->type==IET_IMM_U32)mask|=4;
      else if(ie->type==IET_I386_DATA)mask|=8;
      else mask|=64;
    }
    if(aot->abss)mask|=16;if(aot->heap_glbls)mask|=32;
    bc_meta[index*128+127]=count;
    bc_sizes[index]=aot->aot_U8s;bc_entries[index]=entry;
    r[5]=mains;r[6]=mask;
    if(aot->aot_U8s<=4096 && count<=31 && !(mask&96)) {
      if(aot->aot_U8s)MemCpy(bc_code+index*4096,aot->buf,aot->aot_U8s);
      s=MStrPrint("EXPORT buffer-packet-%d.bin %X %X\n",index,bc_code+index*4096,aot->aot_U8s);if(aot->aot_U8s)BCLog(s);Free(s);
      s=MStrPrint("BUFFER ENTRY %d %d %d\n",index,entry,mask);BCLog(s);Free(s);
      if(mains==1 && 0<=entry<aot->aot_U8s)r[7]=BCExecute(aot,entry);
      else {r[7]=0;I386AOTDel(aot);}
    } else {r[7]=-99;I386AOTDel(aot);}
  }
  if(r[7]!=expected)BCLog("BUFFER VALUE differs\n");
  Free(text);Fs->put_doc=old_doc;DocDel(doc);
  r[8]=Fs->data_heap->used_u8s-used;r[9]=Fs->code_heap->used_u8s-code_used;
  s=MStrPrint("BUFFER ROW %d %d %d %d %d %d\n",index,r[1],r[2],r[7],r[8],r[9]);BCLog(s);Free(s);
}
Bool bc_child_done=FALSE;
U0 BCStreamChild(U8 *data)
{
  try {BCCase(6,"#exe{StreamPrint(\"6*7;\");}",42);}
  catch {Fs->catch_except=TRUE;BCLog("STREAM CHILD failed\n");}
  *data=TRUE;while(TRUE)Yield;
}
U0 BCStreamLifetime(I64 *summary)
{
  CBootBacking *backing=Fs->data_heap->bp;
  CBootHeap *heap=backing->heap,*fallback=backing->fallback;
  I64 used=heap->used,allocations=heap->allocations,other_used=0,other_allocations=0;
  CTask *child;U8 *text;
  if(fallback){other_used=fallback->used;other_allocations=fallback->allocations;}
  bc_child_done=FALSE;child=Spawn(&BCStreamChild,&bc_child_done,"CmpBuf literal owner",-1,Fs);
  while(!bc_child_done)Yield;
  summary[6]=TaskValidate(child) && bc_rows[68]>0 && bc_rows[69]>0;
  summary[7]=Kill(child) && !TaskValidate(child);
  summary[8]=heap->used==used && heap->allocations==allocations && I386HeapValid(heap) &&
    (!fallback || fallback->used==other_used && fallback->allocations==other_allocations && I386HeapValid(fallback));
  text=MStrPrint("STREAM LIFETIME %d %d %d\n",summary[6],summary[7],summary[8]);BCLog(text);Free(text);
  text=MStrPrint("EXPORT buffer-stream-lifetime.bin %X 18\n",summary+6);BCLog(text);Free(text);
}
U0 BCCheck()
{
  I64 *summary=CAlloc(9*8);U8 *s;CAOT *aot;CHashTable *original_hash=Fs->hash_table;
  bc_rows=CAlloc(140*8);bc_sizes=CAlloc(14*8);bc_entries=CAlloc(14*8);bc_meta=CAlloc(14*128*8);bc_code=CAlloc(14*4096);
  summary[0]=!native_jit_support.buffer && !native_jit_support.assembly && !native_jit_support.asm_stage;
  BCCase(0,"6*7;",42);
  BCCase(1,"0x123456789ABCDEF;",0x123456789ABCDEF);
  BCCase(2,"{3;6*7;}",42);
  BCCase(3,"public I64 BCFun(I64 a){return a*3+5;}BCFun(7);",26);
  BCCase(4,"public I64 BCDefault(I64 a,I64 b=5){return a*3+b;}BCDefault(7);",26);
  BCCase(5,"public U8 BCData[4]=\"abc\";public I64 BCRead(){return BCData[1];}BCRead;",98);
  BCStreamLifetime(summary);
  BCCase(7,"public I64 BCLoop(I64 n){I64 noreg i,total=0;for(i=0;i<n;i++)total+=i;return total;}BCLoop(10);",45);
  BCCase(8,"import I64 BCExternal(I64 value);BCExternal(7);",16);
  BCCase(9,"public I64 BCMap(I64 value){return value+2;}BCMap(40);",42,"C:/Probe/Buffer.MAP");
  BCCase(10,"",0);BCCase(11,NULL,0);BCCase(12,";",0);
  BCCase(13,"public U8 *BCText(){return \"abc\";}BCText()[1];",98);
  aot=CmpBuf("6*7;");summary[1]=aot!=NULL;if(aot)I386AOTDel(aot);
  summary[2]=native_jit_support.buffer && native_jit_support.assembly && native_jit_support.join && native_jit_support.asm_stage==4;
  CCmpCtrl *cc=CmpCtrlNew(StrNew("6*7"));Lex(cc);summary[3]=LexExpressionI64(cc);CmpCtrlDel(cc);
  summary[4]=Fs->hash_table==original_hash;
  cc=CmpCtrlNew;summary[5]=(cc->flags&CCF_TARGET_I386)!=0;CmpCtrlDel(cc);
  s=MStrPrint("EXPORT buffer-summary.bin %X 48\n",summary);BCLog(s);Free(s);
  s=MStrPrint("EXPORT buffer-records.bin %X 460\n",bc_rows);BCLog(s);Free(s);
  s=MStrPrint("EXPORT buffer-sizes.bin %X 70\n",bc_sizes);BCLog(s);Free(s);
  s=MStrPrint("EXPORT buffer-entries.bin %X 70\n",bc_entries);BCLog(s);Free(s);
  s=MStrPrint("EXPORT buffer-metadata.bin %X 3800\n",bc_meta);BCLog(s);Free(s);
  s=MStrPrint("EXPORT buffer-code.bin %X E000\n",bc_code);BCLog(s);Free(s);
  BCLog("PUBLIC BUFFER DONE\n");Sleep(1000);
}
BCCheck;
