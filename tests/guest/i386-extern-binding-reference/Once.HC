U0 BindingReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 BindingExport(U8 *name,U8 *data,I64 size)
{U8 *s=MStrPrint("EXPORT %s %X %X\n",name,data,size);BindingReport(s);Free(s);}
U0 BindingReference()
{
 CDoc *old=Fs->put_doc,*doc;
 CHashFun *first,*current;
 U8 *name,*caller,*source,*text,*output;
 I64 mode,kind,exception,value,size,*rows=CAlloc(16*5*8);
 while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
 BindingReport("ADAM SERVER READY\n");
 for(mode=0;mode<2;mode++) {
  name=MStrPrint("BindingTarget%d",mode);caller=MStrPrint("BindingCaller%d",mode);first=NULL;
  for(kind=0;kind<8;kind++) {
   switch(kind) {
    case 0:source=MStrPrint("extern I64 %s(I64 a=7);",name);break;
    case 1:source=MStrPrint("I64 %s(){return %s();}",caller,name);break;
    case 2:case 4:case 6:source=MStrPrint("%s();",caller);break;
    case 3:source=MStrPrint("I64 %s(I64 a=7){return a+90;}",name);break;
    case 5:source=MStrPrint("I64 %s(I64 a=7){return 101;}",name);break;
    case 7:source=MStrPrint("%s();",name);break;
   }
   doc=DocNew;Fs->put_doc=doc;ExePutS("23;");exception=0;value=0;
   try{value=ExePutS(source,0,mode);}catch{exception=Fs->except_ch;Fs->catch_except=TRUE;}
   current=HashFind(name,Fs->hash_table,HTT_FUN);if(kind==0)first=current;
   rows[(mode*8+kind)*5]=value;rows[(mode*8+kind)*5+1]=exception;
   rows[(mode*8+kind)*5+2]=Fs->answer;
   rows[(mode*8+kind)*5+3]=current!=NULL;
   rows[(mode*8+kind)*5+4]=current==first;
   text=DocSave(doc,&size);output=MStrPrint("binding-%d.DD",mode*8+kind);
   BindingExport(output,text,size);Free(output);
   //Export payloads and failed-control borrowed source buffers stay live.
   Fs->put_doc=old;DocDel(doc);
  }
  Free(name);Free(caller);
 }
 BindingExport("binding.bin",rows,16*5*8);
 BindingReport("DONE original extern binding\n");
}
BindingReference;
