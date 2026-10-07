//Original x64 CJob is fourteen eight-byte slots. Use raw fixture buffers so
//this oracle does not redeclare the inherited private class in the test task.
U0 Report(U8 *text) { while(*text) OutU8(0xE9,*text++); }
U0 OriginalMacroSerialization()
{
  I64 *head=CAlloc(112),*a,*arrow;
  U8 *text,*line;
  QueInit(head);
  LBts(&sys_semas[SEMA_RECORD_MACRO],0);
  text=SysMacro2Str(head);
  if(*text || Bt(&sys_semas[SEMA_RECORD_MACRO],0)) {
    Report("FAIL original empty macro\n"); return;
  }
  Free(text);
  a=CAlloc(112); a[3]=1; a[5]=2; a[9]=65;
  QueIns(a,head[1]);
  text=SysMacro2Str(head);
  if(StrCmp(text,"\"A\";") || head[0]!=(a+0)(I64) || head[1]!=(a+0)(I64) || a[9]!=65) {
    Report("FAIL original character macro\n"); return;
  }
  Free(text);
  arrow=CAlloc(112); arrow[3]=1; arrow[5]=2; arrow[10]=0xC8;
  QueIns(arrow,head[1]);
  text=SysMacro2Str(head);
  if(StrCmp(text,"\"A\";Msg(0x2,0x0,0xC8);")) {
    Report("FAIL original mixed macro\n"); return;
  }
  line=MStrPrint("EXPORT MacroMixed.HC %X %X\n",text,StrLen(text));
  Report(line); Free(line);
  QueRem(a); Free(a); QueRem(arrow); Free(arrow); Free(head); Free(text);
  Report("PASS original basic macro serialization\n");
}
OriginalMacroSerialization;

U0 OriginalMacroExtended()
{
  I64 *head=CAlloc(112),*key,i;
  U8 *text,*line;
  QueInit(head);
  for(i=0;i<256;i++) {
    key=CAlloc(112); key[3]=1; key[5]=2; key[9]=i; key[10]=i|256;
    QueIns(key,head[1]);
  }
  key=CAlloc(112); key[3]=1; key[5]=3; key[9]=65; key[10]=0x1E;
  QueIns(key,head[1]);
  text=SysMacro2Str(head);
  line=MStrPrint("EXPORT MacroExtended.HC %X %X\n",text,StrLen(text));
  Report(line); Free(line);
  while(head[0]!=(head+0)(I64)) {
    key=head[0]; QueRem(key); Free(key);
  }
  Free(head); Free(text);
  Report("DONE original extended macro serialization\n");
}
OriginalMacroExtended;
