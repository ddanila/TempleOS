U0 ZILog(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 zi_values[4];
U0 ZIProbe()
{
  U8 flag=sys_var_init_flag,value=sys_var_init_val,*line;
  zi_values[0]=-1;zi_values[1]=flag;zi_values[2]=value;zi_values[3]=0;
  try {
    sys_var_init_flag=TRUE;sys_var_init_val=0xA5;
    zi_values[0]=I386BuildModule("C:/Probe/ZeroModule.HC","C:/Probe/ZeroModule.t32m",TRUE);
  } catch {Fs->catch_except=TRUE;}
  sys_var_init_flag=flag;sys_var_init_val=value;
  zi_values[3]=sys_var_init_flag==flag&&sys_var_init_val==value;
  line=MStrPrint("EXPORT module-zero-values.bin %X %X\n",zi_values,sizeof(zi_values));ZILog(line);Free(line);
  ZILog("MODULE ZERO DONE\n");
}
