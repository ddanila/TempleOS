I64 reset_hook_value;U8 *reset_hook_path;Bool reset_hook_throw;
U0 ProgressBarsRegTf(U8 *path)
{reset_hook_value=progress1;reset_hook_path=path;if(reset_hook_throw)throw('Hook',TRUE);}
I64 ProgressHookContract()
{
  CProgress saved[4];I64 mask=0;U8 *path="ProgressProbe";
  MemCpy(saved,sys_progresses,sizeof(saved));
  progress1=42;reset_hook_value=0;reset_hook_path=0;
  ProgressBarsRst(path);
  if(reset_hook_value==42 && reset_hook_path==path)mask|=1;
  if(progress1==0)mask|=2;
  reset_hook_throw=TRUE;progress1=77;
  try {ProgressBarsRst(path);} catch {
    if(Fs->except_ch=='Hook' && progress1==77)mask|=4;
    Fs->catch_except=TRUE;
  }
  reset_hook_throw=FALSE;MemCpy(sys_progresses,saved,sizeof(saved));return mask;
}
