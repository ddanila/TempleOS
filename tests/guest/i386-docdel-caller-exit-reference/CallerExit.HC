CTask *ce_owner,*ce_deleter;
CDoc *ce_doc;
Bool ce_ready,ce_started,ce_returned;
U0 CEOwner(U8 *data)
{ce_doc=DocNew("CallerExit.DD");DocLock(ce_doc);ce_ready=TRUE;while(TRUE)Yield;}
U0 CEDelete(U8 *data)
{
  ce_owner=Spawn(&CEOwner,NULL,"Retained child",-1,Fs);
  LBtr(&ce_owner->display_flags,DISPLAYf_SHOW);
  while(!ce_ready)Yield;
  ce_started=TRUE;DocDel(ce_doc);ce_returned=TRUE;
}
Bool CEChildLinked(CTask *target)
{
  CTask *self=Fs,*node=self->next_child_task;
  CTask *head=(&self->next_child_task)(U8 *)-offset(CTask.next_sibling_task);
  while(node!=head){if(node==target)return TRUE;node=node->next_sibling_task;}
  return FALSE;
}
I64 CEContract()
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
  CTask *old_child=Fs->next_child_task;
  I64 i,m=0;
  ce_owner=ce_deleter=NULL;ce_doc=NULL;ce_ready=ce_started=ce_returned=FALSE;
  ce_deleter=Spawn(&CEDelete,NULL,"Exiting deleter",-1,Fs);
  LBtr(&ce_deleter->display_flags,DISPLAYf_SHOW);
  while(!ce_started&&TaskValidate(ce_deleter))Yield;
  for(i=0;i<32;i++)Yield;
  if(ce_started&&TaskValidate(ce_deleter))m|=1;
  if(Kill(ce_deleter,FALSE,FALSE))m|=2;
  for(i=0;i<200&&TaskValidate(ce_deleter);i++)Sleep(5);
  if(!TaskValidate(ce_deleter))m|=4;
  if(!TaskValidate(ce_owner))m|=8;
  if(!ce_returned)m|=16;
  for(i=0;i<200&&(CEChildLinked(ce_deleter)||CEChildLinked(ce_owner));i++)Sleep(5);
  if(!CEChildLinked(ce_deleter)&&!CEChildLinked(ce_owner)&&Fs->next_child_task==old_child)m|=32;
  if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=64;
  //Never read the retired child's document or try to restart an exiting caller.
  return m;
}
U0 CEReport(I64 m)
{U8 *s=MStrPrint("OBS caller-exit mask %d\n",m),*p=s;while(*p)OutU8(0xE9,*p++);Free(s);}
I64 CECheck(){I64 m=CEContract;CEReport(m);if(m!=127)throw('CallExit',TRUE);return m;}
