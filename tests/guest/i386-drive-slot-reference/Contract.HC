#ifndef DS_TABLE_ENTER
#define DS_TABLE_ENTER
#define DS_TABLE_LEAVE
#endif
I64 DSContract(I64 mode)
{
 CDrv saved[DRVS_NUM],expected[DRVS_NUM],*dv,*res=NULL,*again=NULL,*current=Fs->cur_dv;
 U8 *directory=Fs->cur_dir,*letters="ABCLMPQSTZ",*starts="ACMQT",*ends="BLPSZ";
 CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
 I64 i,j,before,m=0,index=-1,free_index=-1,kind,shape,answer=0,repeated=0;
 U8 letter='C';Bool bad=FALSE,caught=FALSE,repeat_throw=FALSE,exact=TRUE,repeat=TRUE,make=mode<16;
 if(make) {
   if(mode<10)letter=letters[mode];
   else if(mode==10)letter='c';else if(mode==11)letter=0;
   else if(mode==12)letter=':';else if(mode==13)letter='~';
   else if(mode==14)letter='?';else letter='[';
   index=Let2Let(letter)-'A';bad=index<0||index>=DRVS_NUM;
 } else if(mode<36) {
   kind=(mode-16)/4;shape=(mode-16)%4;letter=starts[kind];
   if(shape==0)free_index=letter-'A';
   if(shape==1)free_index=ends[kind]-'A';
   if(shape==2)free_index=ends[kind]-'A'+1;
   if(free_index>=DRVS_NUM)free_index=-1;
   bad=shape>=2;
 } else {
   if(mode==36)letter='c';if(mode==37)letter='?';if(mode==38)letter=0;
   if(mode==39)letter=':';if(mode==40)letter='~';
   free_index=Let2Let(letter)-'A';bad=free_index<0||free_index>=DRVS_NUM;
   //The zero alias validates the current record before searching.
   if(mode==38){free_index++;bad=free_index>=DRVS_NUM||Let2BlkDevType('A'+free_index)!=Let2BlkDevType(0);}
 }
 Sleep(100);
 Bool wm=Suspend(sys_winmgr_task),root=FALSE;
 if(adam_task!=Fs)root=Suspend(adam_task);
 DS_TABLE_ENTER
 before=Fs->data_heap->used_u8s;
 for(i=0;i<DRVS_NUM;i++) {
   dv=DSRecord(i);MemCpy(&saved[i],dv,sizeof(CDrv));
   MemSet(dv,0xA5,sizeof(CDrv));dv->dv_signature=DRV_SIGNATURE_VAL;dv->drv_let='A'+i;
   if(!make&&i==free_index)dv->dv_signature=0;
   MemCpy(&expected[i],dv,sizeof(CDrv));
 }
 if(make&&!bad){MemSet(&expected[index],0,sizeof(CDrv));expected[index].drv_let='A'+index;}
 try {
   if(make)res=DrvMakeFreeSlot(letter);
   else if(mode==41)answer=DrvNextFreeLet;
   else answer=DrvNextFreeLet(letter);
 } catch {caught=Fs->except_ch=='Drv';Fs->catch_except=TRUE;}
 if(bad){if(caught&&!res&&!answer)m|=1;}
 else if(!caught&&(make&&res==DSRecord(index)||!make&&answer=='A'+free_index))m|=1;
 for(i=0;i<DRVS_NUM;i++) {
   dv=DSRecord(i);
   for(j=0;j<sizeof(CDrv);j++)if(dv(U8 *)[j]!=(&expected[i])(U8 *)[j])exact=FALSE;
 }
 if(exact)m|=2;
 if(!bad) {
   try {
     if(make)again=DrvMakeFreeSlot(letter);
     else if(mode==41)repeated=DrvNextFreeLet;
     else repeated=DrvNextFreeLet(letter);
   } catch {if(mode==11&&Fs->except_ch=='Drv')repeat_throw=TRUE;else repeat=FALSE;Fs->catch_except=TRUE;}
   if(mode==11){if(!repeat_throw||again)repeat=FALSE;}
   else if(make&&again!=res||!make&&repeated!=answer)repeat=FALSE;
 }
 for(i=0;i<DRVS_NUM;i++) {
   dv=DSRecord(i);
   for(j=0;j<sizeof(CDrv);j++)if(dv(U8 *)[j]!=(&expected[i])(U8 *)[j])repeat=FALSE;
   MemCpy(dv,&saved[i],sizeof(CDrv));
 }
 if(repeat)m|=4;
 if(Fs->data_heap->used_u8s==before)m|=8;
 if(Fs->cur_dv==current&&Fs->cur_dir==directory&&DocPut==put&&DocDisplay==display&&DocBorder==border)m|=16;
 DS_TABLE_LEAVE
 if(adam_task!=Fs)Suspend(adam_task,root);Suspend(sys_winmgr_task,wm);
 return m;
}
I64 DSCheck(I64 mode){I64 m=DSContract(mode);if(m!=31)throw('DrvSlot',TRUE);return m;}
