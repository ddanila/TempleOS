//Native-only: all three retained catalog buffers have known final sizes.
U0 UANativeCapacity()
{
  CInst *ins;
  CHashOpcode *opcode;
  I64 rows[6];
  if(!uasm.table_16_32 || !uasm.table_64)throw('UAsmData');
  rows[0]=uasm.table_16_32_entries*sizeof(U8 *);
  rows[1]=MSize(uasm.table_16_32);
  rows[2]=uasm.table_64_entries*sizeof(U8 *);
  rows[3]=MSize(uasm.table_64);
  ins=uasm.table_16_32[0];
  opcode=ins(U8 *)-ins->ins_entry_num*sizeof(CInst)-offset(CHashOpcode.ins);
  rows[4]=(uasm.table_16_32_entries+uasm.table_64_entries)*(sizeof(CHashOpcode)+32);
  rows[5]=MSize(opcode);
  UAExport("unassemble-capacities.bin",rows,sizeof(rows));
  UALog("UNASSEMBLE CAPACITIES DONE\n");Sleep(1000);
}
