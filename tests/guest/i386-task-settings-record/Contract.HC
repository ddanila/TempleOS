I64 settings_record_drive;
I64 SettingsRecordContract()
{
  CTaskSettings a;U8 *text,*name,*check;I64 size,mask=0;
  MemSet(&a,0,sizeof(a));a.left=11;a.right=22;a.scroll_x=-31;a.scroll_y=43;
  a.text_attr=0x1E;a.border=TRUE;a.hide_cursor=TRUE;a.palette[3]=0x123456789ABC;
  StrCpy(a.task_title,"Settings record");
  if(a.left==11 && a.right==22 && a.scroll_x==-31 && a.scroll_y==43)mask|=1;
  if(a.text_attr==0x1E && a.border && a.hide_cursor && a.palette[3]==0x123456789ABC && !StrCmp(a.task_title,"Settings record"))mask|=2;
  text=MStrPrint("%d %d %d %d %d %d %d %d %d %d\n",sizeof(CTaskSettings),offset(CTaskSettings.cur_dir),offset(CTaskSettings.left),offset(CTaskSettings.draw_it),offset(CTaskSettings.song_task),offset(CTaskSettings.scroll_x),offset(CTaskSettings.palette),offset(CTaskSettings.win_inhibit),offset(CTaskSettings.task_title),offset(CTaskSettings.border));
  name=MStrPrint("%c:/settings-layout.TXT",settings_record_drive);FileWrite(name,text,StrLen(text));
  check=FileRead(name,&size);
  if(check && size==StrLen(text) && !MemCmp(check,text,size))mask|=4;
  Free(text);Free(name);Free(check);return mask;
}
