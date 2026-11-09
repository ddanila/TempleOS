#include "/Kernel/I386/PublicAssembly.HH"
#include "/Kernel/I386/PublicDebug.HH"
#include "/Kernel/I386/PublicTextBase.HH"
#include "/Kernel/I386/PublicCompilerContext.HH"
#include "/Kernel/I386/PublicTask.HH"
#include "/Kernel/I386/PublicWindow.HH"
#include "/Compiler/I386/AOTReleaseCore.HC"
U0 BELog(U8 *text){while(*text)OutU8(0xE9,*text++);}
U0 BEWorker(U8 *data)
{
  I64 *rows=data,*r,i,used,code,errors,warnings;U8 *source,*text;
  CBootHeap *global=rows[105],*other=rows[106];I64 *b;
  CAOT *aot;CCmpCtrl *first,*last;CDoc *doc,*old_doc;
  for(i=0;i<10;i++) {
    if(i==0)source="public I64 OperandA(){asm {MOV EAX,MISSING+} return 1;}";
    else if(i==1)source="public I64 OperandB(){asm {MOV CR0,MISSING} return 1;}";
    else if(i==2)source="public I64 OperandC(){asm {MOV EAX,[MISSING+]} return 1;}";
    else if(i==3)source="asm {ALIGN UNKNOWN_ALIGN,0;}";
    else if(i==4)source="asm {ORG UNKNOWN_ORG;}";
    else if(i==5)source="asm {DU8 2 DUP(UNKNOWN_DUP);}";
    else if(i==6)source="asm {DU32 UNKNOWN_DATA+;}";
    else if(i==7)source="asm {DU32 UNKNOWN_DATA DUP(1);}";
    else if(i==8)source="public I64 OperandD(){asm {MOV EAX,[EAX+MISSING} return 1;}";
    else source="public I64 OperandE(){asm {MOV EAX,1+} return 1;}";
    BELog("BE CASE ");OutU8(0xE9,'0'+i);OutU8(0xE9,'\n');
    b=rows+107+i*8;b[0]=global->used;b[1]=global->allocations;
    if(other){b[2]=other->used;b[3]=other->allocations;}
    r=rows+i*8;used=Fs->data_heap->used_u8s;code=Fs->code_heap->used_u8s;
    first=Fs->next_cc;last=Fs->last_cc;old_doc=Fs->put_doc;doc=DocNew;Fs->put_doc=doc;text=StrNew(source);
    errors=warnings=-1;aot=CmpBuf(text,NULL,&errors,&warnings);rows[83+i]=errors;
    rows[187+i]=dbg.fix_file_line && dbg.fix_file_line[0]=='F' && dbg.fix_file_line[1]=='L' && dbg.fix_file_line[2]==':';
    r[0]=!aot;r[1]=errors>0;r[2]=warnings==0;r[3]=!StrCmp(text,source);
    r[4]=Fs->next_cc==first && Fs->last_cc==last;
    I386AOTDel(aot);Free(text);Fs->put_doc=old_doc;DocDel(doc);
    r[5]=Fs->data_heap->used_u8s-used;r[6]=Fs->code_heap->used_u8s-code;
    b[4]=global->used;b[5]=global->allocations;
    if(other){b[6]=other->used;b[7]=other->allocations;}
    aot=CmpBuf("6*7;");r[7]=aot!=NULL;I386AOTDel(aot);
  }
  rows[103]=Fs->data_heap->used_u8s;rows[104]=Fs->code_heap->used_u8s;
  rows[80]=1;while(TRUE)Yield;
}
U0 BECheck()
{
  I64 *rows=CAlloc(217*8),used,allocations,other_used=0,other_allocations=0,i,raw_col=text.raw_col,raw_flags=text.raw_flags;
  CBootBacking *backing=Fs->data_heap->bp;CBootHeap *heap=backing->heap,*fallback=backing->fallback;
  CHeapCtrl *diagnostic_heap;
  CTask *child;U8 *line,*old_fix=dbg.fix_file_line;CAOT *aot=CmpBuf("6*7;");I386AOTDel(aot);
  dbg.fix_file_line=NULL;
  rows[216]=text.raw_scrn_image;
  rows[202]=heap->used;rows[203]=heap->allocations;
  if(fallback){rows[204]=fallback->used;rows[205]=fallback->allocations;}
  //Warm the kernel raw-screen cache and diagnostic allocator, not a failing compiler call.
  //A second cycle must leave the same raw backing state as the first.
  for(i=0;i<2;i++) {
    RawPutChar(0);text.raw_col=raw_col;text.raw_flags=raw_flags;
    FixSet("~/Tmp.DD.Z",1);diagnostic_heap=MHeapCtrl(dbg.fix_file_line);
    Free(dbg.fix_file_line);dbg.fix_file_line=NULL;
    if(!i) {
      rows[206]=heap->used;rows[207]=heap->allocations;
      if(fallback){rows[208]=fallback->used;rows[209]=fallback->allocations;}
    }
  }
  rows[214]=text.raw_scrn_image;
  used=heap->used;allocations=heap->allocations;
  if(fallback){other_used=fallback->used;other_allocations=fallback->allocations;}
  rows[93]=used;rows[94]=allocations;rows[95]=other_used;rows[96]=other_allocations;
  rows[197]=IsSingleUser();rows[210]=diagnostic_heap;rows[211]=diagnostic_heap->used_u8s;
  rows[105]=heap;rows[106]=fallback;
  child=Spawn(&BEWorker,rows,"Failed buffer owner",-1,Fs);while(!rows[80])Yield;
  rows[81]=Kill(child) && !TaskValidate(child);
  rows[97]=heap->used;rows[98]=heap->allocations;
  if(fallback){rows[99]=fallback->used;rows[100]=fallback->allocations;}
  //FixSet publishes an Adam-owned diagnostic. Restore that separately from
  //the task's compiler ownership, preserving the original global pointer.
  Free(dbg.fix_file_line);dbg.fix_file_line=old_fix;
  rows[215]=text.raw_scrn_image && text.raw_scrn_image==rows[214];
  rows[212]=diagnostic_heap->used_u8s;
  rows[213]=rows[212]==rows[211] && dbg.fix_file_line==old_fix;
  rows[198]=heap->used;rows[199]=heap->allocations;
  if(fallback){rows[200]=fallback->used;rows[201]=fallback->allocations;}
  rows[101]=I386HeapValid(heap);rows[102]=!fallback || I386HeapValid(fallback);
  rows[82]=heap->used==used && heap->allocations==allocations && rows[101] &&
    (!fallback || fallback->used==other_used && fallback->allocations==other_allocations && rows[102]);
  line=MStrPrint("EXPORT buffer-errors.bin %X 6C8\n",rows);BELog(line);Free(line);
  BELog("PUBLIC BUFFER ERRORS DONE\n");Sleep(1000);
}BECheck;
