U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 ExportState(U8 *name,U8 *data,I64 size)
{U8 *s=MStrPrint("EXPORT %s %X %X\n",name,data,size);Report(s);Free(s);}
U0 DeclarationStateOracle()
{
 CDoc *old=Fs->put_doc,*doc;
 U8 *source,*a,*b,*saved,*name;
 I64 kind,size,*record=CAlloc(8*4*8);
 while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
 Report("ADAM SERVER READY\n");
 for(kind=0;kind<8;kind++) {
  doc=DocNew;Fs->put_doc=doc;
  switch(kind) {
   case 0:source="extern class OriginalOpaque;class OriginalHolder{OriginalOpaque *p;I64 value;};OriginalHolder oh;oh.p=0;oh.value=42;";
    a="sizeof(OriginalOpaque);";b="oh.value;";break;
   case 1:source="class OriginalOpaque{I64 value;};Unknown opaque_bad;";
    a="sizeof(OriginalOpaque);";b="oh.value;";break;
   case 2:source="class OriginalOpaque{I64 value;};OriginalOpaque original_item;";
    a="sizeof(OriginalOpaque);";b="oh.p=&original_item;original_item.value=42;oh.p->value;";break;
   case 3:source="U8 *original_lost=\"bad\";Unknown lost_bad;";
    a="StrCmp(original_lost,\"bad\")==0;";b="original_lost[1];";break;
   case 4:source="U8 *original_lost=\"ok\";";
    a="StrCmp(original_lost,\"ok\")==0;";b="original_lost[1];";break;
   case 5:source="I64 OriginalCount(){return 1;}I64 OriginalCaller(){return OriginalCount;}";
    a="OriginalCount;";b="OriginalCaller;";break;
   case 6:source="I64 OriginalCount(){return 2;}";
    a="OriginalCount;";b="OriginalCaller;";break;
   case 7:source="I64 OriginalGood(){return 99;}I64 OriginalBad(){return original_missing;}";
    a="OriginalGood;";b="HashFind(\"OriginalBad\",Fs->hash_table,HTT_FUN)!=NULL;";break;
  }
  record[kind*4]=ExePutS(source);
  record[kind*4+1]=Fs->answer;
  record[kind*4+2]=ExePutS(a);record[kind*4+3]=ExePutS(b);
  saved=DocSave(doc,&size);name=MStrPrint("state-%d.DD",kind);ExportState(name,saved,size);Free(name);
  Fs->put_doc=old;DocDel(doc);
 }
 ExportState("declarations.bin",record,8*4*8);
 Report("DONE original declaration state\n");
}
DeclarationStateOracle;
