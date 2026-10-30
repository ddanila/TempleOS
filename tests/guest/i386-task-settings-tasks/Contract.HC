U0 SettingsSleeper(U8 *) { while(TRUE)Sleep(20); }
I64 SettingsTasksContract()
{
  CTask *old_song=Fs->song_task,*old_animation=Fs->animate_task;
  CTask *song,*animation,*new_song,*new_animation,*same_song;
  CTaskSettings *setting;I64 mask=0;
  song=Spawn(&SettingsSleeper,NULL,"Settings song",-1,Fs,16384);
  animation=Spawn(&SettingsSleeper,NULL,"Settings animation",-1,Fs,16384);
  new_song=Spawn(&SettingsSleeper,NULL,"Replacement song",-1,Fs,16384);
  new_animation=Spawn(&SettingsSleeper,NULL,"Replacement animation",-1,Fs,16384);
  same_song=Spawn(&SettingsSleeper,NULL,"Retained song",-1,Fs,16384);
  Fs->song_task=song;Fs->animate_task=animation;
  setting=SettingsPush;
  if(setting && setting->song_task==song && setting->animate_task==animation && !Fs->song_task && !Fs->animate_task)mask|=1;
  if(IsSuspended(song) && IsSuspended(animation))mask|=2;
  Fs->song_task=new_song;Fs->animate_task=new_animation;
  SettingsPop;
  if(Fs->song_task==song && Fs->animate_task==animation && !IsSuspended(song) && !IsSuspended(animation))mask|=4;
  if(!TaskValidate(new_song) && !TaskValidate(new_animation))mask|=8;
  Fs->song_task=same_song;Fs->animate_task=NULL;
  setting=SettingsPush(,TSF_SAME_SONG);
  if(setting && Fs->song_task==same_song && !IsSuspended(same_song))mask|=16;
  SettingsPop(,TSF_SAME_SONG);
  if(Fs->song_task==same_song && TaskValidate(same_song) && !IsSuspended(same_song))mask|=32;
  Fs->song_task=old_song;Fs->animate_task=old_animation;
  Kill(song);Kill(animation);Kill(same_song);
  if(!TaskValidate(song) && !TaskValidate(animation) && !TaskValidate(same_song))mask|=64;
  return mask;
}
