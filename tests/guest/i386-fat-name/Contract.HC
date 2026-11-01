Bool FNEq(U8 *a,U8 *b,I64 n){I64 i;for(i=0;i<n;i++)if(a[i]!=b[i])return FALSE;return TRUE;}
I64 FNContract()
{
 U8 out[64],name[48];I64 mask=0,i;Bool untouched;
 MemSet(out,0xA5,sizeof(out));if(FATNameTo(out,"test.txt") && FNEq(out,"TEST    TXT",11) && out[11]==0xA5)mask|=1;
 if(FATNameXSum(out)==143)mask|=2;
 MemSet(name,0,sizeof(name));if(FATFromName(name,out) && !StrCmp(name,"TEST.TXT"))mask|=4;
 if(FATNameTo(out,".") && FNEq(out,".          ",11) && FATNameXSum(out)==119 && FATFromName(name,out) && !StrCmp(name,"."))mask|=8;
 if(FATNameTo(out,"..") && FNEq(out,"..         ",11) && FATNameXSum(out)==194 && FATFromName(name,out) && !StrCmp(name,".."))mask|=16;
 MemSet(out,0xA5,sizeof(out));if(!FATNameTo(out,"bad/name") && FNEq(out,"           ",11) && out[11]==0xA5)mask|=32;
 if(FATNameTo(out,"file.hc") && FNEq(out,"FILE    HC ",11) && FATNameXSum(out)==88 && FATFromName(name,out) && !StrCmp(name,"FILE.HC"))mask|=64;
 if(FATNameTo(out,"readme") && FNEq(out,"README     ",11) && FATFromName(name,out) && !StrCmp(name,"README"))mask|=128;
 MemSet(out,0xA5,sizeof(out));if(FATNameTo(out,"a.long") && FNEq(out,"A       LONG",12) && out[12]==0xA5)mask|=256;
 MemSet(out,0xA5,sizeof(out));if(FATNameTo(out,"a.long") && FNEq(out,"A       LON",11) && out[11]==0xA5 && out[12]==0xA5)mask|=512;
 for(i=0;i<37;i++)name[i]='A';name[37]=0;MemSet(out,0xA5,sizeof(out));
 if(FATNameTo(out,name) && FNEq(out,"AAAAAAAAAAA",11) && out[37]==0xA5)mask|=1024;
 untouched=TRUE;for(i=11;i<64;i++)if(out[i]!=0xA5)untouched=FALSE;if(untouched)mask|=2048;
 return mask;
}
