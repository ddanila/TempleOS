U32 DPExpected[8]={0x0000000,0x03FF73FB,0xEFFFFFFF,0x6FFFFFFF,
   0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF};
I64 DPKeys=0,DPStrings=0;
Bool DPKey(I64 ch,I64 sc){DPKeys++;return TRUE;}
Bool DPString(U8 *s){DPStrings++;return TRUE;}
I64 DPContract(I64 mode)
{
 Bool ok=FALSE,old,prior;I64 i,flags=Fs->display_flags;
 U8 name[CDIR_FILENAME_LEN+1],one[2];
 CKeyDevEntry *hook;
 if(mode==0)ok=!FileNameChk(NULL)&&!FileNameChk("");
 else if(mode==1)ok=FileNameChk(".")&&FileNameChk("..");
 else if(mode==2){MemSet(name,'a',sizeof(name));name[CDIR_FILENAME_LEN-1]=0;
   ok=FileNameChk(name);name[CDIR_FILENAME_LEN-1]='a';name[CDIR_FILENAME_LEN]=0;
   ok=ok&&!FileNameChk(name);}
 else if(mode==3){ok=TRUE;one[1]=0;for(i=1;i<256;i++){one[0]=i;
   if(FileNameChk(one)!=(i=='.'||Bt(DPExpected,i)))ok=FALSE;}}
 else if(mode==4){old=Silent(OFF);ok=!IsSilent();prior=Silent();
   ok=ok&&!prior&&IsSilent();prior=Silent(ON);ok=ok&&prior;
   prior=Silent(OFF);ok=ok&&prior&&!IsSilent();Silent(old);}
 else if(mode==5){old=Silent(OFF);hook=KeyDevAdd(&DPKey,&DPString,5,TRUE);
   DPKeys=0;DPStrings=0;PutKey('a');PutChars('bc');PutS("test");Print("test");
   ok=DPKeys==3&&DPStrings==2;Silent(ON);
   PutKey('a');PutChars('bc');PutS("test");Print("test");
   ok=ok&&DPKeys==3&&DPStrings==2;Silent(old);KeyDevRem(hook);}
 else if(mode==6){old=Silent(OFF);ok=Fs->display_flags==(flags&~(1<<DISPLAYf_SILENT));
   Silent(ON);ok=ok&&Fs->display_flags==(flags|(1<<DISPLAYf_SILENT));Silent(old);}
 else if(mode==7){StrCpy(name,"valid.HC");ok=FileNameChk(name)&&!StrCmp(name,"valid.HC");
   StrCpy(name,"bad/name");ok=ok&&!FileNameChk(name)&&!StrCmp(name,"bad/name");}
 if(Fs->display_flags!=flags)return 0;
 if(ok)return 31;return 0;
}
I64 DPCheck(I64 mode){I64 result=DPContract(mode);if(result!=31)throw('DPFail');return result;}
