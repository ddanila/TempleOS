I64 *SettingsLifecycleRows()
{
  I64 *rows=CAlloc(5*sizeof(I64)),old_number;
  CTask *active=ac.task;
  CTaskSettings *setting;
  if(!TaskValidate(active))return rows;
  if(TaskValidate(active) && Bt(&sys_run_level,RLf_AUTO_COMPLETE) &&
      !Bt(&ac.flags,ACf_INIT_IN_PROGRESS) && acd.num_words==95293)rows[3]|=1;
  rows[0]=SettingsContract;
  rows[1]=SettingsTasksContract;
  rows[2]=SettingsRemoteContract;
  if(TaskValidate(ac.task) && ac.task==active)rows[3]|=32;
  old_number=-1;
  if(TaskValidate(ac.task))old_number=ac.task->task_num;
  setting=SettingsPush;
  if(setting && setting->autocomplete)rows[3]|=2;
  AutoComplete(OFF);
  SettingsPop;
  if(TaskValidate(ac.task) && ac.task->task_num!=old_number)rows[3]|=4;
  AutoComplete(OFF);
  setting=SettingsPush;
  if(setting && !setting->autocomplete)rows[3]|=8;
  AutoComplete(ON);
  SettingsPop;
  if(!TaskValidate(ac.task))rows[3]|=16;
  rows[4]=acd.num_words;
  return rows;
}
