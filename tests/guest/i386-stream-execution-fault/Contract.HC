U0 SLLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U8 *sl_saved=NULL;I64 sl_fault_code;Bool sl_after_fault=FALSE;I64 *sl_results,*sl_negative;Bool sl_runtime=FALSE,sl_nested=FALSE;
U0 SLCheck()
{
  I64 *r=CAlloc(13*8),i,size,n=StrLen("stream-execution-fault-owner-0123456789")+1;
  U8 *s,*saved,*churn;U8 *(*fun)();CHashFun *f;CCmpCtrl *old=Fs->last_cc;
  sl_results=r;
  while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
  U8 *source="#exe{{sl_saved=(\"stream-execution-fault-owner-0123456789\")(U8 *);throw('Compiler');sl_after_fault=TRUE;}}";
  if(sl_runtime)source="{{sl_saved=(\"stream-execution-fault-owner-0123456789\")(U8 *);throw('Compiler');sl_after_fault=TRUE;}}";
  if(sl_nested)source="#exe{StreamPrint(\"I64 SLEmittedBeforeFault=1;\");#exe{{sl_saved=(\"stream-execution-fault-owner-0123456789\")(U8 *);throw('Compiler');sl_after_fault=TRUE;}}}";
  CDoc *put=DocPut,*doc=DocNew;U8 *diagnostic;
  Fs->put_doc=doc;r[0]=ExePutS(source)==0 && !sl_after_fault;sl_fault_code=Fs->except_ch;
  s=MStrPrint("EXPORT stream-execution-fault-code.bin %X 8\n",&sl_fault_code);SLLog(s);Free(s);
  diagnostic=DocSave(doc,&size);Fs->put_doc=put;DocDel(doc);
  s=MStrPrint("EXPORT stream-execution-fault-error.DD %X %X\n",diagnostic,size);SLLog(s);Free(s);
  saved=sl_saved;r[1]=saved && Fs->answer!=saved;
  r[2]=saved && !MemCmp(saved,"stream-execution-fault-owner-0123456789",n);
  for(i=0;i<32;i++)ExePutS("123;");
  r[3]=saved && !MemCmp(saved,"stream-execution-fault-owner-0123456789",n);
  churn=MAlloc(32768);MemSet(churn,0xA5,32768);Free(churn);
  churn=MAlloc(32768,Fs->code_heap);MemSet(churn,0x5A,32768);Free(churn);
  r[4]=saved && !MemCmp(saved,"stream-execution-fault-owner-0123456789",n);
  r[5]=sl_saved==saved;r[6]=Fs->last_cc==old;
  ExePutS("#exe{StreamPrint(\"U8 *SLOwnedFunction(){return sl_saved;}\");}");
  f=HashFind("SLOwnedFunction",Fs->hash_table,HTT_FUN);fun=NULL;if(f)fun=f->exe_addr;
  r[7]=fun && (*fun)()==saved;
  r[8]=saved && !MemCmp(saved,"stream-execution-fault-owner-0123456789",n);
  r[9]=sizeof(I64)==8 && Fs->last_cc==old;
  SLLog("SL FAULT CHECK DONE\n");
}
U0 SLNoLiteral()
{
  I64 i,before;CDoc *put=DocPut,*doc;
  sl_negative=CAlloc(2*8);
  doc=DocNew;Fs->put_doc=doc;
  for(i=0;i<8;i++)ExePutS("throw('Compiler');");
  Fs->put_doc=put;DocDel(doc);
  before=Fs->code_heap->used_u8s;sl_negative[0]=before;
  doc=DocNew;Fs->put_doc=doc;
  for(i=0;i<32;i++)ExePutS("throw('Compiler');");
  Fs->put_doc=put;DocDel(doc);
  sl_negative[1]=Fs->code_heap->used_u8s;
  SLLog("SL NO LITERAL DONE\n");
}
U0 SLAfter()
{
  I64 *r=sl_results,i,size,n=StrLen("stream-execution-fault-owner-0123456789")+1;
  U8 *s,*chunks[256];
  r[10]=sl_saved && !MemCmp(sl_saved,"stream-execution-fault-owner-0123456789",n);
  for(i=0;i<256;i++){size=32<<(i%8);chunks[i]=MAlloc(size,Fs->code_heap);MemSet(chunks[i],0xA5,size);}
  r[11]=sl_saved && !MemCmp(sl_saved,"stream-execution-fault-owner-0123456789",n);
  for(i=0;i<256;i++)Free(chunks[i]);
  r[12]=HashFind("SLEmittedBeforeFault",Fs->hash_table,HTT_GLBL_VAR|HTT_FUN)==NULL;
  s=MStrPrint("EXPORT stream-execution-fault-negative.bin %X 10\n",sl_negative);SLLog(s);Free(s);
  s=MStrPrint("EXPORT stream-execution-fault.bin %X 68\n",r);SLLog(s);Free(s);
  if(sl_saved){s=MStrPrint("EXPORT stream-execution-fault.txt %X %X\n",sl_saved,n);SLLog(s);Free(s);}
  SLLog("STREAM EXECUTION FAULT DONE\n");Sleep(1000);
}
