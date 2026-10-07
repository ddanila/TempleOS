#include "/Kernel/I386/Ata.HH"
U8 *ia_source,*ia_target;
CI386Ata ia_from,ia_to;
I64 ia_writes,ia_flushes,ia_last,ia_fail_write,ia_fail_flush;
Bool ia_bad;
Bool I386AtaTransfer(CI386Ata *disk,I64 lba,U8 *buffer,I64 polls,Bool write,CI386AtaPoll *poll)
{
  U8 *data;
  no_warn polls; no_warn poll;
  if(lba<0 || lba>=2048 || (disk!=&ia_from && disk!=&ia_to)) { ia_bad=TRUE; return FALSE; }
  data=ia_source; if(disk==&ia_to) data=ia_target;
  if(write) {
    if(disk!=&ia_to) { ia_bad=TRUE; return FALSE; }
    if(lba==ia_fail_write) return FALSE;
    if(!lba && (ia_writes!=2047 || ia_flushes!=1)) ia_bad=TRUE;
    MemCpy(data+lba*512,buffer,512); ia_writes++; ia_last=lba;
  } else MemCpy(buffer,data+lba*512,512);
  return TRUE;
}
Bool I386AtaFlushPolled(CI386Ata *disk,I64 polls,CI386AtaPoll *poll)
{
  no_warn polls; no_warn poll;
  if(disk!=&ia_to) { ia_bad=TRUE; return FALSE; }
  ia_flushes++;
  return ia_flushes!=ia_fail_flush;
}
#include "T:/BootAreaCore.HC"
U0 IAReset(I64 sectors)
{
  MemSet(&ia_from,0,sizeof(CI386Ata)); MemSet(&ia_to,0,sizeof(CI386Ata));
  ia_from.signature=ia_to.signature=0x41543332;
  ia_from.sectors=ia_to.sectors=sectors; ia_from.io=0x1F0; ia_to.io=0x170;
  ia_to.flush=TRUE;
  MemSet(ia_target,0,2048*512); MemSet(ia_target+2048*512,0xA7,512);
  ia_writes=ia_flushes=ia_bad=0; ia_last=-1; ia_fail_write=ia_fail_flush=-1;
}
I64 IAContract()
{
  I64 mode,profile,i,j,cut,sectors;
  U8 image[1024];
  Bool ok;
  ia_source=CAlloc(2048*512); ia_target=CAlloc(2049*512);
  for(i=0;i<2048*512;i++) ia_source[i]=(i*13+7)&255;
  ia_source[510]=0x55; ia_source[511]=0xAA;
  (ia_source+528)(U32 *)[0]=0x42323345;
  (ia_source+532)(U32 *)[0]=1; (ia_source+540)(U32 *)[0]=0x100000;
  for(i=0;i<1024;i++) image[i]=(i*7+3)&255;
  image[0]=0xE9; (image+1)(I32 *)[0]=3; image[5]=image[6]=image[7]=0;
  for(mode=0;mode<2;mode++) {
    for(profile=0;profile<3;profile++) {
      sectors=32768<<profile; IAReset(sectors);
      if(mode) ok=I386InstallBootImageArea(&ia_from,&ia_to,image,1024);
      else ok=I386InstallBootArea(&ia_from,&ia_to);
      if(!ok || ia_bad || ia_writes!=2048 || ia_flushes!=2 || ia_last) return 10+mode*10+profile;
      if(!mode && MemCmp(ia_source,ia_target,2048*512)) return 30;
      if(mode) {
        if(MemCmp(ia_source,ia_target,512) || (ia_target+536)(U32 *)[0]!=1024) return 31;
        for(i=4608;i<2048*512;i++) {
          j=i-4608;
          if(j<1024) { if(ia_target[i]!=image[j]) return 32; }
          else if(ia_target[i]) return 33;
        }
      }
      for(i=2048*512;i<2049*512;i++) if(ia_target[i]!=0xA7) return 34;
    }
    for(cut=0;cut<7;cut++) {
      IAReset(65536);
      switch(cut) {
        case 0: ia_to.sectors=2047; break;
        case 1: ia_target[0]=1; break;
        case 2: ia_to.io=ia_from.io; break;
        case 3: ia_fail_write=17; break;
        case 4: ia_fail_write=2047; break;
        case 5: ia_fail_flush=1; break;
        case 6: ia_from.sectors=2047; break;
      }
      if(mode) ok=I386InstallBootImageArea(&ia_from,&ia_to,image,1024);
      else ok=I386InstallBootArea(&ia_from,&ia_to);
      if(ok || ia_bad || ((cut<3 || cut==6) && ia_writes)) return 40+cut;
      for(i=0;i<512;i++) if(ia_target[i]!=(cut==1 && !i)) return 50+cut;
      for(i=2048*512;i<2049*512;i++) if(ia_target[i]!=0xA7) return 60+cut;
    }
  }
  Free(ia_source); Free(ia_target); return 0;
}
U0 IAReport(U8 *text) { while(*text) OutU8(0xE9,*text++); }
I64 ia_result=IAContract;
if(ia_result) { U8 *line=MStrPrint("FAIL install-area %d\n",ia_result); IAReport(line); Free(line); }
else IAReport("DONE install-area 20 cases\n");
