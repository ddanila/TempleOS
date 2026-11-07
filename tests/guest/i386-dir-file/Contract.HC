U0 DFLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U8 *df_text;I64 df_used,df_deltas[21];
U8 *DFPath(U8 *path)
{
  if(!path)return NULL;
  if(*path=='@')return StrNew(path+1);
  return MStrPrint("%C:%s",Drv2Let,path);
}
U0 DFCase(I64 *r,I64 index,U8 *path,U8 *name,U8 *extension,U8 *expected)
{
  U8 *input=DFPath(path),*want=DFPath(expected),*saved=NULL,*result,*text;
  I64 used,length;
  if(input)saved=StrNew(input);
  DFLog("DF CASE ");if(path)DFLog(path);else DFLog("<current>");DFLog("\n");
  used=Fs->data_heap->used_u8s;
  result=DirFile(input,name,extension);
  r[index*2]=result && want && !StrCmp(result,want) && (!input || !StrCmp(input,saved));
  df_text[df_used++]=index/10+'0';df_text[df_used++]=index%10+'0';df_text[df_used++]=':';
  text=result;if(!text)text="<NULL>";length=StrLen(text);
  if(df_used+length+1>8192){DFLog("FAIL DirFile output capacity\n");throw;}
  MemCpy(df_text+df_used,text,length);df_used+=length;df_text[df_used++]='\n';
  Free(result);df_deltas[index]=Fs->data_heap->used_u8s-used;r[index*2+1]=!df_deltas[index];
  Free(input);Free(want);Free(saved);
}
U0 DFCheck()
{
  I64 *r=CAlloc(44*8),used,i;Bool ok=TRUE;U8 *s,*old=DirCur,*base=DFPath("/DirFileProbe/A/B/C"),*want=DFPath("/DirFileProbe/A/B/C/absent.X"),*parent=DFPath("/DirFileProbe/A/B/up.HC"),*result,*now;
  df_used=0;df_text=MAlloc(8192);
  if(!Cd(base)){DFLog("FAIL DirFile fixture directory\n");throw;}
  DFCase(r,0,"/DirFileProbe/A/B/C/anchor.HC",NULL,NULL,"/DirFileProbe/A/B/C");
  DFCase(r,1,"/DirFileProbe/A/B/C","near","HC","/DirFileProbe/A/B/C/near.HC");
  DFCase(r,2,"/DirFileProbe/A/B/C","near",".HC","/DirFileProbe/A/B/C/near.HC");
  DFCase(r,3,"/DirFileProbe/A/B/C","up","HC","/DirFileProbe/A/B/up.HC");
  DFCase(r,4,"/DirFileProbe/A/B/C","top","HC","/DirFileProbe/A/top.HC");
  DFCase(r,5,"/DirFileProbe/A/B/C",NULL,"PRJ.Z","/DirFileProbe/A/A.PRJ.Z");
  DFCase(r,6,"/DirFileProbe/A/B/C","absent","X","/DirFileProbe/A/B/C/absent.X");
  DFCase(r,7,"/DirFileProbe/A/B/C","plain",NULL,"/DirFileProbe/A/B/C/plain");
  DFCase(r,8,"/DirFileProbe/A/B/C",NULL,"","/DirFileProbe/A/B/C");
  DFCase(r,9,"/DirFileProbe/A/B/C","",NULL,"/DirFileProbe/A/B/C/");
  DFCase(r,10,NULL,NULL,NULL,"/DirFileProbe/A/B/C");
  DFCase(r,11,"@anchor.HC",NULL,NULL,"/DirFileProbe/A/B/C");
  DFCase(r,12,"/DirFileProbe/A/B/C/Missing/Sub/unknown.HC",NULL,NULL,"/DirFileProbe/A/B/C");
  DFCase(r,13,"/",NULL,NULL,"/");
  DFCase(r,14,"/","absent","X","//absent.X");
  DFCase(r,15,"/DirFileProbe/A/B/C","near.HC","HC","/DirFileProbe/A/B/C/near.HC.HC");
  DFCase(r,16,"/DirFileProbe/A/B/C","near",".","/DirFileProbe/A/B/C/near.");
  DFCase(r,17,"/DirFileProbe/A/B/C","","HC","/DirFileProbe/A/B/C/.HC");
  DFCase(r,18,"/DirFileProbe","root","HC","/DirFileProbe/root.HC");
  DFCase(r,19,"/DirFileProbe/A/B/C","root","HC","/DirFileProbe/root.HC");
  s=MStrPrint("EXPORT dir-file-pre-repeat.bin %X 140\n",r);DFLog(s);Free(s);
  s=MStrPrint("EXPORT dir-file-pre-paths.txt %X %X\n",df_text,df_used);DFLog(s);Free(s);
  DFLog("DF REPEAT BEGIN\n");
  used=Fs->data_heap->used_u8s;
  for(i=0;i<256;i++){
    if(!(i&15)){s=MStrPrint("DF REPEAT %d\n",i);DFLog(s);Free(s);}
    if(!i)DFLog("DF MISS START\n");
    result=DirFile(base,"absent","X");if(!result || StrCmp(result,want))ok=FALSE;Free(result);
    if(!i)DFLog("DF MISS END\n");
    result=DirFile(base,"up","HC");if(!result || StrCmp(result,parent))ok=FALSE;Free(result);
  }
  r[40]=ok;df_deltas[20]=Fs->data_heap->used_u8s-used;r[41]=!df_deltas[20];
  r[42]=Cd(old);now=DirCur;r[42]=r[42] && !StrCmp(now,old);Free(now);r[43]=sizeof(I64)==8;
  Free(old);Free(base);Free(want);Free(parent);
  s=MStrPrint("EXPORT dir-file.bin %X 160\n",r);DFLog(s);Free(s);
  s=MStrPrint("EXPORT dir-file-paths.txt %X %X\n",df_text,df_used);DFLog(s);Free(s);
  s=MStrPrint("EXPORT dir-file-heap-deltas.bin %X A8\n",df_deltas);DFLog(s);Free(s);
  DFLog("DIR FILE DONE\n");Sleep(1000);
}
DFCheck;
