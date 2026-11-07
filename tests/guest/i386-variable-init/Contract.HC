U0 VILog(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 VIValue(U8 *name)
{
  CHashFun *fun=HashFind(name,Fs->hash_table,HTT_FUN);
  if(!fun)return 0;
  return Call(fun->exe_addr);
}
Bool VIBytes(U8 *name,U8 value,I64 size)
{
  CHashGlblVar *global=HashFind(name,Fs->hash_table,HTT_GLBL_VAR);
  I64 i;
  if(!global || global->size!=size)return FALSE;
  for(i=0;i<size;i++)if(global->data_addr[i]!=value)return FALSE;
  return TRUE;
}
U0 VICheck()
{
  U8 old_flag=sys_var_init_flag,old_value=sys_var_init_val,*s;
  I64 mask=0,*r=CAlloc(5*8);CHashGlblVar *global;
  r[1]=old_flag;r[2]=old_value;
  s=MStrPrint("EXPORT variable-init-defaults.bin %X 10\n",r+1);VILog(s);Free(s);
  try {
    sys_var_init_flag=TRUE;sys_var_init_val=0xA5;
    if(sys_var_init_flag && sys_var_init_val==0xA5)mask|=1;
    ExePutS("U8 VIUninitialized[37];");
    if(VIBytes("VIUninitialized",0xA5,37))mask|=2;
    ExePutS("U8 VIInitialized[4]={1,2,3,4};");
    global=HashFind("VIInitialized",Fs->hash_table,HTT_GLBL_VAR);
    if(global && global->data_addr[0]==1 && global->data_addr[1]==2 &&
        global->data_addr[2]==3 && global->data_addr[3]==4)mask|=4;
    ExePutS("I64 VIStatic(){static I64 value;return value;}");
    if(VIValue("VIStatic")==0xA5A5A5A5A5A5A5A5)mask|=8;
    ExePutS("I64 VILocalA5(){I64 noreg value;return value;}");
    if(VIValue("VILocalA5")==0xA5A5A5A5A5A5A5A5)mask|=16;
    ExePutS("I64 VIStackBytes(){U8 noreg value[17];I64 i;for(i=0;i<17;i++)if(value[i]!=0xA5)return 0;return 1;}");
    if(VIValue("VIStackBytes")==1)mask|=32;
    sys_var_init_val=0x3C;
    ExePutS("I64 VILocal3C(){I64 noreg value;return value;}");
    r[3]=VIValue("VILocalA5");r[4]=VIValue("VILocal3C");
    if(r[3]==0xA5A5A5A5A5A5A5A5 && r[4]==0x3C3C3C3C3C3C3C3C &&
        VIValue("VIStatic")==0xA5A5A5A5A5A5A5A5 && VIBytes("VIUninitialized",0xA5,37))mask|=64;
  }catch{Fs->catch_except=TRUE;}
  sys_var_init_flag=old_flag;sys_var_init_val=old_value;
  if(sys_var_init_flag==old_flag && sys_var_init_val==old_value &&
      VIValue("VILocal3C")==0x3C3C3C3C3C3C3C3C)mask|=128;
  r[0]=mask;
  s=MStrPrint("EXPORT variable-init.bin %X 28\n",r);VILog(s);Free(s);
  VILog("VARIABLE INIT DONE\n");Sleep(1000);
}
VICheck;
