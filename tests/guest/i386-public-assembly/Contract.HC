#include "/Kernel/I386/PublicAssembly.HH"
#include "/Kernel/I386/PublicCompilerContext.HH"
#include "/Kernel/I386/PublicFormat.HH"
#include "/Compiler/PrsCompileFlags.HH"
U0 PALog(U8 *s){while(*s)OutU8(0xE9,*s++);}
Bool pa_state=TRUE;
CAOT *PAJoin(U8 *source,Bool aot=TRUE)
{
  I64 flags=CCF_TARGET_I386;CCmpCtrl *cc;CAOT *result;
  CLexHashTableContext saved;
  if(aot)flags|=CCF_AOT_COMPILE;
  cc=CmpCtrlNew(StrNew(source),flags,"C:/Probe/Assembly.HC");
  MemCpy(&saved,&cc->htc,sizeof(saved));
  PALog("PA JOIN ");PALog(source);PALog("\n");
  result=CmpJoin(cc,CMPF_LEX_FIRST);PALog("PA JOIN returned\n");
  if(cc->error_cnt || cc->warning_cnt || cc->aot || cc->aotc || cc->aot_depth ||
      MemCmp(&saved,&cc->htc,sizeof(saved)))pa_state=FALSE;
  CmpCtrlDel(cc);return result;
}
U0 PADel(CAOT *aot)
{
  CAOTImportExport *record;
  if(!aot)return;
  while(aot->next_ie!=&aot->next_ie){record=aot->next_ie;QueRem(record);Free(record->str);Free(record);}
  LinkedLstDel(aot->abss);Free(aot->buf);Free(aot);
}
I64 PAFunction(U8 *name,U8 *body,I64 argument)
{
  CHashTable *table=HashTableNew(32);CHashFun *fun;
  CCmpCtrl *cc=CmpCtrlNew(StrNew(body),CCF_TARGET_I386,"C:/Probe/Inline.HC");
  I64 (*invoke)(I64 value),result;
  table->next=Fs->hash_table;
  cc->htc.glbl_hash_table=cc->htc.local_hash_table=cc->htc.hash_table_lst=table;
  PALog("PA FUNCTION ");PALog(name);PALog("\n");
  Lex(cc);PrsFun(cc,cmp.internal_types[RT_I64],StrNew(name),0);
  PALog("PA FUNCTION parsed\n");
  if(cc->error_cnt || cc->warning_cnt || cc->token!=TK_EOF)pa_state=FALSE;
  CmpCtrlDel(cc);fun=HashFind(name,table,HTT_FUN);invoke=fun->exe_addr;
  result=(*invoke)(argument);Free(fun->exe_addr);HashTableDel(table);return result;
}
I64 PARecover()
{
  CCmpCtrl *cc=CmpCtrlNew(StrNew("6*7"),CCF_TARGET_I386,"C:/Probe/Recovery.HC");
  I64 value;
  Lex(cc);value=LexExpressionI64(cc);
  if(cc->error_cnt || cc->warning_cnt || cc->token!=TK_EOF)value=-1;
  CmpCtrlDel(cc);return value;
}
U0 PACheck()
{
  I64 *r=CAlloc(24*8),used,code_used,warning_size=0;U8 *s,*warning,*warning_copy=CAlloc(4096);CAOT *aot;CHashOpcode *opcode;CHash *type_entry;
  CDoc *held_doc=Fs->put_doc,*warning_doc;
  CHashClass *integer=cmp.internal_types[RT_I64],*pointer=cmp.internal_types[RT_PTR];
  r[0]=!native_jit_support.assembly && !native_jit_support.join && !native_jit_support.asm_stage;
  aot=PAJoin("asm {DU8 0x12,0x34;DU16 0x5678;DU32 0x9ABCDEF0;DU64 0x1122334455667788;}");
  r[1]=aot && aot->aot_U8s==16 && !MemCmp(aot->buf,"\x12\x34\x78\x56\xF0\xDE\xBC\x9A\x88\x77\x66\x55\x44\x33\x22\x11",16);PADel(aot);
  used=Fs->data_heap->used_u8s;code_used=Fs->code_heap->used_u8s;
  aot=PAJoin("asm {MOV EAX,42 MOV EDX,0 RET}",FALSE);
  r[2]=aot && aot->aot_U8s==11 && !MemCmp(aot->buf,"\xB8\x2A\x00\x00\x00\xBA\x00\x00\x00\x00\xC3",11);
  if(aot)r[3]=Call(aot->buf);PADel(aot);
  warning_doc=DocNew;Fs->put_doc=warning_doc;
  aot=PAJoin("asm {JMP I32 @@done DU8 3 DUP(0x90);@@done: MOV EAX,42 MOV EDX,0 RET}",FALSE);
  r[4]=aot && aot->aot_U8s==19 && aot->buf[0]==0xE9 && *(aot->buf+1)(I32 *)==3;
  if(aot)r[5]=Call(aot->buf);PADel(aot);
  Fs->put_doc=held_doc;warning=DocSave(warning_doc,&warning_size);
  if(0<warning_size<=4096) {
    MemCpy(warning_copy,warning,warning_size);
    r[23]=StrMatch("could use I8 displacement",warning) && StrMatch("@@done",warning);
  } else warning_size=0;
  Free(warning);DocDel(warning_doc);
  aot=PAJoin("asm {IMPORT PAExternal;CALL PAExternal RET}");
  r[6]=aot && aot->aot_U8s==6 && aot->buf[0]==0xE8 && aot->buf[5]==0xC3 &&
    aot->next_ie!=&aot->next_ie && aot->next_ie->next==&aot->next_ie &&
    aot->next_ie->type==IET_REL_I32 && aot->next_ie->rip==1 && !StrCmp(aot->next_ie->str,"PAExternal");PADel(aot);
  r[7]=PAFunction("PALoop","(I64 a){asm {MOV ECX,5 XOR EAX,EAX @@10: ADD EAX,ECX DEC ECX JNZ @@10 MOV U32 &a[EBP],EAX}return a;}",0);
  r[8]=PAFunction("PABranch","(I64 a){asm {JMP done}a=99;done:return a;}",17);
  r[9]=PAFunction("PAEntry","(I64 a){goto inside;asm {MOV U32 &a[EBP],99 inside:MOV U32 &a[EBP],17}return a;}",0);
  r[10]=PAFunction("PACall","(I64 a){asm {MOV EAX,5 CALL @@10 JMP @@20 @@10: ADD EAX,7 RET @@20: MOV U32 &a[EBP],EAX}return a;}",0);
  r[11]=PAFunction("PALocal","(I64 a){I64 value=a;asm {MOV U32 &value[EBP],23}return value;}",0);
  r[12]=PAFunction("PAStatement","(I64 a){MOV U32 &a[EBP],29;return a;}",0);
  r[13]=PAFunction("PAPrefix","(I64 a){if(a)return 99;asm {MOV U32 &a[EBP],41 @@10:ADD U32 &a[EBP],1}return a;}",0);
  r[22]=PAFunction("PADead","(I64 a){if(0){asm {MOV U32 &a[EBP],99}}return a;}",42);
  r[19]=PARecover;
  r[14]=Fs->data_heap->used_u8s-used;r[15]=Fs->code_heap->used_u8s-code_used;
  r[16]=integer==cmp.internal_types[RT_I64] && pointer==cmp.internal_types[RT_PTR];
  r[17]=native_jit_support.assembly && native_jit_support.join && native_jit_support.asm_stage==4;
  r[18]=pa_state;
  opcode=HashFind("MOV",cmp.asm_hash,HTT_OPCODE);r[20]=opcode->inst_entry_cnt;
  type_entry=HashFind("U8",cmp.asm_hash,HTG_TYPE_MASK);r[21]=ToBool(type_entry->type&(HTT_CLASS|HTT_INTERNAL_TYPE));
  s=MStrPrint("EXPORT public-assembly.bin %X C0\n",r);PALog(s);Free(s);
  s=MStrPrint("EXPORT assembly-warning.bin %X %X\n",warning_copy,warning_size);PALog(s);Free(s);
  PALog("PUBLIC ASSEMBLY DONE\n");Sleep(1000);
}
PACheck;
