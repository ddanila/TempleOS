CTask *bdw_target;
I64 bdw_drive;
U0 BDWSleeper(U8 *) { while(TRUE)Sleep(20); }
U0 BDWReplace(U8 *)
{
  Sleep(40);bdw_target=Spawn(&BDWSleeper,NULL,"Wait replacement",-1,Fs->parent_task,16384);
}
U0 BDWKill(U8 *data)
{
  Sleep(40);Kill(data(CTask *));
}
I64 BirthDeathWaitContract()
{
  CTask *first,*maker,*killer,*user;U8 *name;I64 first_num,second_num,mask=0;
  first=Spawn(&BDWSleeper,NULL,"Wait first",-1,Fs,16384);
  bdw_target=first;first_num=BirthWait(&bdw_target);
  if(first_num==first->task_num && TaskValidate(first))mask|=1;
  maker=Spawn(&BDWReplace,NULL,"Wait maker",-1,Fs,16384);
  second_num=BirthWait(&bdw_target,first_num);
  if(bdw_target!=first && TaskValidate(bdw_target) && second_num==bdw_target->task_num && second_num!=first_num)mask|=2;
  while(TaskValidate(maker))Yield;
  Kill(first);DeathWait(&first);
  if(!TaskValidate(first))mask|=4;
  killer=Spawn(&BDWKill,bdw_target,"Wait killer",-1,Fs,16384);
  DeathWait(&bdw_target);
  if(!TaskValidate(bdw_target))mask|=8;
  while(TaskValidate(killer))Yield;
  user=User;
  if(user && TaskValidate(user)) {
    DeathWait(&user,TRUE);
    if(!TaskValidate(user))mask|=16;
  }
  if(mask==31) {
    name=MStrPrint("%c:/birth-death-wait.OK",bdw_drive);
    FileWrite(name,"complete",8);Free(name);
  }
  return mask;
}
