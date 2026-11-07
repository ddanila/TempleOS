U0 SLLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U8 *sl_saved;I64 *sl_results;
U0 SLCheck()
{
  I64 *r=CAlloc(12*8),i,size,n=StrLen("stream-literal-owner-0123456789")+1;
  U8 *s,*saved,*churn;U8 *(*fun)();CHashFun *f;CCmpCtrl *old=Fs->last_cc;
  sl_results=r;
  while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
  r[0]=ExePutS("#exe{sl_saved=(\"stream-literal-owner-0123456789\")(U8 *);}")==0;
  saved=sl_saved;r[1]=saved && Fs->answer==saved;
  r[2]=saved && !MemCmp(saved,"stream-literal-owner-0123456789",n);
  for(i=0;i<32;i++)ExePutS("123;");
  r[3]=saved && !MemCmp(saved,"stream-literal-owner-0123456789",n);
  churn=MAlloc(32768);MemSet(churn,0xA5,32768);Free(churn);
  churn=MAlloc(32768,Fs->code_heap);MemSet(churn,0x5A,32768);Free(churn);
  r[4]=saved && !MemCmp(saved,"stream-literal-owner-0123456789",n);
  r[5]=sl_saved==saved;r[6]=Fs->last_cc==old;
  ExePutS("#exe{StreamPrint(\"U8 *SLOwnedFunction(){return sl_saved;}\");}");
  f=HashFind("SLOwnedFunction",Fs->hash_table,HTT_FUN);fun=NULL;if(f)fun=f->exe_addr;
  r[7]=fun && (*fun)()==saved;
  r[8]=saved && !MemCmp(saved,"stream-literal-owner-0123456789",n);
  r[9]=sizeof(I64)==8 && Fs->last_cc==old;
}
U0 SLAfter()
{
  I64 *r=sl_results,i,size,n=StrLen("stream-literal-owner-0123456789")+1;
  U8 *s,*chunks[256];
  r[10]=sl_saved && !MemCmp(sl_saved,"stream-literal-owner-0123456789",n);
  for(i=0;i<256;i++){size=32<<(i%8);chunks[i]=MAlloc(size,Fs->code_heap);MemSet(chunks[i],0xA5,size);}
  r[11]=sl_saved && !MemCmp(sl_saved,"stream-literal-owner-0123456789",n);
  for(i=0;i<256;i++)Free(chunks[i]);
  s=MStrPrint("EXPORT stream-literal.bin %X 60\n",r);SLLog(s);Free(s);
  if(sl_saved){s=MStrPrint("EXPORT stream-literal.txt %X %X\n",sl_saved,n);SLLog(s);Free(s);}
  SLLog("STREAM LITERAL DONE\n");Sleep(1000);
}
