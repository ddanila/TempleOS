I64 fo_next[32];
class FOTestDrive {I64 size,spc;};
I64 FONext(FOTestDrive *dv,I64 clus)
{
 if (0<=clus<32) return fo_next[clus];
 return INVALID_CLUS;
}
// INSERT HELPER
I64 FOContract()
{
 FOTestDrive dv;I64 mask=0;Bool caught;
 MemSet(fo_next,0xFF,sizeof(fo_next));dv.size=32;dv.spc=1;
 fo_next[2]=3;fo_next[3]=4;fo_next[5]=6;fo_next[6]=3;fo_next[7]=8;
 if(FOOverlap(&dv,2,2)==2)mask|=1;
 if(FOOverlap(&dv,2,3)==3)mask|=2;
 if(FOOverlap(&dv,3,2)==3)mask|=4;
 if(FOOverlap(&dv,2,5)==3)mask|=8;
 if(FOOverlap(&dv,5,2)==3)mask|=16;
 if(FOOverlap(&dv,2,7)==INVALID_CLUS)mask|=32;
 if(FOOverlap(&dv,0,2)==INVALID_CLUS)mask|=64;
 if(FOOverlap(&dv,2,INVALID_CLUS)==INVALID_CLUS)mask|=128;
 fo_next[10]=11;fo_next[11]=10;caught=FALSE;
 try {FOOverlap(&dv,10,2);} catch {caught=Fs->except_ch=='FAT';Fs->catch_except=TRUE;}
 if(caught)mask|=256;
 caught=FALSE;
 try {FOOverlap(&dv,2,10);} catch {caught=Fs->except_ch=='FAT';Fs->catch_except=TRUE;}
 if(caught)mask|=512;
 caught=FALSE;dv.spc=0;
 try {FOOverlap(&dv,2,3);} catch {caught=Fs->except_ch=='FAT';Fs->catch_except=TRUE;}
 if(caught)mask|=1024;
 return mask;
}
U0 FOReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 fo_mask=FOContract;U8 *fo_line=MStrPrint("FAT OVERLAP MASK %d\n",fo_mask);
FOReport(fo_line);Free(fo_line);FOReport("DONE fat overlap\n");
