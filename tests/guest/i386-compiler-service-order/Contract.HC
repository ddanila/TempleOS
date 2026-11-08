#ifndef PS_REVERSE
#define PS_REVERSE 0
#endif
I64 ps_state[8],ps_trace[12],ps_heap[2];
U0 PSLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 PSExport(U8 *name,U8 *data,I64 bytes)
{U8 *s=MStrPrint("EXPORT %s %X %X\n",name,data,bytes);PSLog(s);Free(s);}
Bool PSLex(I64 *trace)
{
 CCmpCtrl *cc=CmpCtrlNew(StrNew("42 + \"ab\" \"cd\""));I64 size;U8 *joined;Bool okay;
 okay=Lex(cc)==TK_I64;trace[0]=cc->cur_i64;okay=okay && Lex(cc)=='+' && Lex(cc)==TK_STR;
 joined=LexExtStr(cc,&size);trace[1]=size;okay=okay && trace[0]==42 && size==5 && !StrCmp(joined,"abcd") && cc->token==TK_EOF;
 Free(joined);CmpCtrlDel(cc);return okay;
}
Bool PSCompile(I64 *trace)
{
 CCmpCtrl *cc=CmpCtrlNew();CHashClass *type=cmp.internal_types[RT_I64];U8 *code;I64 size,raw;
 COCInit(cc);ICAdd(cc,IC_IMM_I64,6,type);ICAdd(cc,IC_IMM_I64,7,type);ICAdd(cc,IC_MUL,0,type);
 ICAdd(cc,IC_RETURN_VAL,0,NULL);ICAdd(cc,IC_RET,0,NULL);
 code=COCCompile(cc,&size,NULL,&raw);CmpCtrlDel(cc);trace[0]=Call(code);trace[1]=raw;Free(code);
 return trace[0]==42 && raw==RT_I64 && size>0;
}
Bool PSFixup(I64 *trace)
{
 CCmpCtrl *cc=CmpCtrlNew();CAOT *packet=CAlloc(sizeof(CAOT));CAOTCtrl ctrl;Bool okay;
 COCInit(cc);MemSet(&ctrl,0,sizeof(CAOTCtrl));QueInit(packet);QueInit(&packet->next_ie);
 ctrl.rip=17;cc->aotc=&ctrl;
 //JIT consumes its heap-owned packet, including the empty packet.
 CmpFixUpJITAsm(cc,packet);
 packet=CAlloc(sizeof(CAOT));QueInit(packet);QueInit(&packet->next_ie);cc->aot=packet;
 CmpFixUpAOTAsm(cc,packet);
 okay=packet->next_ie==&packet->next_ie && !packet->abss && !ctrl.abss;
 trace[0]=okay;trace[1]=ctrl.rip;okay=okay && ctrl.rip==17 && !cc->error_cnt && !cc->warning_cnt;
 cc->aot=NULL;cc->aotc=NULL;Free(packet);CmpCtrlDel(cc);return okay;
}
U0 PSRun()
{
 CDoc *display=Fs->display_doc,*put=Fs->put_doc;Bool ud=FALSE,up=FALSE;I64 data,code,i;
 if(display)ud=DocLock(display);if(put && put!=display)up=DocLock(put);
 data=Fs->data_heap->used_u8s;code=Fs->code_heap->used_u8s;
 for(i=0;i<2;i++){
#if PS_REVERSE
  ps_state[i*3+2]=PSFixup(ps_trace+i*6+4);ps_state[i*3+1]=PSCompile(ps_trace+i*6+2);ps_state[i*3]=PSLex(ps_trace+i*6);
#else
  ps_state[i*3]=PSLex(ps_trace+i*6);ps_state[i*3+1]=PSCompile(ps_trace+i*6+2);ps_state[i*3+2]=PSFixup(ps_trace+i*6+4);
#endif
 }
 ps_heap[0]=Fs->data_heap->used_u8s-data;ps_heap[1]=Fs->code_heap->used_u8s-code;
 ps_state[6]=!ps_heap[0];ps_state[7]=!ps_heap[1];
 if(up)DocUnlock(put);if(ud)DocUnlock(display);
 PSExport("service-state.bin",ps_state,sizeof(ps_state));PSExport("service-trace.bin",ps_trace,sizeof(ps_trace));PSExport("service-heap.bin",ps_heap,sizeof(ps_heap));
 PSLog("PUBLIC SERVICES DONE\n");Sleep(1000);
}
PSRun;
