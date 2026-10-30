I64 SettingsContract()
{
  CTaskSettings *first,*second,*old=Fs->next_settings;
  CDoc *doc=DocPut;
  CBGR48 old_color,first_color;
  I64 mask=0,old_attr=Fs->text_attr,old_x=Fs->scroll_x,old_y=Fs->scroll_y;
  I64 old_left=Fs->win_left,old_right=Fs->win_right,old_top=Fs->win_top,old_bottom=Fs->win_bottom;
  U8 *old_dir=DirCur,*new_dir,*old_title=StrNew(Fs->task_title);
  Bool old_hidden=Bt(&doc->flags,DOCf_HIDE_CURSOR);
  old_color=GrPaletteColorGet(1);
  first=SettingsPush;
  if(first && Fs->next_settings==first && first->next==old)mask|=1;
  Fs->text_attr=0x1E;Fs->scroll_x=23;Fs->scroll_y=31;
  StrCpy(Fs->task_title,"first");LBts(&doc->flags,DOCf_HIDE_CURSOR);
  GrPaletteColorSet(1,0xAAAA5555FFFF);first_color=GrPaletteColorGet(1);
  second=SettingsPush;
  if(second && Fs->next_settings==second && second->next==first)mask|=2;
  Fs->text_attr=0x2F;Fs->scroll_x=41;Fs->scroll_y=47;StrCpy(Fs->task_title,"second");
  LBtr(&doc->flags,DOCf_HIDE_CURSOR);GrPaletteColorSet(1,0x1111CCCC7777);
  SettingsPop;
  if(Fs->next_settings==first && Fs->text_attr==0x1E && Fs->scroll_x==23 && Fs->scroll_y==31 && !StrCmp(Fs->task_title,"first") && Bt(&doc->flags,DOCf_HIDE_CURSOR))mask|=4;
  if(GrPaletteColorGet(1)==first_color)mask|=64;
  SettingsPop;
  if(GrPaletteColorGet(1)==old_color)mask|=128;
  if(Fs->next_settings==old && Fs->text_attr==old_attr && Fs->scroll_x==old_x && Fs->scroll_y==old_y && !StrCmp(Fs->task_title,old_title) && Bt(&doc->flags,DOCf_HIDE_CURSOR)==old_hidden)mask|=8;
  if(Fs->win_left==old_left && Fs->win_right==old_right && Fs->win_top==old_top && Fs->win_bottom==old_bottom)mask|=16;
  new_dir=DirCur;
  if(!StrCmp(new_dir,old_dir))mask|=32;
  Free(new_dir);
  Free(old_dir);Free(old_title);
  return mask;
}
