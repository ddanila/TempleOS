U0 FRPut16(U8 *p,I64 n){p[0]=n;p[1]=n>>8;}
I64 FRContract()
{
 U8 raw[32];CDirEntry entry;CDateStruct ds;I64 mask=0;CDate expected,offset=0x100000000;
 MemSet(raw,0,sizeof(raw));MemCpy(raw,"FILE    TXT",11);raw[11]=0x20;
 FRPut16(raw+20,0x1234);FRPut16(raw+26,0x5678);raw[28]=4;raw[29]=3;raw[30]=2;raw[31]=1;
 FRPut16(raw+22,(23<<11)|(59<<5)|29);FRPut16(raw+24,(44<<9)|(2<<5)|29);
 MemSet(&ds,0,sizeof(ds));ds.year=2024;ds.mon=2;ds.day_of_mon=29;ds.hour=23;ds.min=59;ds.sec=58;expected=Struct2Date(&ds);
 MemSet(&entry,0,sizeof(entry));
 if(FAT32CDirFill(&entry,raw,0) && !StrCmp(entry.name,"FILE.TXT"))mask|=1;
 if(entry.clus==0x12345678 && entry.size==0x01020304 && entry.attr==0x20)mask|=2;
 if(entry.datetime==expected)mask|=4;
 MemSet(&entry,0,sizeof(entry));StrCpy(entry.name,"LongFile.txt");
 if(FAT32CDirFill(&entry,raw,offset) && !StrCmp(entry.name,"LongFile.txt") && entry.datetime==expected-offset)mask|=8;
 MemCpy(raw,"BAD/    TXT",11);MemSet(&entry,0,sizeof(entry));
 if(!FAT32CDirFill(&entry,raw,0) && entry.clus==0x12345678 && entry.size==0x01020304 && entry.datetime==expected)mask|=16;
 MemCpy(raw,"DIR        ",11);raw[11]=0x10;MemSet(&entry,0,sizeof(entry));
 if(FAT32CDirFill(&entry,raw,0) && !StrCmp(entry.name,"DIR") && entry.attr==0x10 && entry.size==0x01020304)mask|=32;
 return mask;
}
