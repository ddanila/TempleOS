U0 SettingsRemoteSleeper(U8 *) {while(TRUE)Sleep(20);}
I64 SettingsRemoteContract()
{
  CTask *target=Spawn(&SettingsRemoteSleeper,NULL,"Settings remote",-1,Fs,16384);
  CTaskSettings *first,*second,*old;I64 mask=0,old_attr,old_x,old_y;
  U8 *old_title;
  TaskWait(target);old=target->next_settings;old_attr=target->text_attr;
  old_x=target->scroll_x;old_y=target->scroll_y;old_title=StrNew(target->task_title);
  first=SettingsPush(target);
  if(first && target->next_settings==first && first->next==old)mask|=1;
  target->text_attr=0x1E;target->scroll_x=12;target->scroll_y=13;StrCpy(target->task_title,"remote one");
  second=SettingsPush(target);
  if(second && target->next_settings==second && second->next==first)mask|=2;
  target->text_attr=0x2F;target->scroll_x=22;target->scroll_y=23;StrCpy(target->task_title,"remote two");
  SettingsPop(target);
  if(target->next_settings==first && target->text_attr==0x1E && target->scroll_x==12 && target->scroll_y==13 && !StrCmp(target->task_title,"remote one"))mask|=4;
  SettingsPop(target);
  if(target->next_settings==old && target->text_attr==old_attr && target->scroll_x==old_x && target->scroll_y==old_y && !StrCmp(target->task_title,old_title))mask|=8;
  Free(old_title);Kill(target);
  if(!TaskValidate(target))mask|=16;
  return mask;
}
