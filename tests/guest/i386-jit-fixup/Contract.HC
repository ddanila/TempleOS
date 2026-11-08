I64 jf_offsets[8]={0,1,2,4,8,12,16,24},jf_widths[8]={1,1,2,2,4,4,8,8};
I64 jf_positions[4]={0,2,4,8};
I64 jf_masks[4]={0xFF,0xFFFF,0xFFFFFFFF,-1};
I64 jf_minimum[3]={-128,-32768,-0x80000000},jf_maximum[3]={127,32767,0x7FFFFFFF};
I64 jf_extypes[4]={16,17,18,19};
I64 jf_trace_base,jf_heap_metrics[9];
U0 JFLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
CAOT *JFPacket(CAOT *head,U8 *buf,I64 rip=16)
{
  CAOT *a=CAlloc(sizeof(CAOT));QueIns(a,head->last);QueInit(&a->next_ie);
  a->buf=buf;a->rip=rip;return a;
}
CAOTImportExport *JFRecord(CAOT *a,I64 type,I64 rip,U8 *name=NULL,I64 flags=0)
{
  CAOTImportExport *e=CAlloc(sizeof(CAOTImportExport));e->type=type;e->rip=rip;e->flags=flags;
  if(name)e->str=StrNew(name);QueIns(e,a->last_ie);return e;
}
CHashExport *JFExport(U8 *name,I64 value)
{
  CHashExport *h=CAlloc(sizeof(CHashExport));h->str=StrNew(name);h->type=HTT_EXPORT_SYS_SYM|HTF_IMM;
  h->val=value;HashAdd(h,Fs->hash_table);return h;
}
Bool jf_baseline_ok;
I64 JFErrorCost()
{
  I64 before=Fs->data_heap->used_u8s,i;
  CCmpCtrl *cc=CmpCtrlNew(StrNew("JitFixupProbe"),0,"JitFixupProbe.HC");
  U8 *saved=dbg.fix_file_line;Bool old=Raw(ON);
  dbg.fix_file_line=NULL;jf_baseline_ok=TRUE;
  for(i=0;i<6;i++) {
    try{LexExcept(cc,"Branch out of range at ");jf_baseline_ok=FALSE;}
    catch{if(Fs->except_ch!='Compiler')jf_baseline_ok=FALSE;Fs->catch_except=TRUE;}
  }
  if(cc->error_cnt!=6)jf_baseline_ok=FALSE;
  Raw(old);Free(dbg.fix_file_line);dbg.fix_file_line=saved;CmpCtrlDel(cc);
  return Fs->data_heap->used_u8s-before;
}
I64 JFWarm()
{
  I64 before=Fs->data_heap->used_u8s;
  CCmpCtrl *cc=CmpCtrlNew();CAOT head,*a;
  MemSet(&head,0,sizeof(head));QueInit(&head);a=JFPacket(&head,NULL,0);
  cc->aot_depth=1;CmpFixUpJITAsm(cc,a);CmpCtrlDel(cc);
  if(head.next!=&head || head.last!=&head)throw('JFWarm');
  return Fs->data_heap->used_u8s-before;
}
U0 JFCheck()
{
  I64 *r=CAlloc(40*8),used=Fs->data_heap->used_u8s,i,j,k,width,base,value,actual,delta,site,n;
  I64 expected[4],caught;
  Bool valid=TRUE,rejected=TRUE,owned=TRUE,old_raw;
  U8 *buf=CAlloc(256),*s,*text,*saved_fix,*cursor,stream[32];
  CHashTable *old_table=Fs->hash_table,*table=HashTableNew(32);
  CDoc *old_doc=Fs->put_doc,*doc=DocNew;
  CCmpCtrl *cc=CmpCtrlNew(StrNew("JitFixupProbe"),0,"JitFixupProbe.HC");
  CAOT head,*a;CAOTAbsAddr *abs;CAOTImportExport *e;
  CHashExport *h;CHashImport *pending;CHashFun *fun;CHashGlblVar *var;
  CCodeMisc *label,*forward;
  table->next=old_table;Fs->hash_table=table;Fs->put_doc=doc;
  MemSet(&head,0,sizeof(head));QueInit(&head);MemSet(buf,0xA5,256);
  cc->flags|=0x10000000000;cc->aot_depth=1;Btr(&cc->opts,OPTf_TRACE);COCInit(cc);
  base=buf+16;a=JFPacket(&head,buf);
  for(i=0;i<8;i++){
    value=0x123456789ABCDEF0;
    if(i&1)value+=base;else value-=base;
    MemCpy(buf+16+jf_offsets[i],&value,jf_widths[i]);
    abs=CAlloc(sizeof(CAOTAbsAddr));abs->type=i;abs->rip=jf_offsets[i];abs->next=a->abss;a->abss=abs;
  }
  CmpFixUpJITAsm(cc,a);
  for(i=0;i<8;i++){actual=0;MemCpy(&actual,buf+16+jf_offsets[i],jf_widths[i]);r[i]=actual==(0x123456789ABCDEF0&jf_masks[i/2]);}
  r[8]=head.next==&head && head.last==&head;r[9]=TRUE;for(i=0;i<16;i++)if(buf[i]!=0xA5)r[9]=FALSE;
  // Publish all four export forms and resolve a pre-existing deferred import.
  cursor=stream;*cursor++=11;*cursor(U32 *)++=224;StrCpy(cursor,"JFExport3");cursor+=StrLen(cursor)+1;*cursor=0;
  cursor=stream;LoadOneImport(&cursor,buf,4);pending=HashSingleTableFind("JFExport3",table,HTT_IMPORT_SYS_SYM);
  a=JFPacket(&head,buf);expected[0]=base+7;expected[1]=0x12345678;expected[2]=base+9;expected[3]=0x123456789ABCDEF0;
  for(i=0;i<4;i++){
    s=MStrPrint("JFExport%d",i);e=JFRecord(a,jf_extypes[i],7+i,s);Free(s);
    if(i==1)e->rip=expected[1];if(i==3)e->rip=expected[3];
    e->src_link=StrNew("JFSource");
  }
  CmpFixUpJITAsm(cc,a);
  for(i=0;i<4;i++){
    s=MStrPrint("JFExport%d",i);h=HashFind(s,table,HTT_EXPORT_SYS_SYM);Free(s);
    r[10+i]=h && h->val==expected[i] && h->type==(HTT_EXPORT_SYS_SYM|HTF_IMM) && !StrCmp(h->src_link,"JFSource");
  }
  // Relative export 0 uses offset 7, relative export 2 uses offset 9.
  r[14]=pending && pending->type==HTT_INVALID && !HashSingleTableFind("JFExport3",table,HTT_IMPORT_SYS_SYM);
  r[15]=*(&buf[224])(I64 *)==expected[3];
  JFExport("JFForwardTarget",buf+112);JFExport("JFBackwardTarget",buf);JFExport("JFImmediate",0x123456789ABCDEF0);
  a=JFPacket(&head,buf);
  for(i=0;i<4;i++){s=NULL;if(!i)s="JFForwardTarget";JFRecord(a,4+i*2,jf_positions[i],s);}
  for(i=0;i<4;i++){s=NULL;if(!i)s="JFBackwardTarget";JFRecord(a,4+i*2,16+jf_positions[i],s);}
  for(i=0;i<4;i++){s=NULL;if(!i)s="JFImmediate";JFRecord(a,5+i*2,32+jf_positions[i],s);}
  CmpFixUpJITAsm(cc,a);
  for(i=0;i<4;i++){
    width=1<<i;actual=0;MemCpy(&actual,buf+16+jf_positions[i],width);r[16+i]=actual==((96-jf_positions[i]-width)&jf_masks[i]);
    actual=0;MemCpy(&actual,buf+32+jf_positions[i],width);r[20+i]=actual==((-32-jf_positions[i]-width)&jf_masks[i]);
    actual=0;MemCpy(&actual,buf+48+jf_positions[i],width);r[24+i]=actual==(0x123456789ABCDEF0&jf_masks[i]);
  }
  label=COCMiscNew(cc,CMT_GOTO_LABEL);label->str=StrNew("JFLabel");label->flags=CMF_DEFINED;
  forward=COCMiscNew(cc,CMT_ASM_LABEL);forward->str=StrNew("JFForward");forward->flags=CMF_DEFINED;forward->use_cnt=1;forward->addr=80;label->fwd=forward;
  fun=CAlloc(sizeof(CHashFun));fun->str=StrNew("JFFunction");fun->type=HTT_FUN;fun->exe_addr=buf+160;HashAdd(fun,table);
  var=CAlloc(sizeof(CHashGlblVar));var->str=StrNew("JFVariable");var->type=HTT_GLBL_VAR;var->data_addr=buf+176;HashAdd(var,table);
  a=JFPacket(&head,buf);JFRecord(a,6,48,"JFLabel",IEF_GOTO_LABEL);
  buf[68]=0xAA;buf[72]=0xBB;JFRecord(a,5,52,"JFAbsent",IEF_GOTO_LABEL);JFRecord(a,5,56,"JFMissing");
  JFRecord(a,10,64,"JFFunction");JFRecord(a,10,72,"JFVariable");CmpFixUpJITAsm(cc,a);
  r[28]=*(&buf[64])(U16 *)==14 && label->use_cnt==1 && forward->use_cnt==1;
  r[29]=*(&buf[80])(I64 *)==72;r[30]=*(&buf[88])(I64 *)==80;
  doc->flags|=DOCF_NO_CURSOR;text=DocSave(doc,&n);
  r[31]=buf[68]==0xAA && buf[72]==0xBB && StrMatch("Unresolved Reference:JFAbsent",text) && StrMatch("Unresolved Reference:JFMissing",text) && !cc->error_cnt;
  Free(text);DocRst(doc,TRUE);
  jf_heap_metrics[7]=Fs->data_heap->used_u8s;
  h=JFExport("JFRange",0);saved_fix=dbg.fix_file_line;dbg.fix_file_line=NULL;old_raw=Raw(ON);
  for(i=0;i<3;i++)for(j=0;j<4;j++){
    width=1<<i;delta=jf_minimum[i];if(j==1)delta=jf_maximum[i];if(j==2)delta=jf_minimum[i]-1;if(j==3)delta=jf_maximum[i]+1;
    site=buf+24;h->val=site+width+delta;MemSet(buf+24,0x5A,8);
    a=JFPacket(&head,buf);e=JFRecord(a,4+i*2,8,"JFRange");caught=0;
    try{CmpFixUpJITAsm(cc,a);}catch{caught=Fs->except_ch;Fs->catch_except=TRUE;}
    if(j<2){
      actual=0;MemCpy(&actual,buf+24,width);if(caught || actual!=(delta&jf_masks[i]))valid=FALSE;
      for(k=width;k<8;k++)if(buf[24+k]!=0x5A)valid=FALSE;
    }else{
      if(caught!='Compiler')rejected=FALSE;
      for(k=0;k<8;k++)if(buf[24+k]!=0x5A)rejected=FALSE;
      if(head.next!=a || a->next_ie!=e || e->next!=&a->next_ie)owned=FALSE;
      QueRem(e);Free(e->str);Free(e->src_link);Free(e);QueRem(a);Free(a);
    }
  }
  Raw(old_raw);Free(dbg.fix_file_line);dbg.fix_file_line=saved_fix;
  jf_heap_metrics[7]=Fs->data_heap->used_u8s-jf_heap_metrics[7];
  r[32]=valid;r[33]=rejected;r[34]=cc->error_cnt==6;r[35]=owned;
  r[36]=TRUE;for(i=0;i<16;i++)if(buf[i]!=0xA5)r[36]=FALSE;
  jf_heap_metrics[0]=used;jf_heap_metrics[1]=Fs->data_heap->used_u8s;
  JFLog("JF TRACE START\n");
  // Exercise the actual system disassembler through the trace path.
  buf[192]=0x90;buf[193]=0xC3;jf_trace_base=buf+192;
  a=JFPacket(&head,buf,192);a->aot_U8s=2;cc->aot_depth=0;Bts(&cc->opts,OPTf_TRACE);CmpFixUpJITAsm(cc,a);
  jf_heap_metrics[2]=Fs->data_heap->used_u8s;JFLog("JF TRACE COMPLETE\n");
  r[37]=head.next==&head && head.last==&head;
  doc->flags|=DOCF_NO_CURSOR;text=DocSave(doc,&n);r[38]=StrMatch("XCHG",text) && StrMatch("RET",text);
  Fs->put_doc=old_doc;DocDel(doc);COCDel(cc,&cc->coc);CmpCtrlDel(cc);
  fun->exe_addr=NULL;var->data_addr=NULL;Fs->hash_table=old_table;table->next=NULL;HashTableDel(table);Free(buf);
  jf_heap_metrics[3]=Fs->data_heap->used_u8s-used;jf_heap_metrics[4]=MSize2(text);jf_heap_metrics[5]=jf_heap_metrics[3]-jf_heap_metrics[4];
  r[39]=jf_baseline_ok && jf_heap_metrics[5]==jf_heap_metrics[6];
  s=MStrPrint("EXPORT jit-fixup.bin %X 140\n",r);JFLog(s);Free(s);
  s=MStrPrint("EXPORT jit-trace.txt %X %X\n",text,n);JFLog(s);Free(s);
  s=MStrPrint("EXPORT jit-trace-base.bin %X 8\n",&jf_trace_base);JFLog(s);Free(s);
  s=MStrPrint("EXPORT jit-heap.bin %X 48\n",jf_heap_metrics);JFLog(s);Free(s);
  JFLog("JIT FIXUP DONE\n");Sleep(1000);
}
while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
jf_heap_metrics[6]=JFErrorCost;
jf_heap_metrics[8]=JFWarm;
JFCheck;
