U8 fl_offsets[13]={1,3,5,7,9,14,16,18,20,22,24,28,30};
U0 FLSlot(U8 *entry,I64 ord,I64 sum,U8 *text)
{
 I64 i;MemSet(entry,0,32);entry[0]=ord;entry[11]=15;entry[13]=sum;
 for(i=0;i<13 && text[i];i++)entry[fl_offsets[i]]=text[i];
}
I64 FLContract()
{
 U8 slot[32];CDirEntry entry;I64 sum=0,mask=0;
 MemSet(&entry,0xA5,sizeof(entry));FLSlot(slot,0x41,42,"HELLO.TXT");
 if(DirLongNameFill(&entry,slot,&sum) && sum==42 && !StrCmp(entry.name,"HELLO.TXT"))mask|=1;
 FLSlot(slot,0x42,57,"NOPQRST");if(DirLongNameFill(&entry,slot,&sum) && sum==57 && !StrCmp(entry.name+13,"NOPQRST"))mask|=2;
 FLSlot(slot,1,57,"ABCDEFGHIJKLM");if(DirLongNameFill(&entry,slot,&sum) && !StrCmp(entry.name,"ABCDEFGHIJKLMNOPQRST"))mask|=4;
 FLSlot(slot,1,58,"BAD");if(!DirLongNameFill(&entry,slot,&sum) && !*entry.name && !sum)mask|=8;
 FLSlot(slot,0x42,31,"XYZ");DirLongNameFill(&entry,slot,&sum);FLSlot(slot,1,31,"Q");slot[12]=1;
 if(!DirLongNameFill(&entry,slot,&sum) && !*entry.name && !sum)mask|=16;
 FLSlot(slot,0x42,31,"XYZ");DirLongNameFill(&entry,slot,&sum);FLSlot(slot,1,31,"Q");slot[26]=1;
 if(!DirLongNameFill(&entry,slot,&sum) && !*entry.name && !sum)mask|=32;
 FLSlot(slot,0x41,13,"A");slot[2]=1;if(DirLongNameFill(&entry,slot,&sum) && !StrCmp(entry.name,"A") && sum==13)mask|=64;
 FLSlot(slot,0x42,77,"NOPQRSTUVWXYZ");DirLongNameFill(&entry,slot,&sum);FLSlot(slot,1,77,"ABCDEFGHIJKLM");DirLongNameFill(&entry,slot,&sum);
 if(!StrCmp(entry.name,"ABCDEFGHIJKLMNOPQRSTUVWXY"))mask|=128;
 if(!StrCmp(entry.name,"ABCDEFGHIJKLMNOPQRSTUVWXYZ"))mask|=256;
 FLSlot(slot,0x43,91,"0123456789A");DirLongNameFill(&entry,slot,&sum);FLSlot(slot,2,91,"NOPQRSTUVWXYZ");DirLongNameFill(&entry,slot,&sum);FLSlot(slot,1,91,"ABCDEFGHIJKLM");DirLongNameFill(&entry,slot,&sum);
 if(!StrCmp(entry.name,"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789A"))mask|=512;
 return mask;
}
