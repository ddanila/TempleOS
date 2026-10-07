#include "/Kernel/I386/ModuleStageCore.HC"
CI386ModuleStage st_stage;
U8 st_disk[65],st_source[65],st_output[65];
I64 st_writes,st_flushes,st_reads,st_releases,st_fail,st_mode,st_checks;
Bool st_flush_fail,st_read_fail,st_release_fail;
U0 STAssert(Bool ok){st_checks++;if(!ok)throw('Stage',TRUE);}
I64 STWrite(U8 *context,U32 offset,U8 *buffer,U32 bytes)
{
  no_warn context;
  st_writes++;
  if(st_writes==st_fail){if(st_mode==2)throw('Write',TRUE);if(st_mode)return -1;return bytes-1;}
  MemCpy(st_disk+offset,buffer,bytes);return bytes;
}
Bool STFlush(U8 *context){no_warn context;st_flushes++;return !st_flush_fail;}
I64 STRead(U8 *context,U8 *buffer,I64 bytes)
{no_warn context;st_reads++;if(st_read_fail)return bytes-1;MemCpy(buffer,st_disk,bytes);return bytes;}
Bool STRelease(U8 *context){no_warn context;st_releases++;return !st_release_fail;}
U0 STReset()
{
  MemSet(&st_stage,0,sizeof(CI386ModuleStage));
  MemSet(st_disk,0xA7,65);MemSet(st_output,0xA7,65);
  st_writes=st_flushes=st_reads=st_releases=st_fail=st_mode=0;
  st_flush_fail=st_read_fail=st_release_fail=FALSE;
}
Bool STInit(I64 bytes=65)
{return I386ModuleStageInit(&st_stage,bytes,0,&STWrite,&STFlush,&STRead,&STRelease);}
U0 STFill(I64 chunk)
{
  I64 offset=0,n;
  while(offset<65){n=65-offset;if(n>chunk)n=chunk;
    STAssert(I386ModuleStageWrite(&st_stage,offset,st_source+offset,n)==n);offset+=n;}
}
U0 STContract()
{
  I64 i,j,k,chunk;Bool caught;
  st_checks=0;
  for(i=0;i<65;i++)st_source[i]=i*17+3;
  for(j=0;j<6;j++) {
    chunk=1;if(j==1)chunk=3;if(j==2)chunk=17;if(j==3)chunk=31;if(j==4)chunk=512;if(j==5)chunk=4096;
    STReset();STAssert(STInit);STFill(chunk);
    STAssert(I386ModuleStageSeal(&st_stage) && st_flushes==1);
    STAssert(!I386ModuleStageRead(&st_stage,st_output,65) && !st_reads);
    STAssert(I386ModuleStageUnwound(&st_stage,TRUE));
    STAssert(I386ModuleStageRead(&st_stage,st_output,65) && !MemCmp(st_output,st_source,65));
    STAssert(!I386ModuleStageRead(&st_stage,st_output,65) && st_reads==1);
    STAssert(I386ModuleStageRelease(&st_stage) && !st_stage.owned && st_releases==1);
    STAssert(I386ModuleStageRelease(&st_stage) && st_releases==1);
  }
  for(j=0;j<3;j++)for(k=1;k<=4;k++) {
    STReset();STAssert(STInit);st_fail=k;st_mode=j;caught=FALSE;
    try {for(i=0;i<65;i+=17)if(!I386ModuleStageWrite(&st_stage,i,st_source+i,MinI64(17,65-i)))break;}
    catch {if(j==2 && Fs->except_ch=='Write'){Fs->catch_except=TRUE;caught=TRUE;}}
    STAssert((j==2)==caught && st_writes==k && st_stage.owned);
    STAssert(!I386ModuleStageSeal(&st_stage) && !st_flushes);
    STAssert(!I386ModuleStageRead(&st_stage,st_output,65) && !st_reads);
    STAssert(I386ModuleStageRelease(&st_stage) && st_releases==1);
  }
  STReset();STAssert(!STInit(31) && !st_stage.owned);
  STAssert(!STInit(4194305) && !st_stage.owned);
  STAssert(!I386ModuleStageInit(0,65,0,&STWrite,&STFlush,&STRead,&STRelease));
  STAssert(!I386ModuleStageInit(&st_stage,65,0,0,&STFlush,&STRead,&STRelease));
  STAssert(!I386ModuleStageInit(&st_stage,65,0,&STWrite,0,&STRead,&STRelease));
  STAssert(!I386ModuleStageInit(&st_stage,65,0,&STWrite,&STFlush,0,&STRelease));
  STAssert(!I386ModuleStageInit(&st_stage,65,0,&STWrite,&STFlush,&STRead,0));
  STAssert(STInit && !STInit && !st_writes);
  STAssert(!I386ModuleStageWrite(&st_stage,1,st_source,1) && !st_writes);
  STAssert(!I386ModuleStageWrite(&st_stage,0,st_source,0) && !st_writes);
  STAssert(!I386ModuleStageWrite(&st_stage,0,0,1) && !st_writes);
  STAssert(!I386ModuleStageWrite(&st_stage,0,st_source,66) && !st_writes);
  STAssert(!I386ModuleStageSeal(&st_stage) && !st_flushes);
  STAssert(!I386ModuleStageUnwound(&st_stage,TRUE));
  STAssert(!I386ModuleStageRead(&st_stage,st_output,65) && !st_reads);
  STAssert(I386ModuleStageRelease(&st_stage));
  STReset();STAssert(STInit(8192));
  STAssert(!I386ModuleStageWrite(&st_stage,0,st_source,4097) && !st_writes);
  STAssert(I386ModuleStageRelease(&st_stage));
  STReset();STAssert(STInit);STFill(17);st_flush_fail=TRUE;
  STAssert(!I386ModuleStageSeal(&st_stage) && st_stage.owned && st_flushes==1);
  STAssert(!I386ModuleStageUnwound(&st_stage,TRUE));STAssert(I386ModuleStageRelease(&st_stage));
  STReset();STAssert(STInit);STFill(17);STAssert(I386ModuleStageSeal(&st_stage));
  STAssert(!I386ModuleStageUnwound(&st_stage,FALSE) && st_stage.owned);
  STAssert(!I386ModuleStageRead(&st_stage,st_output,65) && !st_reads);
  STAssert(I386ModuleStageRelease(&st_stage));
  STReset();STAssert(STInit);STFill(17);STAssert(I386ModuleStageSeal(&st_stage));
  STAssert(I386ModuleStageUnwound(&st_stage,TRUE));
  STAssert(!I386ModuleStageRead(&st_stage,st_output,64) && !st_reads);
  STAssert(!I386ModuleStageRead(&st_stage,st_output,66) && !st_reads);
  st_read_fail=TRUE;STAssert(!I386ModuleStageRead(&st_stage,st_output,65) && st_reads==1 && st_stage.owned);
  st_release_fail=TRUE;STAssert(!I386ModuleStageRelease(&st_stage) && st_stage.owned && st_releases==1);
  st_release_fail=FALSE;STAssert(I386ModuleStageRelease(&st_stage) && !st_stage.owned && st_releases==2);
  STAssert(I386ModuleStageRelease(&st_stage) && st_releases==2);
}
U0 STReport(U8 *text){while(*text)OutU8(0xE9,*text++);}
U0 STRun()
{
  Bool passed=FALSE;
  U8 *line;
  try {STContract;passed=st_checks==253;}
  catch {Fs->catch_except=TRUE;}
  if(passed)line=MStrPrint("DONE module-stage %d checks\n",st_checks);
  else line=MStrPrint("FAIL module-stage %d checks\n",st_checks);
  STReport(line);Free(line);
}
STRun;
