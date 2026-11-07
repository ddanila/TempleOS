U0 SDLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 sd_case,sd_count,sd_used;Bool sd_ok,sd_controls=TRUE,sd_cwd=TRUE;
U8 *sd_wants[3],*sd_temporary,sd_text[8192];
U0 SDCapture(U8 *value=NULL)
{
  U8 *text;I64 length;
  if(sd_count>=3)sd_ok=FALSE;
  else if(value){if(!sd_wants[sd_count] || StrCmp(value,sd_wants[sd_count]))sd_ok=FALSE;}
  else if(sd_wants[sd_count])sd_ok=FALSE;
  sd_text[sd_used++]=sd_case/10+'0';sd_text[sd_used++]=sd_case%10+'0';sd_text[sd_used++]=':';
  sd_text[sd_used++]=sd_count+'0';sd_text[sd_used++]=':';
  text=value;if(!text)text="<NULL>";length=StrLen(text);
  if(sd_used+length+1>8192){SDLog("FAIL StreamDir output capacity\n");throw;}
  MemCpy(sd_text+sd_used,text,length);sd_used+=length;sd_text[sd_used++]='\n';sd_count++;
}
U8 *SDPath(U8 *path)
{
  if(!path)return NULL;
  if(!StrCmp(path,"@temp"))return StrNew(sd_temporary);
  if(*path=='@')return StrNew(path+1);
  return MStrPrint("%C:%s",Drv2Let,path);
}
U0 SDCase(I64 *r,I64 index,U8 *filename,U8 *source,U8 *want,Bool file=FALSE)
{
  U8 *name=SDPath(filename),*old=DirCur,*title=StrNew(Fs->task_title),*now;
  I64 title_src=Fs->title_src;CCmpCtrl *cc=Fs->last_cc;
  sd_case=index;sd_count=0;sd_ok=TRUE;sd_wants[0]=SDPath(want);
  SDLog("SD CASE ");if(name)SDLog(name);else SDLog("<default>");SDLog("\n");
  if(file){sd_wants[1]=SDPath("/SDTree/A/B");sd_wants[2]=SDPath("/SDTree/A");ExeFile(name);}
  else ExePutS(source,name);
  if(Fs->last_cc!=cc || Fs->title_src!=title_src || StrCmp(title,Fs->task_title))sd_controls=FALSE;
  if(file)r[index]=sd_ok && sd_count==3;else r[index]=sd_ok && sd_count==1;
  if(!Cd(old))sd_cwd=FALSE;now=DirCur;if(StrCmp(now,old))sd_cwd=FALSE;Free(now);
  Free(sd_wants[0]);if(file){Free(sd_wants[1]);Free(sd_wants[2]);}
  Free(name);Free(old);Free(title);
}
U0 SDCheck()
{
  I64 *r=CAlloc(14*8);U8 *s,*old=DirCur,*old_tmp=StrNew(blkdev.tmp_filename);
  while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
  if(StrLen(old_tmp)<StrLen("Temp/T.HC")){SDLog("FAIL temporary filename capacity\n");throw;}
  StrCpy(blkdev.tmp_filename,"Temp/T.HC");sd_used=0;
  if(!Cd("/SDTree/A")){SDLog("FAIL StreamDir fixture cwd\n");throw;}
  sd_temporary=DirNameAbs("Temp");
  SDCase(r,0,"/SDTree/A/B/marker.HC","SDCapture(#exe{StreamDir;});","/SDTree/A/B");
  SDCase(r,1,"/SDTree/A/B","SDCapture(#exe{StreamDir;});","/SDTree/A/B");
  SDCase(r,2,"/SDTree/A/B/Missing/Sub/Virtual.HC","SDCapture(#exe{StreamDir;});","/SDTree/A/B");
  SDCase(r,3,"/StreamDirVirtual.HC","SDCapture(#exe{StreamDir;});",NULL);
  SDCase(r,4,"/","SDCapture(#exe{StreamDir;});","/");
  SDCase(r,5,"@Relative.HC","SDCapture(#exe{StreamDir;});","/SDTree/A");
  SDCase(r,6,NULL,"SDCapture(#exe{StreamDir;});","@temp");
  SDCase(r,7,"/SDTree/A/B/Missing/Sub/Virtual.HC","SDCapture(__DIR__);","/SDTree/A/B");
  SDCase(r,8,"/SDTree/A/B/Missing/Sub/Virtual.HC","#define SD_ALIAS_A __DIR__\nSDCapture(SD_ALIAS_A);","/SDTree/A/B");
  SDCase(r,9,"/SDTree/A/B/Missing/Sub/Virtual.HC","#define SD_ALIAS_B #exe{StreamDir;}+0\nSDCapture(SD_ALIAS_B);","@temp");
  SDCase(r,10,"/SDTree/A/B/Missing/Sub/Virtual.HC","Cd(\"/SDTree/A/B\");SDCapture(#exe{StreamDir;});","/SDTree/A/B");
  SDCase(r,11,"/SDTree/A/Outer.HC",NULL,"/SDTree/A",TRUE);
  if(!Cd(old))sd_cwd=FALSE;Free(old);
  r[12]=sd_controls;r[13]=sd_cwd && sizeof(I64)==8;StrCpy(blkdev.tmp_filename,old_tmp);Free(old_tmp);Free(sd_temporary);
  s=MStrPrint("EXPORT stream-directory.bin %X 70\n",r);SDLog(s);Free(s);
  s=MStrPrint("EXPORT stream-directory-paths.txt %X %X\n",sd_text,sd_used);SDLog(s);Free(s);
  SDLog("STREAM DIRECTORY DONE\n");Sleep(1000);
}
SDCheck;
