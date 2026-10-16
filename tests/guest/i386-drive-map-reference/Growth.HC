//Native RedSea integration: force root relocation through a mapped letter.
Bool DMRootGrowth()
{
 CDrv *saved=*DMMapSlot('X'-'A'),*drive=Let2Drv('C');
 U8 letter=drive->drv_let,*name=NULL,*data=NULL;
 I64 root=drive->root_clus,i,size;
 Bool result=DrvMap('X',drive);
 try {
   for(i=0;i<80&&result;i++) {
     name=MStrPrint("X:/MapRoot%03d.TXT",i);
     result=FileWrite(name,"grow",4)>0;Free(name);name=NULL;
   }
   result=result&&drive->root_clus!=root;
   for(i=0;i<80&&result;i++) {
     name=MStrPrint("C:/MapRoot%03d.TXT",i);
     data=FileRead(name,&size);result=DMBytes(data,size,"grow",4);
     Free(data);data=NULL;Free(name);name=NULL;
   }
 } catch {result=FALSE;Fs->catch_except=TRUE;}
 Free(data);Free(name);*DMMapSlot('X'-'A')=saved;drive->drv_let=letter;
 return result;
}
