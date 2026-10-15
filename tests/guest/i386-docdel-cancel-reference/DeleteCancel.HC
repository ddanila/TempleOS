CDoc *ca_doc;
CTask *ca_owner,*ca_deleter;
Bool ca_ready,ca_unlock,ca_unlocked,ca_caught,ca_alive,ca_release,ca_returned,ca_roles;
I64 ca_before;
U0 CAAbort(){throw('DDStop',TRUE);}
U0 CAOwner(U8 *data)
{
  ca_doc=DocNew("Cancel.DD");DocLock(ca_doc);ca_ready=TRUE;
  while(!ca_unlock)Yield;
  DocUnlock(ca_doc);ca_unlocked=TRUE;while(TRUE)Yield;
}
U0 CADelete(U8 *data)
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
  ca_before=Fs->data_heap->used_u8s;Fs->task_end_cb=&CAAbort;
  try{DocDel(ca_doc);ca_returned=TRUE;}
  catch{if(Fs->except_ch=='DDStop'){ca_caught=TRUE;Fs->catch_except=TRUE;}}
  ca_roles=DocPut==put&&DocDisplay==display&&DocBorder==border;
  ca_alive=TRUE;while(!ca_release)Yield;
}
Bool CAChildLinked(CTask *target)
{
  CTask *self=Fs,*node=self->next_child_task;
  CTask *head=(&self->next_child_task)(U8 *)-offset(CTask.next_sibling_task);
  while(node!=head){if(node==target)return TRUE;node=node->next_sibling_task;}
  return FALSE;
}
I64 CAContract()
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
  CTask *old_child=Fs->next_child_task;
  I64 m=0,i;
  Bool retried=FALSE;
  ca_doc=NULL;ca_ready=ca_unlock=ca_unlocked=ca_caught=ca_alive=ca_release=ca_returned=ca_roles=FALSE;
  ca_owner=Spawn(&CAOwner,NULL,"Cancel owner",-1,Fs);
  while(!ca_ready)Yield;
  ca_deleter=Spawn(&CADelete,NULL,"Cancel deleter",-1,Fs);
  //The deleter yields while waiting for the owner's lock.
  for(i=0;i<32;i++)Yield;
  Kill(ca_deleter,TRUE,FALSE);
  while(TaskValidate(ca_deleter)&&!ca_alive)Yield;
  if(ca_caught&&!ca_returned&&ca_alive&&TaskValidate(ca_deleter))m|=1;
  if(TaskValidate(ca_deleter)&&ca_deleter->data_heap->used_u8s==ca_before)m|=2;
  if(ca_roles)m|=4;
  if(ca_doc->doc_signature==DOC_SIGNATURE_VAL&&ca_doc->owning_task==ca_owner&&
      Bt(&ca_doc->locked_flags,DOClf_LOCKED))m|=8;
  ca_unlock=TRUE;while(!ca_unlocked)Yield;
  try{DocDel(ca_doc);retried=TRUE;}
  catch{Fs->catch_except=TRUE;}
  if(retried)m|=16;
  Kill(ca_owner,TRUE,FALSE);
  for(i=0;i<200&&CAChildLinked(ca_owner);i++)Sleep(5);
  if(!CAChildLinked(ca_owner)&&TaskValidate(ca_deleter)&&ca_alive)m|=64;
  ca_release=TRUE;
  for(i=0;i<200&&(CAChildLinked(ca_owner)||CAChildLinked(ca_deleter));i++)Sleep(5);
  if(!CAChildLinked(ca_owner)&&!CAChildLinked(ca_deleter)&&Fs->next_child_task==old_child)m|=128;
  if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=32;
  return m;
}
I64 CACheck(){I64 m=CAContract;if(m!=255)throw('DelCncl',TRUE);return m;}
