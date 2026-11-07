//Native eight-byte argument slots and EDX:EAX integer/soft-float return bits.
//Like the original CallExtStr, the target has a matching fixed argument count.
I64 NativeCallArgs(U8 *address,I64 count,I64 *arguments)
{
  I64 result;
  asm {
    PUSH EBX
    PUSH ESI
    PUSH EDI
    MOV ESI,U32 &arguments[EBP]
    MOV ECX,U32 &count[EBP]
@@10:
    TEST ECX,ECX
    JZ @@20
    DEC ECX
    PUSH U32 +4[ESI+ECX*8]
    PUSH U32 [ESI+ECX*8]
    JMP @@10
@@20:
    MOV EAX,U32 &address[EBP]
    CALL EAX
    MOV U32 &result[EBP],EAX
    MOV U32 &result+4[EBP],EDX
    POP EDI
    POP ESI
    POP EBX
  }
  return result;
}
I64 Call(U8 *machine_code)
{//Original zero-argument Call policy, using the native EDX:EAX return ABI.
  if(!machine_code)return 0;
  return NativeCallArgs(machine_code,0,NULL);
}
I64 CallExtStr(U8 *name,...)
{
  CHash *hook;
  U8 *address;
  if(!(*console_config->compiler->frontend_call_address)(console_config->heap,Fs,name,&address)) {
    hook=HashFind(name,Fs->hash_table,HTT_FUN|HTT_EXPORT_SYS_SYM);
    if(!hook)return 0;
    if(hook->type&HTT_FUN)address=hook(CHashFun *)->exe_addr;
    else address=hook(CHashExport *)->val;
  }
  if(!address)return 0;
  return NativeCallArgs(address,argc,argv);
}
