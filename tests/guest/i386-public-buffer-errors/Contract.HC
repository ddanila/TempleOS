#include "/Kernel/I386/PublicAssembly.HH"
#include "/Kernel/I386/PublicCompilerContext.HH"
#include "/Kernel/I386/PublicTask.HH"
#include "/Kernel/I386/PublicWindow.HH"
#include "/Compiler/I386/AOTReleaseCore.HC"
U0 BELog(U8 *text){while(*text)OutU8(0xE9,*text++);}
U0 BEWorker(U8 *data)
{
  I64 *rows=data,*r,i,used,code,errors,warnings;U8 *source,*text;
  CAOT *aot;CCmpCtrl *first,*last;CDoc *doc,*old_doc;
  for(i=0;i<5;i++) {
    if(i==0)source="1+;";
    else if(i==1)source="6*7;1+;";
    else if(i==2)source="public I64 ErrFun(I64 a){return a+1;}1+;";
    else if(i==3)source="public U8 ErrData[4]=\"abc\";1+;";
    else source="import I64 ErrImport(I64 x);ErrImport(1);1+;";
    r=rows+i*8;used=Fs->data_heap->used_u8s;code=Fs->code_heap->used_u8s;
    first=Fs->next_cc;last=Fs->last_cc;old_doc=Fs->put_doc;doc=DocNew;Fs->put_doc=doc;text=StrNew(source);
    errors=warnings=-1;aot=CmpBuf(text,NULL,&errors,&warnings);rows[43+i]=errors;
    r[0]=!aot;r[1]=errors>0;r[2]=warnings==0;r[3]=!StrCmp(text,source);
    r[4]=Fs->next_cc==first && Fs->last_cc==last;
    I386AOTDel(aot);Free(text);Fs->put_doc=old_doc;DocDel(doc);
    r[5]=Fs->data_heap->used_u8s-used;r[6]=Fs->code_heap->used_u8s-code;
    aot=CmpBuf("6*7;");r[7]=aot!=NULL;I386AOTDel(aot);
  }
  rows[40]=1;while(TRUE)Yield;
}
U0 BECheck()
{
  I64 *rows=CAlloc(48*8),used,allocations,other_used=0,other_allocations=0;
  CBootBacking *backing=Fs->data_heap->bp;CBootHeap *heap=backing->heap,*fallback=backing->fallback;
  CTask *child;U8 *text;CAOT *aot=CmpBuf("6*7;");I386AOTDel(aot);
  used=heap->used;allocations=heap->allocations;
  if(fallback){other_used=fallback->used;other_allocations=fallback->allocations;}
  child=Spawn(&BEWorker,rows,"Failed buffer owner",-1,Fs);while(!rows[40])Yield;
  rows[41]=Kill(child) && !TaskValidate(child);
  rows[42]=heap->used==used && heap->allocations==allocations && I386HeapValid(heap) &&
    (!fallback || fallback->used==other_used && fallback->allocations==other_allocations && I386HeapValid(fallback));
  text=MStrPrint("EXPORT buffer-errors.bin %X 180\n",rows);BELog(text);Free(text);
  BELog("PUBLIC BUFFER ERRORS DONE\n");Sleep(1000);
}BECheck;
