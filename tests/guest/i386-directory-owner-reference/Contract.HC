U8 do_base[STR_LEN];
Bool DOSetup(U8 drive)
{
 U8*root=MStrPrint("%c:/",drive);Bool ok=Cd(root);Free(root);
 DirMk("Probe");Cd("Probe");DirMk("DirectoryOwner");ok=ok&&Cd("DirectoryOwner");
 DirMk("A");StrCpy(do_base,Fs->cur_dir);return ok;
}
I64 do_child_result;
U0 DOChild(CTask *parent)
{
 I64 m=0;U8*path=MStrPrint("%c:%s",Drv2Let(parent->cur_dv),do_base);
 //Original Spawn starts at home; explicitly select the shared fixture directory.
 Cd(path);Free(path);
 if(Fs->cur_dir!=parent->cur_dir&&!StrCmp(Fs->cur_dir,parent->cur_dir)&&
    MHeapCtrl(Fs->cur_dir)==Fs->data_heap&&Fs->data_heap!=parent->data_heap)m|=1;
 Free(Fs->cur_dir);Fs->cur_dir=StrNew("/");
 if(!StrCmp(parent->cur_dir,do_base)&&!StrCmp(Fs->cur_dir,"/")&&Cd(do_base))m|=2;
 do_child_result=m;
}
I64 DOContract(I64 mode)
{
 I64 before=Fs->data_heap->used_u8s,m=0;
 CDrv*drive=Fs->cur_dv;CDoc*put=DocPut,*display=DocDisplay,*border=DocBorder;
 U8*replacement,*actual,*expected;CTask*child;
 if(MHeapCtrl(Fs->cur_dir)==Fs->data_heap&&MSize(Fs->cur_dir)>=StrLen(Fs->cur_dir)+1)m|=1;
 if(mode==3){
  do_child_result=0;child=Spawn(&DOChild,Fs,"Directory owner",-1,Fs);
  while(TaskValidate(child))Yield;
  if(do_child_result==3&&!StrCmp(Fs->cur_dir,do_base))m|=2;
 }else{
 if(mode==0)replacement=StrNew(do_base);
 else if(mode==1)replacement=MStrPrint("%s/A",do_base);
 else replacement=StrNew("/");
 Free(Fs->cur_dir);Fs->cur_dir=replacement;
 actual=FileNameAbs("marker");
 if(mode==2)expected=MStrPrint("%c:/marker",Drv2Let(drive));
 else expected=MStrPrint("%c:%s/marker",Drv2Let(drive),replacement);
 if(!StrCmp(actual,expected))m|=2;
 Free(actual);Free(expected);
 }
 if(MHeapCtrl(Fs->cur_dir)==Fs->data_heap&&Fs->cur_dv==drive)m|=4;
 if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=8;
 Cd(do_base);
 if(!StrCmp(Fs->cur_dir,do_base)&&Fs->data_heap->used_u8s==before)m|=16;
 return m;
}
I64 DOCheck(I64 mode){I64 m=DOContract(mode);if(m!=31)throw('DirOwner',TRUE);return m;}
