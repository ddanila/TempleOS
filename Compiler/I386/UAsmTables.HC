//The catalog is a pointer-free export from the pinned original opcode tables.
//Publish only after every allocation and record validation has succeeded.
U0 NativeUAsmTablesInit()
{
  I64 size,i,n,count32,count64;
  U8 *bytes=NULL,*storage=NULL,*record;
  CInst **table32=NULL,**table64=NULL;
  CHashOpcode *opcode;
  CHashExport *allocator;
  U8 *(*allocate)(I64 bytes,CTask *task);
  if(uasm.table_16_32)return;
  try {
    bytes=FileRead("::/Compiler/I386/UAsmTables.DATA",&size);
    if(!bytes || size<40 || sizeof(CInst)!=16)throw('UAsmData');
    count32=bytes(I64 *)[0];count64=bytes(I64 *)[1];
    if(count32<=0 || count64<=0 || count32>4096 || count64>4096)throw('UAsmSize');
    n=count32+count64;
    if(size!=40+n*48)throw('UAsmSize');
    //These final sizes are known. Avoid the public pool's optional larger
    //returned block and power-of-two page reserve for this retained catalog.
    allocator=HashFind("I386CAllocExact",Fs->hash_table,HTT_EXPORT_SYS_SYM);
    if(!allocator || !allocator->val)throw('UAsmMem');
    allocate=allocator->val;
    table32=(*allocate)(count32*sizeof(U8 *),Fs);
    table64=(*allocate)(count64*sizeof(U8 *),Fs);
    storage=(*allocate)(n*(sizeof(CHashOpcode)+32),Fs);
    for(i=0;i<n;i++) {
      record=bytes+40+i*48;
      if(!*record || record[31])throw('UAsmName');
      opcode=storage+i*(sizeof(CHashOpcode)+32);
      opcode->str=opcode(U8 *)+sizeof(CHashOpcode);
      MemCpy(opcode->str,record,32);opcode->inst_entry_cnt=1;
      MemCpy(&opcode->ins,record+32,16);opcode->ins[0].ins_entry_num=0;
      if(i<count32)table32[i]=&opcode->ins;
      else table64[i-count32]=&opcode->ins;
    }
    uasm.table_16_32_entries=count32;uasm.table_64_entries=count64;
    uasm.ins64_arg_mask=bytes(I64 *)[2];
    uasm.signed_arg_mask=bytes(I64 *)[3];
    uasm.mem_arg_mask=bytes(I64 *)[4];
    uasm.table_64=table64;uasm.table_16_32=table32;
  } catch {
    Free(storage);Free(table32);Free(table64);Free(bytes);
  }
  Free(bytes);
}
