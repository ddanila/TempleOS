U0 UALog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 UAExport(U8 *name,U8 *bytes,I64 size)
{U8 *s=MStrPrint("EXPORT %s %X %X\n",name,bytes,size);UALog(s);Free(s);}
U0 UACheck()
{
  CHash *h=HashFind("Ui",Fs->hash_table,HTT_FUN|HTT_EXPORT_SYS_SYM);
  U0 (*unassemble)(U8 *buf,U8 **ip,I64 bits,I64 *destination,Bool just_ins);
  U8 code[192];
  U8 buf[1024],*ip,*name;I64 i,destination,rows[24],addresses[12];
  Bool raw;
  if(!h){UALog("UNASSEMBLE UNAVAILABLE\n");return;}
  if(h->type&HTT_FUN)unassemble=h(CHashFun *)->exe_addr;else unassemble=h(CHashExport *)->val;
  if(!unassemble){UALog("UNASSEMBLE UNAVAILABLE\n");return;}
  MemSet(code,0,sizeof(code));
  code[0]=0x90;code[16]=0xC3;code[32]=0xCC;
  MemCpy(code+48,"\xB8\x78\x56\x34\x12",5);
  MemCpy(code+64,"\x89\xD8",2);
  MemCpy(code+80,"\x8B\x44\x8D\x10",4);
  MemCpy(code+96,"\x66\xB8\x34\x12",4);
  code[112]=0x40;code[128]=0x50;
  MemCpy(code+144,"\x83\xC0\x07",3);
  code[160]=0xE9;code[176]=0xEB;code[177]=0xFE;
  raw=Raw(ON);
  for(i=0;i<12;i++) {
    ip=(code+i*16);destination=-1;
    (*unassemble)(buf,&ip,32,&destination,TRUE);
    addresses[i]=(code+i*16)(I64);
    rows[i*2]=ip-(code+i*16);rows[i*2+1]=destination;
    if(i>=10)rows[i*2+1]=destination-(code+i*16);
    name=MStrPrint("unassemble-%d.txt",i);UAExport(name,buf,StrLen(buf));Free(name);Sleep(1000);
  }
  Raw(raw);UAExport("unassemble-state.bin",rows,sizeof(rows));
  UAExport("unassemble-addresses.bin",addresses,sizeof(addresses));
  UALog("UNASSEMBLE DONE\n");Sleep(1000);
}
