//Native-only: all three retained catalog buffers have known final sizes.
U0 UANativeCapacity()
{
  CInst *ins;
  CHashOpcode *opcode,*first;
  I64 rows[6],i,count;
  U8 *name;
  if(!uasm.table_16_32 || !uasm.table_64)throw('UAsmData');
  rows[0]=uasm.table_16_32_entries*sizeof(U8 *);
  rows[1]=MSize(uasm.table_16_32);
  rows[2]=uasm.table_64_entries*sizeof(U8 *);
  rows[3]=MSize(uasm.table_64);
  count=uasm.table_16_32_entries+uasm.table_64_entries;
  first=uasm.table_16_32[0](U8 *)-offset(CHashOpcode.ins);
  name=first(U8 *)+count*sizeof(CHashOpcode);
  for(i=0;i<count;i++) {
    if(i<uasm.table_16_32_entries)ins=uasm.table_16_32[i];
    else ins=uasm.table_64[i-uasm.table_16_32_entries];
    opcode=ins(U8 *)-offset(CHashOpcode.ins);
    if(ins->ins_entry_num || opcode!=first(U8 *)+i*sizeof(CHashOpcode) ||
        opcode->str!=name)throw('UAsmData');
    name+=StrLen(name)+1;
  }
  rows[4]=name-first(U8 *);
  rows[5]=MSize(first);
  UAExport("unassemble-capacities.bin",rows,sizeof(rows));
  UALog("UNASSEMBLE CAPACITIES DONE\n");Sleep(1000);
}
