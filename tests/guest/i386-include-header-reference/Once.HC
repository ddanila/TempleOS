U0 IncludeReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 IncludeHeaderReference()
{
 I64 *rows=CAlloc(7*8),exception=0,size;
 U8 *source="I64 IncludePending(){return 99;}\n#include \"T:/Abort.HC\"\n",*output;
 CDoc *old=Fs->put_doc,*doc=DocNew;
 CHashFun *function;
 CHash *undefined;
 U8 *undefined_address;
 while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
 IncludeReport("ADAM SERVER READY\n");Fs->put_doc=doc;ExePutS("23;");
 try{ExePutS(source);}catch{exception=Fs->except_ch;Fs->catch_except=TRUE;}
 rows[0]=exception;rows[1]=Fs->answer;
 function=HashFind("IncludePending",Fs->hash_table,HTT_FUN);
 undefined=HashFind("UndefinedExtern",Fs->hash_table,HTT_FUN|HTT_EXPORT_SYS_SYM);
 if(undefined->type&HTT_FUN)undefined_address=undefined(CHashFun *)->exe_addr;
 else undefined_address=undefined(CHashExport *)->val;
 rows[2]=function!=NULL;
 if(function){rows[3]=Bt(&function->flags,Cf_EXTERN);rows[4]=function->exe_addr==undefined_address;}
 exception=0;
 try{ExePutS("IncludePending();");}catch{exception=Fs->except_ch;Fs->catch_except=TRUE;}
 rows[5]=exception;rows[6]=Fs->answer;Fs->put_doc=old;
 output=MStrPrint("EXPORT include-header.bin %X %X\n",rows,7*8);IncludeReport(output);
 output=DocSave(doc,&size);U8 *notice=MStrPrint("EXPORT include-header.DD %X %X\n",output,size);IncludeReport(notice);
 IncludeReport("DONE include header reference\n");
}
IncludeHeaderReference;
