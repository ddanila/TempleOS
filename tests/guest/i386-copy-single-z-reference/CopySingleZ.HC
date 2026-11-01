I64 CSContract(I64 drive)
{
 U8 *src=MStrPrint("%c:/CopyTest.HC",drive),*z=MStrPrint("%c:/CopyTest.HC.Z",drive),
    *dst=MStrPrint("%c:/CopyOut.HC",drive),*missing=MStrPrint("%c:/CopyMissing.HC",drive),*buf,*line;
 I64 mask=0,size,attr;CDirEntry de1,de2;Bool old_silent=Silent(TRUE);
 CSDelete(src);CSDelete(z);CSDelete(dst);CSDelete(missing);
 if(FileWrite(src,"Hello copy!",11,0x11223344))mask|=1;
 if(CopySingleZ(src,z))mask|=2;
 buf=FileRead(z,&size,&attr);
 if(buf&&size==11&&!MemCmp(buf,"Hello copy!",11)&&(attr&0x400))mask|=4;
 Free(buf);
 if(CopySingleZ(z,dst))mask|=8;
 buf=FileRead(dst,&size,&attr);
 if(buf&&size==11&&!MemCmp(buf,"Hello copy!",11)&&!(attr&0x400))mask|=16;
 Free(buf);
 if(FileFind(src,&de1)&&FileFind(dst,&de2)) {
   if(de1.datetime==de2.datetime)mask|=32;
   Free(de1.full_name);Free(de2.full_name);
 }
 if(!CopySingleZ(missing,dst)) {
   buf=FileRead(dst,&size,&attr);
   if(buf&&size==11&&!MemCmp(buf,"Hello copy!",11)&&!(attr&0x400))mask|=64;
   Free(buf);
 }
 if(CSDelete(src)&&CSDelete(z)&&CSDelete(dst))mask|=128;
 Free(src);Free(z);Free(dst);Free(missing);Silent(old_silent);
 line=MStrPrint("COPY SINGLE Z MASK %d\n",mask);Report(line);Free(line);
 return mask;
}
I64 CSCheck(I64 drive){I64 v=CSContract(drive);if(v!=255)throw('CopyTest',TRUE);return v;}
