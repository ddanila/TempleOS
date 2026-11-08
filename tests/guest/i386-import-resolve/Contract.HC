I64 ir_negative[4];
U0 IRLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U8 *IRRecord(U8 *p,I64 type,I64 offset,U8 *name)
{*p++=type;*p(U32 *)++=offset;StrCpy(p,name);return p+StrLen(name)+1;}
CHashExport *IRExport(U8 *name,I64 value)
{
  CHashExport *h=CAlloc(sizeof(CHashExport));h->str=StrNew(name);
  h->type=HTT_EXPORT_SYS_SYM|HTF_IMM;h->val=value;HashAdd(h,Fs->hash_table);return h;
}
U0 IRCheck()
{
  I64 *r=CAlloc(24*8),used=Fs->data_heap->used_u8s,i;
  CHashTable *old=Fs->hash_table,*table=HashTableNew(32);
  U8 *bytes=CAlloc(128),*records=CAlloc(512),*p,*next_group,*end,*cursor;
  CHashImport *pending,*other;
  CHashFun *fun;
  CHashGlblVar *var;
  CHashExport *h;
  U8 *s;
  table->next=old;Fs->hash_table=table;
  p=IRRecord(records,4,0,"IRRelative");p=IRRecord(p,6,2,"");
  p=IRRecord(p,8,4,"");p=IRRecord(p,10,8,"");
  next_group=p;p=IRRecord(p,5,16,"IRImmediate");p=IRRecord(p,7,18,"");
  p=IRRecord(p,9,20,"");p=IRRecord(p,11,24,"");end=p;*p=0;
  cursor=records;LoadOneImport(&cursor,bytes,4);
  pending=HashSingleTableFind("IRRelative",table,HTT_IMPORT_SYS_SYM);
  r[0]=pending && pending->module_base==bytes && pending->module_header_entry==records;
  r[1]=cursor==next_group;
  r[2]=TRUE;for(i=0;i<128;i++)if(bytes[i])r[2]=FALSE;
  LoadOneImport(&cursor,bytes,4);other=HashSingleTableFind("IRImmediate",table,HTT_IMPORT_SYS_SYM);
  r[3]=other && cursor==end && other->module_header_entry==next_group;
  IRExport("IRRelative",bytes+96);SysSymImportsResolve("IRRelative",0);
  r[4]=pending->type==HTT_INVALID && !HashSingleTableFind("IRRelative",table,HTT_IMPORT_SYS_SYM);
  r[5]=bytes[0]==95 && *(&bytes[2])(U16 *)==92 && *(&bytes[4])(U32 *)==88 && *(&bytes[8])(I64 *)==80;
  r[6]=other->type==HTT_IMPORT_SYS_SYM && !bytes[16];
  IRExport("IRImmediate",0x123456789ABCDEF0);SysSymImportsResolve("IRImmediate",0);
  r[7]=other->type==HTT_INVALID && !HashSingleTableFind("IRImmediate",table,HTT_IMPORT_SYS_SYM);
  r[8]=bytes[16]==0xF0 && *(&bytes[18])(U16 *)==0xDEF0;
  r[9]=*(&bytes[20])(U32 *)==0x9ABCDEF0 && *(&bytes[24])(I64 *)==0x123456789ABCDEF0;
  h=HashFind("IRRelative",table,HTT_EXPORT_SYS_SYM);h->val=bytes-16;
  cursor=records;LoadOneImport(&cursor,bytes,0);
  ir_negative[0]=bytes[0];ir_negative[1]=*(&bytes[2])(U16 *);ir_negative[2]=*(&bytes[4])(U32 *);ir_negative[3]=*(&bytes[8])(I64 *);
  r[10]=cursor==next_group && bytes[0]==0xEF && *(&bytes[2])(U16 *)==0xFFEC && *(&bytes[4])(U32 *)==0xFFFFFFE8 && *(&bytes[8])(I64 *)==-32;
  LoadOneImport(&cursor,bytes,0);r[11]=cursor==end;
  cursor=end;LoadOneImport(&cursor,bytes,0);r[12]=cursor==end;
  // Fictitious relocation kinds consume their records without touching storage.
  p=IRRecord(records,2,40,"IRRelative");p=IRRecord(p,3,41,"");*p=0;
  bytes[40]=0xAA;bytes[41]=0xBB;cursor=records;LoadOneImport(&cursor,bytes,0);
  r[13]=cursor==p && bytes[40]==0xAA && bytes[41]==0xBB;
  // Function and global-variable symbols use their address fields, not val.
  fun=CAlloc(sizeof(CHashFun));fun->str=StrNew("IRFunction");fun->type=HTT_FUN;fun->exe_addr=bytes+100;HashAdd(fun,table);
  p=IRRecord(records,10,48,"IRFunction");*p=0;cursor=records;LoadOneImport(&cursor,bytes,0);
  r[14]=*(&bytes[48])(I64 *)==44;
  var=CAlloc(sizeof(CHashGlblVar));var->str=StrNew("IRVariable");var->type=HTT_GLBL_VAR;var->data_addr=bytes+104;HashAdd(var,table);
  p=IRRecord(records,10,56,"IRVariable");*p=0;cursor=records;LoadOneImport(&cursor,bytes,0);
  r[15]=*(&bytes[56])(I64 *)==40;
  // Two pending groups with one name are both retired when its export appears.
  p=IRRecord(records,9,64,"IRRepeated");*p=0;cursor=records;LoadOneImport(&cursor,bytes,4);
  cursor=records;LoadOneImport(&cursor,bytes,4);
  pending=HashSingleTableFind("IRRepeated",table,HTT_IMPORT_SYS_SYM,1);
  other=HashSingleTableFind("IRRepeated",table,HTT_IMPORT_SYS_SYM,2);
  r[16]=pending && other && pending!=other;
  IRExport("IRRepeated",0x87654321);SysSymImportsResolve("IRRepeated",0);
  r[17]=pending->type==HTT_INVALID && other->type==HTT_INVALID && *(&bytes[64])(U32 *)==0x87654321;
  r[18]=!HashSingleTableFind("IRRepeated",table,HTT_IMPORT_SYS_SYM);
  SysSymImportsResolve("IRRepeated",0);r[19]=*(&bytes[64])(U32 *)==0x87654321;
  // A parent-table export resolves, while pending imports are local to this table.
  Fs->hash_table=old;h=IRExport("IRParent",0x1122334455667788);Fs->hash_table=table;
  fun->exe_addr=NULL;var->data_addr=NULL;HashRemDel(fun,table);HashRemDel(var,table);
  cursor=records;p=IRRecord(records,11,72,"IRParent");*p=0;LoadOneImport(&cursor,bytes,0);
  r[20]=*(&bytes[72])(I64 *)==h->val;
  HashRemDel(h,old);Fs->hash_table=old;table->next=NULL;HashTableDel(table);Free(records);Free(bytes);
  r[21]=Fs->hash_table==old;r[22]=Fs->data_heap->used_u8s==used;r[23]=sizeof(I64)==8;
  s=MStrPrint("EXPORT import-resolve.bin %X C0\n",r);IRLog(s);Free(s);
  s=MStrPrint("EXPORT import-negative.bin %X 20\n",ir_negative);IRLog(s);Free(s);
  IRLog("IMPORT RESOLVE DONE\n");Sleep(1000);
}
IRCheck;
