U0 ISOLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 ISOCheck(I64 drive)
{
  U8 *home=DirCur,*root=MStrPrint("%C:/ISOScope",drive),
     *name=MStrPrint("%C:/Result.ISO.C",drive),*stage,*data,*image,*plain,*s;
  U8 payload[4097],boot[1537],path[STR_LEN];
  I64 i,size,v[10],mounted;
  CDirEntry de;
  DirMk(root);Cd(root);DirMk("Nested");DirMk("Empty");
  for(i=0;i<4097;i++)payload[i]=i*7;
  for(i=0;i<1537;i++)boot[i]=i*11+3;
  FileWrite("Nested/Small.DATA","iso",3,0x1122334455667788);
  FileWrite("Large.DATA",payload,4097,0x1122334455667788);
  FileWrite("Stage2.BIN",boot,1537,0x1122334455667788);
  stage=FileNameAbs("Stage2.BIN");Cd(home);
  v[0]=RedSeaISO(name,root,stage)>0;
  image=FileRead(name,&size);v[1]=image && size>45056 && !(size&2047);
  s=MStrPrint("EXPORT generated.iso %X %X\n",image,size);ISOLog(s);Free(s);
  mounted=MountFile(name);StrPrint(path,"%C:/Nested/Small.DATA",mounted);
  data=FileRead(path,&size);v[2]=data && size==3 && !MemCmp(data,"iso",3);Free(data);
  StrPrint(path,"%C:/Large.DATA",mounted);data=FileRead(path,&size);
  v[3]=data && size==4097 && !MemCmp(data,payload,4097);Free(data);
  StrPrint(path,"%C:/Stage2.BIN",mounted);data=FileRead(path,&size);
  v[4]=data && size==1537 && !MemCmp(data,boot,1537);Free(data);
  StrPrint(path,"%C:/Empty",mounted);v[5]=IsDir(path);
  v[6]=Let2Drv(mounted)->bd->type==BDT_ISO_FILE_READ;
  Unmount(mounted);v[7]=!Let2Drv(mounted,FALSE);
  Free(name);name=MStrPrint("%C:/Default.ISO.C",drive);
  v[8]=RedSeaISO(name,root)>0;
  plain=FileRead(name,&size);
  s=MStrPrint("EXPORT default.iso %X %X\n",plain,size);ISOLog(s);Free(s);
  mounted=MountFile(name);StrPrint(path,"%C:/Large.DATA",mounted);
  data=FileRead(path,&size);v[9]=data && size==4097 && !MemCmp(data,payload,4097);Free(data);
  Unmount(mounted);
  s=MStrPrint("EXPORT iso-checks.bin %X %X\n",v,sizeof(v));ISOLog(s);Free(s);
  ISOLog("REDSEA ISO DONE\n");Sleep(1000);
  Free(plain);Free(image);Free(stage);Free(name);Free(root);Free(home);
}
