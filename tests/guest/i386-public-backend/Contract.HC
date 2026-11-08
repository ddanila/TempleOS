#ifndef BC_ORIGINAL
#define BC_ORIGINAL 0
#endif
I64 bc_state[48],bc_trace[44],bc_heap[2];
I64 bc_codes[16]={IC_ADD,IC_SUB,IC_MUL,IC_DIV,IC_MOD,IC_AND,IC_OR,IC_XOR,IC_SHL,IC_SHR,IC_LESS,IC_GREATER_EQU,IC_EQU_EQU,IC_ADD,IC_MUL,IC_DIV};
I64 bc_left[16]={6,6,6,-29,-29,0xAA,0xA0,0xAA,3,-32,2,2,7,0x3FF4000000000000,0x3FF4000000000000,0x4014000000000000};
I64 bc_right[16]={7,7,7,6,6,15,15,15,5,2,3,3,7,0x4004000000000000,0x4010000000000000,0x4000000000000000};
I64 bc_expected[16]={13,-1,42,-4,-5,10,175,165,96,-8,1,0,1,0x400E000000000000,0x4014000000000000,0x4004000000000000};
U0 BCLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 BCExport(U8 *name,U8 *data,I64 size)
{U8 *s=MStrPrint("EXPORT %s %X %X\n",name,data,size);BCLog(s);Free(s);}
I64 BCTarget(I64 value){return value+37;}
I64 BCLateTarget(I64 value){return value+42;}
U0 BCCheck()
{
 CDoc *display=Fs->display_doc,*put=Fs->put_doc;Bool ud=FALSE,up=FALSE,debug_ok=TRUE,consumed=TRUE,context_ok=TRUE;
 I64 data,code,i,j,type,opcode,size,actual,base;CCmpCtrl *cc;U8 *bytes;CDbgInfo *dbg;
 CHashClass *cls;CAOT packet;CAOTCtrl ctrl;CHashFun function,*target;
 CAOTImportExport *relocation;CExternUsage *usage;I64 offset,patch,site;Bool metadata_ok;
 if(display)ud=DocLock(display);if(put && put!=display)up=DocLock(put);
 data=Fs->data_heap->used_u8s;code=Fs->code_heap->used_u8s;
 for(i=0;i<16;i++){
  cc=CmpCtrlNew();COCInit(cc);type=RT_I64;opcode=IC_IMM_I64;
  if(i>=13){type=RT_F64;opcode=IC_IMM_F64;}
  cls=cmp.internal_types[type];cc->min_line=10;cc->max_line=12;cc->last_line_num=10;
  ICAdd(cc,opcode,bc_left[i],cls);cc->last_line_num=11;ICAdd(cc,opcode,bc_right[i],cls);
  cc->last_line_num=12;ICAdd(cc,bc_codes[i],0,cls);ICAdd(cc,IC_RETURN_VAL,0,NULL);ICAdd(cc,IC_RET,0,NULL);
  bytes=COCCompile(cc,&size,&dbg,&type);base=bytes;
  if(!bytes || size<1 || !dbg || dbg->min_line!=10 || dbg->max_line!=12)debug_ok=FALSE;
  else{
   if(dbg->body[0]!=base || dbg->body[3]!=base+size)debug_ok=FALSE;
   for(j=0;j<3;j++)if(dbg->body[j] && !(base<=dbg->body[j]<=base+size))debug_ok=FALSE;
  }
#if BC_ORIGINAL
  //The original frees nodes but leaves the active-list head stale.
  if(cc->coc.coc_head.next==&cc->coc.coc_head.next)consumed=FALSE;
#else
  if(cc->coc.coc_head.next!=&cc->coc.coc_head.next || cc->coc.coc_next_misc!=&cc->coc.coc_next_misc)consumed=FALSE;
#endif
  if(cc->aot || cc->aotc || cc->htc.fun)context_ok=FALSE;
  CmpCtrlDel(cc);actual=Call(bytes);
  bc_state[i]=actual==bc_expected[i];bc_trace[i*2]=actual;bc_trace[i*2+1]=type;
  if(i<13){if(type!=RT_I64)bc_state[i]=FALSE;}else if(type!=RT_F64)bc_state[i]=FALSE;
  Free(bytes);Free(dbg);
 }
 for(i=0;i<2;i++){
  cc=CmpCtrlNew();COCInit(cc);MemSet(&packet,0,sizeof(CAOT));MemSet(&ctrl,0,sizeof(CAOTCtrl));
  QueInit(&packet);QueInit(&packet.next_ie);ctrl.rip=0x1000;cc->aot=&packet;cc->aotc=&ctrl;cc->flags|=CCF_AOT_COMPILE;
  j=2;type=RT_I64;opcode=IC_IMM_I64;if(i){j=13;type=RT_F64;opcode=IC_IMM_F64;}
  cls=cmp.internal_types[type];cc->min_line=10;cc->max_line=12;cc->last_line_num=10;
  ICAdd(cc,opcode,bc_left[j],cls);cc->last_line_num=11;ICAdd(cc,opcode,bc_right[j],cls);
  cc->last_line_num=12;ICAdd(cc,bc_codes[j],0,cls);ICAdd(cc,IC_RETURN_VAL,0,NULL);ICAdd(cc,IC_RET,0,NULL);
  bytes=COCCompile(cc,&size,&dbg,&type);
  bc_state[21+i*4]=dbg && dbg->min_line==10 && dbg->max_line==12 && dbg->body[0]==0x1000 && dbg->body[3]==0x1000+size;
  bc_state[22+i*4]=cc->aot==&packet && cc->aotc==&ctrl && !cc->htc.fun;
  bc_state[23+i*4]=ctrl.rip==0x1000 && !ctrl.abss && !ctrl.heap_glbls && packet.next_ie==&packet.next_ie;
  cc->aot=NULL;cc->aotc=NULL;CmpCtrlDel(cc);actual=Call(bytes);
  bc_state[20+i*4]=bytes && size>0 && actual==bc_expected[j];
  if(!i){if(type!=RT_I64)bc_state[20]=FALSE;}else if(type!=RT_F64)bc_state[24]=FALSE;
  bc_trace[32+i*2]=actual;bc_trace[33+i*2]=type;
  LinkedLstDel(ctrl.abss);LinkedLstDel(ctrl.heap_glbls);Free(bytes);Free(dbg);
 }
 //Exercise caller-owned symbol records and relocation publication after IR deletion.
 target=HashFind("BCTarget",Fs->hash_table,HTT_FUN);
 for(i=0;i<4;i++){
  MemCpy(&function,target,sizeof(CHashFun));function.ie_lst=NULL;function.ext_lst=NULL;
  if(i){Bts(&function.flags,Cf_EXTERN);if(i==2)function.type|=HTF_IMPORT;}
  cc=CmpCtrlNew();COCInit(cc);MemSet(&packet,0,sizeof(CAOT));MemSet(&ctrl,0,sizeof(CAOTCtrl));
  QueInit(&packet);QueInit(&packet.next_ie);ctrl.rip=0x1000;
  if(i>=2){cc->aot=&packet;cc->aotc=&ctrl;cc->flags|=CCF_AOT_COMPILE;}
  cls=cmp.internal_types[RT_I64];cc->min_line=cc->max_line=cc->last_line_num=1;
  ICAdd(cc,IC_CALL_START,&function,NULL);ICAdd(cc,IC_IMM_I64,5,cls,ICF_PUSH_RES);
  opcode=IC_CALL;patch=function.exe_addr;
  if(i==1){opcode=IC_CALL_INDIRECT2;patch=&function.exe_addr;}
  if(i==2){opcode=IC_CALL_IMPORT;patch=&function;}
  if(i==3){opcode=IC_CALL_EXTERN;patch=&function;}
  ICAdd(cc,opcode,patch,cls);ICAdd(cc,IC_CALL_END,&function,cls);
  ICAdd(cc,IC_RETURN_VAL,0,NULL);ICAdd(cc,IC_RET,0,NULL);
  bytes=COCCompile(cc,&size,NULL,&type);
  if(i>=2)bc_state[29+i*5]=cc->aot==&packet && cc->aotc==&ctrl && !cc->htc.fun;
  else bc_state[29+i*5]=!cc->aot && !cc->aotc && !cc->htc.fun;
  cc->aot=NULL;cc->aotc=NULL;CmpCtrlDel(cc);metadata_ok=TRUE;
  if(i==1)function.exe_addr=&BCLateTarget;
  if(i==2){
#if BC_ORIGINAL
   relocation=function.ie_lst;
#else
   relocation=packet.next_ie;if(relocation==&packet.next_ie)relocation=NULL;
#endif
   metadata_ok=relocation && !function.ext_lst;
   if(relocation){
    offset=relocation->rip-0x1000;patch=function.exe_addr;site=bytes+offset+4;
    if(relocation->type==IET_REL_I32){patch-=site;MemCpy(bytes+offset,&patch,4);}
    else if(relocation->type==IET_IMM_I64)MemCpy(bytes+offset,&patch,8);
    else metadata_ok=FALSE;
#if BC_ORIGINAL
    metadata_ok=metadata_ok && !relocation->next;function.ie_lst=NULL;
#else
    metadata_ok=metadata_ok && relocation->next==&packet.next_ie && relocation->aot==&packet && !function.ie_lst && !StrCmp(relocation->str,function.str);
    QueRem(relocation);
#endif
    Free(relocation->str);Free(relocation);
   }
  }
  if(i==3){
   usage=function.ext_lst;metadata_ok=usage && !usage->next && !function.ie_lst && packet.next_ie==&packet.next_ie;
   if(usage){offset=usage->rip-0x1000;patch=function.exe_addr;site=bytes+offset+4;patch-=site;MemCpy(bytes+offset,&patch,4);Free(usage);function.ext_lst=NULL;}
  }
  actual=Call(bytes);bc_trace[36+i*2]=actual;bc_trace[37+i*2]=type;
  patch=42;if(i==1)patch=47;bc_state[28+i*5]=actual==patch && type==RT_I64 && size>0;
  bc_state[30+i*5]=metadata_ok;
  bc_state[31+i*5]=!function.ie_lst && !function.ext_lst && packet.next_ie==&packet.next_ie;
  bc_state[32+i*5]=!ctrl.abss && !ctrl.heap_glbls && ctrl.rip==0x1000;
  Free(bytes);
 }
 bc_state[16]=debug_ok;bc_state[17]=consumed;bc_state[18]=context_ok;
 bc_heap[0]=Fs->data_heap->used_u8s-data;bc_heap[1]=Fs->code_heap->used_u8s-code;
 bc_state[19]=!bc_heap[0] && !bc_heap[1];
 if(up)DocUnlock(put);if(ud)DocUnlock(display);
 BCExport("backend-state.bin",bc_state,sizeof(bc_state));BCExport("backend-trace.bin",bc_trace,sizeof(bc_trace));BCExport("backend-heap.bin",bc_heap,sizeof(bc_heap));
 BCLog("PUBLIC BACKEND DONE\n");Sleep(1000);
}
BCCheck;
