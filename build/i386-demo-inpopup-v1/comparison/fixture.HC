
U0 DemoBatchLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 DemoBatchRun(U8 *path,U8 *name,I64 seed=0)
{
  CDoc *put=DocPut,*doc=DocNew;
  I64 size,previous_seed=Fs->rand_seed;
  U8 *data,*line;
  Bool raw=Raw(OFF),previous_fixed=Bt(&Fs->task_flags,TASKf_NONTIMER_RAND);
  if(seed)Seed(seed);
  Fs->put_doc=doc;
  ExeFile(path);
  if(seed) {
    Fs->rand_seed=previous_seed;
    if(previous_fixed)LBts(&Fs->task_flags,TASKf_NONTIMER_RAND);
    else LBtr(&Fs->task_flags,TASKf_NONTIMER_RAND);
  }
  if(Fs->put_doc!=doc)throw('Batch',TRUE);
  Fs->put_doc=put;
  data=DocSave(doc,&size);
  line=MStrPrint("EXPORT %s %X %X\n",name,data,size);
  DemoBatchLog(line);
  Sleep(1000);
  Free(line);Free(data);DocDel(doc);Raw(raw);
}
DemoBatchRun("::/Demo/InFile/InPopUp.HC","demo-0.DD",0);
DemoBatchLog("DEMO BATCH DONE\n");
