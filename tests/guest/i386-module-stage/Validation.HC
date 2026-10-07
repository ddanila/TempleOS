#include "/Kernel/I386/ModuleCheck.HC"
#include "/Kernel/I386/ModuleStageCheck.HC"
CI386ModuleStage sv_unit;
U8 sv_disk[7056],sv_metadata[6000];
I64 sv_checks,sv_reads,sv_fail;
Bool sv_fail_phase;
U0 SVAssert(Bool value){sv_checks++;if(!value)throw('Stage',TRUE);}
I64 SVRead(CI386ModuleStage *unit,U32 offset,U8 *buffer,U32 bytes)
{
  if(!unit->owned || unit->phase!=I386_STAGE_READY || !bytes || bytes>4096 ||
      offset>unit->bytes || bytes>unit->bytes-offset)return 0;
  sv_reads++;
  if(sv_reads==sv_fail){if(sv_fail_phase)unit->phase=I386_STAGE_FAILED;return 0;}
  MemCpy(buffer,sv_disk+offset,bytes);return bytes;
}
U0 SVReset()
{
  CI386ModuleHeader *h=sv_disk;
  CI386ModuleRecord *r=sv_disk+1056;
  MemSet(sv_disk,0,7056);MemSet(&sv_unit,0,sizeof(CI386ModuleStage));
  h->magic=I386_MODULE_MAGIC;h->version=2;h->cpu=3;h->pointer_size=4;
  h->abi=1;h->total_size=1100;h->code_size=1024;
  h->records_offset=1056;h->record_count=2;h->strings_offset=1088;
  r[0].kind=1;r[0].name_offset=1088;r[0].name_length=1;
  r[1].kind=2;r[1].offset=478;r[1].name_offset=1090;r[1].name_length=1;
  sv_disk[32+477]=0xE8;sv_disk[1088]='F';sv_disk[1090]='G';
  sv_unit.bytes=1100;sv_unit.owned=TRUE;sv_unit.phase=I386_STAGE_READY;
  sv_unit.read_range=&SVRead;sv_reads=sv_fail=0;sv_fail_phase=TRUE;
}
Bool SVValid(I64 capacity=44)
{return I386ModuleStageValid(&sv_unit,sv_metadata,capacity,&I386ModuleValidParts);}
U0 SVContract()
{
  CI386ModuleHeader h,*disk=sv_disk;
  I64 i;
  sv_checks=0;
  SVReset;SVAssert(I386ModuleStageMetadataSize(&sv_unit,&h)==44 && sv_reads==1);
  SVReset;SVAssert(I386ModuleValid(sv_disk,1100) && SVValid && sv_reads==4);
  SVAssert(sv_unit.owned && sv_unit.phase==I386_STAGE_READY);
  SVReset;SVAssert(!SVValid(43) && sv_reads==1);
  for(i=1;i<=4;i++) {
    SVReset;sv_fail=i;if(i==4)sv_fail_phase=FALSE;
    SVAssert(!SVValid && sv_reads==i);
    if(i==4)SVAssert(sv_unit.owned && sv_unit.phase==I386_STAGE_READY);
    else SVAssert(sv_unit.owned && sv_unit.phase==I386_STAGE_FAILED);
  }
  for(i=0;i<12;i++) {
    SVReset;
    if(i==0)disk->magic=0;if(i==1)disk->version=5;
    if(i==2)disk->cpu=4;if(i==3)disk->pointer_size=8;
    if(i==4)disk->abi=2;if(i==5)disk->total_size=1099;
    if(i==6)disk->code_size=0;if(i==7)disk->code_size=1023;
    if(i==8)disk->code_size=0xFFFFFFF8;if(i==9)disk->records_offset=0;
    if(i==10)disk->record_count=0xFFFFFFFF;if(i==11)disk->strings_offset=0;
    SVAssert(I386ModuleStageMetadataSize(&sv_unit,&h)<0 && sv_reads==1);
    SVAssert(!SVValid && sv_reads==2);
  }
  SVReset;sv_disk[32+477]=0;SVAssert(!SVValid);
  SVReset;sv_disk[32+478]=1;SVAssert(!SVValid);
  SVReset;sv_disk[1089]=1;SVAssert(!SVValid);
  SVReset;sv_unit.owned=FALSE;SVAssert(!SVValid && !sv_reads);
  SVReset;sv_unit.phase=I386_STAGE_SEALED;SVAssert(!SVValid && !sv_reads);
  SVReset;sv_unit.read_range=0;SVAssert(!SVValid && !sv_reads);
  SVReset;SVAssert(!I386ModuleStageValid(&sv_unit,0,44,&I386ModuleValidParts));
  SVReset;SVAssert(!I386ModuleStageValid(&sv_unit,sv_metadata,44,0));
  SVReset;sv_unit.bytes=disk->total_size=7056;
  SVAssert(I386ModuleStageMetadataSize(&sv_unit,&h)==6000);
  sv_reads=0;SVAssert(SVValid(6000) && sv_reads==5);
}
U0 SVReport(U8 *line){while(*line)OutU8(0xE9,*line++);}
U0 SVRun()
{
  Bool passed=FALSE;U8 *line;
  try {SVContract;passed=sv_checks==46;}
  catch {Fs->catch_except=TRUE;}
  if(passed)line=MStrPrint("DONE stage-validation %d checks\n",sv_checks);
  else line=MStrPrint("FAIL stage-validation %d checks\n",sv_checks);
  SVReport(line);Free(line);
}
SVRun;
