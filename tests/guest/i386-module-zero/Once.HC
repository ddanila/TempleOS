while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
U0 ZILog(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 zi_values[4];
U0 ZIReference()
{
  U8 flag=sys_var_init_flag,value=sys_var_init_val,*source,*module=NULL,*line;
  I64 size=0,errors=0;
  zi_values[0]=-1;zi_values[1]=flag;zi_values[2]=value;zi_values[3]=0;
  source=FileRead("T:/Module.HC");
  try {
    sys_var_init_flag=TRUE;sys_var_init_val=0xA5;
    module=CmpI386Module(source,&size,&errors);
    if(module&&!errors)zi_values[0]=size;
  } catch {Fs->catch_except=TRUE;}
  sys_var_init_flag=flag;sys_var_init_val=value;Free(source);
  zi_values[3]=sys_var_init_flag==flag&&sys_var_init_val==value;
  if(module) {
    line=MStrPrint("EXPORT module-zero.t32m %X %X\n",module,size);ZILog(line);Free(line);
  }
  line=MStrPrint("EXPORT module-zero-values.bin %X %X\n",zi_values,sizeof(zi_values));ZILog(line);Free(line);
  ZILog("DONE module zero\n");
}
ZIReference;
