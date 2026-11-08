I64 po_state[18],po_trace[48],po_heap[2];
I64 po_codes[16]={IC_ADD,IC_SUB,IC_MUL,IC_DIV,IC_MOD,IC_AND,IC_OR,IC_XOR,IC_SHL,IC_SHR,IC_LESS,IC_GREATER_EQU,IC_EQU_EQU,IC_ADD,IC_MUL,IC_DIV};
I64 po_left[16]={6,6,6,-29,-29,0xAA,0xA0,0xAA,3,-32,2,2,7,0x3FF4000000000000,0x3FF4000000000000,0x4014000000000000};
I64 po_right[16]={7,7,7,6,6,15,15,15,5,2,3,3,7,0x4004000000000000,0x4010000000000000,0x4000000000000000};
I64 po_expected[16]={13,-1,42,-4,-5,10,175,165,96,-8,1,0,1,0x400E000000000000,0x4014000000000000,0x4004000000000000};
U0 POLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 POExport(U8 *name,U8 *data,I64 size)
{U8 *s=MStrPrint("EXPORT %s %X %X\n",name,data,size);POLog(s);Free(s);}
U0 POCheck()
{
 CDoc *display=Fs->display_doc,*put=Fs->put_doc;Bool ud=FALSE,up=FALSE,stacks=TRUE;
 I64 data,code,i,pass,type,opcode;CCmpCtrl *cc;CIntermediateCode *ret,*producer,*answer;
 CPrsStk *stack;CHashClass *cls;
 if(display)ud=DocLock(display);if(put && put!=display)up=DocLock(put);
 data=Fs->data_heap->used_u8s;code=Fs->code_heap->used_u8s;
 for(i=0;i<16;i++){
  cc=CmpCtrlNew();COCInit(cc);type=RT_I64;opcode=IC_IMM_I64;
  if(i>=13){type=RT_F64;opcode=IC_IMM_F64;}
  cls=cmp.internal_types[type];
  ICAdd(cc,opcode,po_left[i],cls);ICAdd(cc,opcode,po_right[i],cls);
  ICAdd(cc,po_codes[i],0,cls);ret=ICAdd(cc,IC_RETURN_VAL,0,NULL);ICAdd(cc,IC_RET,0,NULL);
  stack=NULL;
  for(pass=0;pass<3;pass++){
   cc->pass=pass;answer=OptPass012(cc);
   if(!pass)stack=cc->ps;else if(cc->ps!=stack)stacks=FALSE;
   if(!answer || !cc->ps || MSize2(cc->ps)<sizeof(CPrsStk))stacks=FALSE;
  }
  producer=ret->t.arg1_tree;
  po_state[i]=producer && producer->ic_code==opcode && producer->ic_data==po_expected[i] && producer->ic_class->raw_type==type;
  po_state[i]&=!cc->error_cnt && !cc->warning_cnt && cc->pass==2;
  po_trace[i*3]=producer->ic_code;po_trace[i*3+1]=producer->ic_class->raw_type;po_trace[i*3+2]=producer->ic_data;
  COCDel(cc,&cc->coc);CmpCtrlDel(cc);
 }
 po_state[16]=stacks;
 po_state[17]=cmp.internal_types[RT_I64]==HashFind("I64i",Fs->hash_table,HTT_INTERNAL_TYPE) && cmp.internal_types[RT_F64]==HashFind("F64",Fs->hash_table,HTT_INTERNAL_TYPE);
 po_heap[0]=Fs->data_heap->used_u8s-data;po_heap[1]=Fs->code_heap->used_u8s-code;
 if(up)DocUnlock(put);if(ud)DocUnlock(display);
 POExport("optimizer-state.bin",po_state,sizeof(po_state));POExport("optimizer-trace.bin",po_trace,sizeof(po_trace));POExport("optimizer-heap.bin",po_heap,sizeof(po_heap));
 POLog("PUBLIC OPTIMIZER DONE\n");Sleep(1000);
}
POCheck;
