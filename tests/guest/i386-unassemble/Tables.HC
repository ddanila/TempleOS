//Run only on the pinned original. The output contains no guest pointers.
U0 UATables()
{
  I64 i,j,n=uasm.table_16_32_entries+uasm.table_64_entries;
  I64 size=40+n*48;
  U8 *bytes=CAlloc(size),*record;
  CInst *ins;CHashOpcode *opcode;
  bytes(I64 *)[0]=uasm.table_16_32_entries;
  bytes(I64 *)[1]=uasm.table_64_entries;
  bytes(I64 *)[2]=uasm.ins64_arg_mask;
  bytes(I64 *)[3]=uasm.signed_arg_mask;
  bytes(I64 *)[4]=uasm.mem_arg_mask;
  if(sizeof(CInst)!=16)throw('InstSize');
  for(i=0;i<n;i++) {
    if(i<uasm.table_16_32_entries)ins=uasm.table_16_32[i];
    else ins=uasm.table_64[i-uasm.table_16_32_entries];
    opcode=ins(U8 *)-ins->ins_entry_num*sizeof(CInst)-offset(CHashOpcode.ins);
    if(StrLen(opcode->str)>=32)throw('InstName');
    record=bytes+40+i*48;StrCpy(record,opcode->str);
    MemCpy(record+32,ins,16);
  }
  UAExport("unassemble-tables.bin",bytes,size);Sleep(1000);Free(bytes);
}
