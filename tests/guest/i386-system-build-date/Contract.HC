U0 BDLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 bd_values[12];U8 *bd_text;
U0 BDProbe()
{
  CDateStruct ds;U8 *s;
  bd_values[0]=sys_compile_time;bd_values[1]=&sys_compile_time;
  bd_values[2]=Now;Sleep(1100);bd_values[3]=Now;
  bd_values[4]=sys_compile_time;Date2Struct(&ds,sys_compile_time);
  bd_values[5]=Struct2Date(&ds);
  bd_values[6]=ds.year;bd_values[7]=ds.mon;bd_values[8]=ds.day_of_mon;
  bd_values[9]=ds.hour;bd_values[10]=ds.min;bd_values[11]=ds.sec;
  s=bd_text=MStrPrint("%D %T",sys_compile_time,sys_compile_time);
  U8 *line=MStrPrint("EXPORT build-date.txt %X %X\n",s,StrLen(s));BDLog(line);Free(line);
  line=MStrPrint("EXPORT build-date.bin %X %X\n",bd_values,sizeof(bd_values));BDLog(line);Free(line);
  BDLog("BUILD DATE DONE\n");
}
U0 BDHomeLoad()
{
  if(Adam("ExeFile(\"::/HomeSys.HC\",CCF_JUST_LOAD);")!=1)throw('HomeLoad',TRUE);
  BDLog("HOME LOAD DONE\n");
}
