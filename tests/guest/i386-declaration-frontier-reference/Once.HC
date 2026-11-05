U0 FrontierReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 FrontierExport(U8 *name,U8 *data,I64 size)
{U8 *s=MStrPrint("EXPORT %s %X %X\n",name,data,size);FrontierReport(s);Free(s);}
I64 FrontierHeader(U8 *name)
{
 CHashFun *fun=HashFind(name,Fs->hash_table,HTT_FUN);
 CHash *undefined=HashFind("UndefinedExtern",Fs->hash_table,HTT_FUN|HTT_EXPORT_SYS_SYM);
 CMemberLst *member;
 U8 *address;
 I64 result=0;
 if(!fun)return 0;
 result=1;
 if(fun->flags&1<<Cf_EXTERN)result|=2;
 if(fun->arg_cnt==2)result|=4;
 member=fun->member_lst_and_root;
 if(member && member->dft_val==7 && member->flags&MLF_DFT_AVAILABLE)result|=8;
 if(member && (member=member->next) && member->flags&MLF_STR_DFT_AVAILABLE &&
     !StrCmp(member->dft_val(U8 *),"AZ"))result|=16;
 if(undefined) {
  result|=32;
  if(undefined->type&HTT_FUN)address=undefined(CHashFun *)->exe_addr;
  else address=undefined(CHashExport *)->val;
  if(fun->exe_addr==address)result|=64;
 }
 return result;
}
U0 DeclarationFrontier()
{
 CDoc *old=Fs->put_doc,*doc;
 U8 *name,*source,*probe,*text,*output;
 I64 mode,kind,exception,value,size,*rows=CAlloc(10*5*8);
 while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
 FrontierReport("ADAM SERVER READY\n");
 for(mode=0;mode<2;mode++)for(kind=0;kind<5;kind++) {
  doc=DocNew;Fs->put_doc=doc;
  switch(kind) {
   case 0:
    name=MStrPrint("FrontierThrow%d",mode);
    source=MStrPrint("{I64 %s(){return 99;}41;throw('Delib',TRUE);}",name);
    probe=MStrPrint("%s;",name);break;
   case 1:
    name=MStrPrint("FrontierParse%d",mode);
    source=MStrPrint("{I64 %s(){return 99;}Unknown frontier_bad;}",name);
    probe=MStrPrint("%s;",name);break;
   case 2:
    name=MStrPrint("FrontierLost%d",mode);
    source=MStrPrint("{U8 *%s=\"bad\";throw('Delib',TRUE);}",name);
    probe=MStrPrint("%s[1];",name);break;
   case 3:
    name=MStrPrint("FrontierHeader%d",mode);
    source=MStrPrint("I64 %s(I64 a=7,U8 *s=\"AZ\"){return frontier_missing;}",name);
    probe=MStrPrint("FrontierHeader(\"%s\");",name);break;
   case 4:
    name=MStrPrint("FrontierHeader%d",mode);
    source=MStrPrint("%s();",name);
    probe=MStrPrint("FrontierHeader(\"%s\");",name);break;
  }
  ExePutS("23;");exception=0;value=0;
  try {value=ExePutS(source,0,mode);}catch{exception=Fs->except_ch;Fs->catch_except=TRUE;}
  rows[(mode*5+kind)*5]=value;rows[(mode*5+kind)*5+1]=exception;
  rows[(mode*5+kind)*5+2]=Fs->answer;
  rows[(mode*5+kind)*5+3]=HashFind(name,Fs->hash_table,HTT_FUN|HTT_GLBL_VAR)!=NULL;
  text=DocSave(doc,&size);output=MStrPrint("frontier-%d.DD",mode*5+kind);
  //The host reads exported addresses only after DONE. Keep payloads alive.
  FrontierExport(output,text,size);Free(output);
  rows[(mode*5+kind)*5+4]=ExePutS(probe);
  //Original failed controls can still borrow their input buffer.
  Fs->put_doc=old;DocDel(doc);Free(name);Free(probe);
 }
 FrontierExport("frontier.bin",rows,10*5*8);
 FrontierReport("DONE original declaration frontier\n");
}
DeclarationFrontier;
