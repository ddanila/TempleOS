U0 BELog(U8 *text){while(*text)OutU8(0xE9,*text++);}
U0 BECheck()
{
  I64 *rows=CAlloc(70*8),*r,i,used,code,errors,recovery,size;U8 *source,*text,*saved,*diagnostics=CAlloc(10*8192),*input;
  CCmpCtrl *first,*last;CDoc *doc,*old_doc;
  source="#include \"T:/Kernel/KernelA.HH\"\n6*7;";
  FileWrite("B:/BEGood.HC",source,StrLen(source));
  Cmp("B:/BEGood.HC",NULL,"B:/BEGood.BIN");
  for(i=0;i<10;i++) {
    if(i==0)source="public I64 NestedBad(){asm {MOV EAX,} return 1;}";
    else if(i==1)source="public I64 NestedPrefix(){asm {MOV EAX,1 MOV EDX,} return 1;}";
    else if(i==2)source="public I64 NestedMissing(){asm {JMP I32 @@missing} return 1;}";
    else if(i==3)source="public I64 NestedRange(){asm {JMP I8 @@far DU8 256 DUP(0x90);@@far:RET} return 1;}";
    else if(i==4)source="public I64 NestedTwo(){asm {MOV EAX,1} asm {MOV EDX,} return 1;}";
    else if(i==5)source="public I64 NestedCall(I64 a){asm {MOV EAX,} return a;}";
    else if(i==6)source="public I64 NestedGoto(){goto missing;asm {MOV EAX,} return 1;}";
    else if(i==7)source="public I64 NestedLabel(){asm {@@done: MOV EAX,1 MOV EDX,} return 1;}";
    else if(i==8)source="public I64 NestedDone(){return 42;} public I64 NestedAfter(){asm {MOV EAX,} return 1;}";
    else source="public I64 NestedExtern(){asm {IMPORT NEST_MISSING; CALL I32 NEST_MISSING MOV EAX,} return 1;}";
    BELog("BE CASE ");OutU8(0xE9,'0'+i);OutU8(0xE9,'\n');
    input=MStrPrint("#include \"T:/Kernel/KernelA.HH\"\n%s",source);
    FileWrite("B:/BEFail.HC",input,StrLen(input));
    r=rows+i*7;used=Fs->data_heap->used_u8s;code=Fs->code_heap->used_u8s;
    first=Fs->next_cc;last=Fs->last_cc;old_doc=Fs->put_doc;doc=DocNew;Fs->put_doc=doc;
    errors=Cmp("B:/BEFail.HC",NULL,"B:/BEFail.BIN");
    r[0]=errors>0;saved=FileRead("B:/BEFail.HC");r[1]=!StrCmp(input,saved);Free(saved);
    r[2]=Fs->next_cc==first && Fs->last_cc==last;
    saved=DocSave(doc,&size);if(size>8191)size=8191;MemCpy(diagnostics+i*8192,saved,size);Free(saved);
    Fs->put_doc=old_doc;DocDel(doc);
    r[3]=Fs->data_heap->used_u8s-used;r[4]=Fs->code_heap->used_u8s-code;
    Free(input);
    recovery=Cmp("B:/BEGood.HC",NULL,"B:/BEGood.BIN");r[5]=recovery==0;r[6]=errors;
  }
  text=MStrPrint("EXPORT buffer-errors.bin %X 230\n",rows);BELog(text);Free(text);
  text=MStrPrint("EXPORT original-diagnostics.bin %X 14000\n",diagnostics);BELog(text);Free(text);
  BELog("DONE buffer errors original\n");
}BECheck;
