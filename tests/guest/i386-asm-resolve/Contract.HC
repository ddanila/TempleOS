#ifndef AR_X64
#define AR_X64 0
#endif
I64 ar_calls,ar_results[32],ar_values[8];
I64 ar_widths[8]={1,1,2,2,4,4,8,8};
U0 ARLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 ARExport(U8 *name,U8 *data,I64 size)
{U8 *s=MStrPrint("EXPORT %s %X %X\n",name,data,size);ARLog(s);Free(s);}
U8 *ARThunk(I64 value)
{
 U8 *p=MAlloc(32,Fs->code_heap);I64 address=&ar_calls;
 MemSet(p,0,32);
#if AR_X64
 p[0]=0x48;p[1]=0xB8;MemCpy(p+2,&address,8);p[10]=0xFF;p[11]=0;
 p[12]=0x48;p[13]=0xB8;MemCpy(p+14,&value,8);p[22]=0xC3;
#else
 p[0]=0xFF;p[1]=5;MemCpy(p+2,&address,4);p[6]=0xB8;
 MemCpy(p+7,&value,4);p[11]=0xBA;MemCpy(p+12,(&value)(U8*)+4,4);p[16]=0xC3;
#endif
 return p;
}
U0 ARCheck()
{
 CCmpCtrl *cc=CmpCtrlNew();CAOTCtrl ctrl;CAOT packet;
 CAsmUnresolvedRef u,*first,*second;CAsmUndefHash *ref,*ref2;
 CHashExport *h;CLexHashTableContext saved;
 CAOTBinBlk *blk;I64 i,j,v,expect,width,actual,seed=0x123456789ABCDEF0;
 Bool bytes=TRUE,guards=TRUE;U8 *code,*name1,*name2;
 CAOTImportExport *ie,*ie2;CHashFun *fun;CExternUsage *ext;
 ar_calls=0;
 MemCpy(&saved,&cc->htc,sizeof(CLexHashTableContext));
 MemSet(&ctrl,0,sizeof(CAOTCtrl));MemSet(&packet,0,sizeof(CAOT));
 QueInit(&packet.next_ie);cc->aotc=&ctrl;cc->aot=&packet;
 ctrl.last_label=StrNew("ARRoot");ctrl.bin=CAlloc(sizeof(CAOTBinBlk));
 MemSet(ctrl.bin->body,0xA5,AOT_BIN_BLK_SIZE);
 for(i=0;i<8;i++){
  MemSet(&u,0,sizeof(CAsmUnresolvedRef));width=ar_widths[i];
  u.type=IET_REL_I8+i;u.rip=16+i*16;u.rel_rip=0x10000;
  v=seed;if(!(i&1))v=u.rel_rip-17;
  code=ARThunk(v);u.machine_code=code;
  AsmResolve(cc,&u,"ARWidth",FALSE);Free(code);
  expect=v;if(!(i&1))expect-=u.rel_rip;
  actual=0;MemCpy(&actual,ctrl.bin->body+u.rip,width);ar_values[i]=actual;
  for(j=0;j<width;j++)if(ctrl.bin->body[u.rip+j]!=expect.u8[j])bytes=FALSE;
  if(ctrl.bin->body[u.rip-1]!=0xA5 || ctrl.bin->body[u.rip+width]!=0xA5)guards=FALSE;
 }
 ar_results[0]=bytes;ar_results[1]=guards;ar_results[2]=ar_calls==8;
 ar_results[3]=ctrl.rip==0;
 //An immediate spanning the 64 KiB storage boundary must allocate the next block.
 u.type=IET_IMM_U16;u.rip=AOT_BIN_BLK_SIZE-1;u.machine_code=ARThunk(0x7654);
 AsmResolve(cc,&u,"ARCross",FALSE);Free(u.machine_code);
 ar_results[4]=ctrl.bin->body[AOT_BIN_BLK_SIZE-1]==0x54 && ctrl.bin->next->body[0]==0x76;
 ar_results[5]=ctrl.num_bin_U8s==AOT_BIN_BLK_SIZE+1;
 //Undefined expressions retain the addend and attach a relocation to the hash.
 h=CAlloc(sizeof(CHashExport));h->str=StrNew("ARImport");
 h->type=HTT_EXPORT_SYS_SYM|HTF_UNRESOLVED|HTF_IMPORT|HTF_IMM;
 ref=CAlloc(sizeof(CAsmUndefHash));ref->hash=h;
 u.type=IET_REL_I32;u.rip=160;u.rel_rip=0x10000;u.asm_undef_hash=ref;
 u.machine_code=ARThunk(0x12345678);AsmResolve(cc,&u,"ARImport",TRUE);
 ar_results[6]=h->ie_lst && h->ie_lst->type==u.type && h->ie_lst->rip==160 && h->ie_lst->aot==&packet;
 actual=0;MemCpy(&actual,ctrl.bin->body+160,4);ar_results[7]=actual==0x12345678;
 ar_results[8]=ar_calls==10;Free(u.machine_code);Free(h->ie_lst);h->ie_lst=NULL;Free(ref);
 //The constructor must defer execution and route local references ahead of globals.
 cc->htc.glbl_hash_table=HashTableNew(16);cc->htc.local_hash_table=HashTableNew(16);
 cc->htc.local_hash_table->next=cc->htc.glbl_hash_table;cc->htc.hash_table_lst=cc->htc.local_hash_table;
 h->type=HTT_EXPORT_SYS_SYM;HashAdd(h,cc->htc.local_hash_table);
 ref=CAlloc(sizeof(CAsmUndefHash));ref->hash=h;ref2=CAlloc(sizeof(CAsmUndefHash));ref2->hash=h;
 AsmUnresolvedAdd(cc,ARThunk(77),IET_IMM_U32,176,0x200,ref,ref2,31,TRUE);
 first=ctrl.local_unresolved;
 ar_results[9]=first && first->asm_undef_hash==ref && !ctrl.glbl_unresolved;
 ar_results[10]=first->type==IET_IMM_U32 && first->rip==176 && first->rel_rip==0x200 && first->aot==&packet;
 ar_results[11]=first->line_num==31 && first->U8_avail && !first->imm_flag && !first->str;
 Free(ref2);ref=CAlloc(sizeof(CAsmUndefHash));ref->hash=h;
 AsmUnresolvedAdd(cc,ARThunk(88),IET_IMM_U32,180,0,ref,NULL,32,FALSE);
 second=ctrl.local_unresolved;ar_results[12]=second->next==first && ar_calls==10;
 AOTLocalsResolve(cc);
 ar_results[13]=!ctrl.local_unresolved && ar_calls==12;
 actual=0;MemCpy(&actual,ctrl.bin->body+176,4);ar_results[14]=actual==77;
 actual=0;MemCpy(&actual,ctrl.bin->body+180,4);ar_results[15]=actual==88;
 ar_results[16]=cc->htc.hash_table_lst==cc->htc.local_hash_table && cc->htc.local_hash_table->mask==15;
 ar_results[17]=cc->htc.local_hash_table->next==cc->htc.glbl_hash_table;
 ar_results[18]=!HashFind("ARImport",cc->htc.local_hash_table,HTT_EXPORT_SYS_SYM);
 //Two deferred uses of one imported symbol emit metadata in source order.
 h=CAlloc(sizeof(CHashExport));h->str=StrNew("ARGlobal");h->import_name=StrNew("ARExternal");
 h->type=HTT_EXPORT_SYS_SYM|HTF_UNRESOLVED|HTF_IMPORT|HTF_IMM;h->use_cnt=1;
 HashAdd(h,cc->htc.glbl_hash_table);
 ref=CAlloc(sizeof(CAsmUndefHash));ref->hash=h;
 AsmUnresolvedAdd(cc,ARThunk(0x1357),IET_REL_I32,200,0x1000,NULL,ref,40,FALSE);
 first=ctrl.glbl_unresolved;name1=first->str;
 ar_results[20]=first->imm_flag && !StrCmp(first->str,"ARGlobal") && first->str!=h->str;
 ref=CAlloc(sizeof(CAsmUndefHash));ref->hash=h;
 AsmUnresolvedAdd(cc,ARThunk(0x2468),IET_IMM_U32,204,0,NULL,ref,41,FALSE);
 second=ctrl.glbl_unresolved;name2=second->str;
 ar_results[21]=second->next==first && ar_calls==12;
 AOTGlblsResolve(cc,&packet);ie=packet.next_ie;ie2=ie->next;
 ar_results[22]=ie!=&packet.next_ie && ie2!=&packet.next_ie && ie2->next==&packet.next_ie;
 ar_results[23]=ie->rip==200 && ie2->rip==204 && ie->type==IET_REL_I32 && ie2->type==IET_IMM_U32;
 ar_results[24]=!StrCmp(ie->str,"ARExternal") && !ie2->str && !h->ie_lst;
 ar_results[25]=ie->aot==&packet && ie2->aot==&packet && ar_calls==14;
 actual=0;MemCpy(&actual,ctrl.bin->body+200,4);ar_results[26]=actual==0x1357;
 actual=0;MemCpy(&actual,ctrl.bin->body+204,4);ar_results[27]=actual==0x2468;
 //Original leaves the consumed list head and constructor-owned names behind.
 ar_results[28]=ctrl.glbl_unresolved==second;ctrl.glbl_unresolved=NULL;
 Free(name1);Free(name2);
 QueRem(ie);QueRem(ie2);Free(ie->str);Free(ie);Free(ie2);
 //A defined function resolves external call sites and emits an export record.
 fun=CAlloc(sizeof(CHashFun));fun->str=StrNew("ARFunction");
 fun->type=HTT_FUN|HTF_RESOLVE|HTF_EXPORT;fun->exe_addr=0x180;
 ext=CAlloc(sizeof(CExternUsage));ext->rip=220;fun->ext_lst=ext;
 HashAdd(fun,cc->htc.glbl_hash_table);AOTGlblsResolve(cc,&packet);
 actual=0;MemCpy(&actual,ctrl.bin->body+220,4);ar_results[29]=actual==0x180-224;
 ie=packet.next_ie;ar_results[30]=ie!=&packet.next_ie && ie->type==IET_REL32_EXPORT && ie->rip==0x180 && !StrCmp(ie->str,"ARFunction");
 ar_results[31]=fun->ext_lst==ext;fun->ext_lst=NULL;fun->exe_addr=NULL;
 QueRem(ie);Free(ie->str);Free(ie->src_link);Free(ie);
 HashTableDel(cc->htc.local_hash_table);HashTableDel(cc->htc.glbl_hash_table);MemCpy(&cc->htc,&saved,sizeof(CLexHashTableContext));
 while(ctrl.bin){blk=ctrl.bin->next;Free(ctrl.bin);ctrl.bin=blk;}
 Free(ctrl.last_label);cc->aotc=NULL;cc->aot=NULL;CmpCtrlDel(cc);ar_results[19]=ar_calls==14;
 ARExport("asm-resolve.bin",ar_results,sizeof(ar_results));
 ARExport("asm-values.bin",ar_values,sizeof(ar_values));ARLog("ASM RESOLVE DONE\n");Sleep(1000);
}
ARCheck;
