#include "/Kernel/I386/Module.HH"
extern Bool I386ModuleValid(U8 *data,I64 size);
extern Bool I386ModuleValidParts(CI386ModuleHeader *h,CI386ModuleRecord *r,
 U8 *strings,I64 size,U8 (*code)(U8 *context,U32 offset),U8 *context);
I64 VBReads;
U8 VBByte(U8 *context,U32 offset){VBReads++;return context[32+offset];}
I64 VBCheck(I64 mode)
{
 I64 before=Fs->data_heap->used_u8s,size,m=0;U8 *data;
 CI386ModuleHeader *h;CI386ModuleRecord *records;U32 saved;
 Bool ok=FALSE;
 data=FileRead("C:/Modules/I386/MemoryRuntime.t32m",&size);
 if(!data)throw('ValidIO',TRUE);
 h=data;records=data+h->records_offset;VBReads=0;saved=h->magic;
 if(mode==0)ok=I386ModuleValid(data,size);
 if(mode==1)ok=!I386ModuleValid(NULL,size);
 if(mode==2)ok=!I386ModuleValid(data,-1);
 if(mode==3)ok=!I386ModuleValid(data,size-1);
 if(mode==4){h->magic=0;ok=!I386ModuleValid(data,size);h->magic=saved;}
 if(mode==5)ok=I386ModuleValidParts(h,records,data+h->strings_offset,size,&VBByte,data)&&VBReads>0;
 if(mode==6)ok=!I386ModuleValidParts(h,records,data+h->strings_offset,size-1,&VBByte,data);
 if(mode==7)ok=!I386ModuleValidParts(h,records,data+h->strings_offset,size,NULL,data);
 if(mode==8){h->magic=0;ok=!I386ModuleValidParts(h,records,data+h->strings_offset,size,&VBByte,data);h->magic=saved;}
 if(ok)m|=1;
 if(h->magic==saved&&I386ModuleValid(data,size))m|=2;
 Free(data);
 if(Fs->data_heap->used_u8s==before)m|=4;
 if(m!=7)throw('ValidAPI',TRUE);
 return m;
}
