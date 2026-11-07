#ifndef RAWDR_REG_COUNT
#define RAWDR_REG_COUNT 16
#define RAWDR_REG_NAMES "ST_U64_REGS"
#define RAWDR_HEX_WIDTH 16
#define RAWDR_IP_NAME "RIP"
#define RAWDR_CODE_BITS 64
#endif
#define RAWDR_COL	40

U0 RawDr(CTask *task=NULL)
{
  I64 i,j,old_col=text.raw_col;
  Bool old_raw=Raw(ON);
  U8 buf[200];

  if (!task) task=Fs;

  for (i=0;i<RAWDR_REG_COUNT;i++) {
    text.raw_col=i*text.cols+RAWDR_COL;
    "º%3Z:%0*X\n",i,RAWDR_REG_NAMES,RAWDR_HEX_WIDTH,*TaskRegAddr(task,i);
  }

  text.raw_col=i++*text.cols+RAWDR_COL;
  "º%s:%0*X\n",RAWDR_IP_NAME,RAWDR_HEX_WIDTH,task->rip;

  text.raw_col=i++*text.cols+RAWDR_COL;
  "º%-*tp\n",text.cols-(RAWDR_COL+1)-1,Fs->rip;

  text.raw_col=i++*text.cols+RAWDR_COL;
  'º';
  if (Bt(&sys_run_level,RLf_COMPILER)) {
    j=Fs->rip;
    Ui(buf,&j,RAWDR_CODE_BITS,,TRUE);
    "%s",buf;
  } else
    '\n';

  text.raw_col=i*text.cols+RAWDR_COL;
  'È';
  for (j=0;j<text.cols-RAWDR_COL-1;j++)
    'Í';

  text.raw_col=old_col;
  Raw(old_raw);
}

