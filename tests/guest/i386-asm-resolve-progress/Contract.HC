#ifndef AP_X64
#define AP_X64 0
#endif
#ifndef AP_ORIGINAL
#define AP_ORIGINAL 0
#endif
#ifndef AP_REPAIRED
#define AP_REPAIRED 0
#endif
I64 ap_calls,ap_state[28],ap_values[16],ap_heap[6],ap_diag_data,ap_diag_code;
Bool ap_diag_ok;
U0 APLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 APExport(U8 *name,U8 *data,I64 size)
{U8 *s=MStrPrint("EXPORT %s %X %X\n",name,data,size);APLog(s);Free(s);}
U8 *APThunk(I64 value)
{
 U8 *p=MAlloc(32,Fs->code_heap);I64 address=&ap_calls;MemSet(p,0,32);
#if AP_X64
 p[0]=0x48;p[1]=0xB8;MemCpy(p+2,&address,8);p[10]=0xFF;p[11]=0;
 p[12]=0x48;p[13]=0xB8;MemCpy(p+14,&value,8);p[22]=0xC3;
#else
 p[0]=0xFF;p[1]=5;MemCpy(p+2,&address,4);p[6]=0xB8;
 MemCpy(p+7,&value,4);p[11]=0xBA;MemCpy(p+12,(&value)(U8*)+4,4);p[16]=0xC3;
#endif
 return p;
}
CHashExport *APSymbol(U8 *name,I64 flags,CHashTable *table)
{
 CHashExport *h=CAlloc(sizeof(CHashExport));h->str=StrNew(name);
 h->type=HTT_EXPORT_SYS_SYM|flags;HashAdd(h,table);return h;
}
U0 APAdd(CCmpCtrl *cc,CHashExport *h,I64 value,I64 type,I64 rip,Bool global)
{
 CAsmUndefHash *ref=CAlloc(sizeof(CAsmUndefHash));ref->hash=h;
 if(global)AsmUnresolvedAdd(cc,APThunk(value),type,rip,0,NULL,ref,51,FALSE);
 else AsmUnresolvedAdd(cc,APThunk(value),type,rip,0,ref,NULL,51,FALSE);
}
U0 APScenario(Bool global,Bool abandon,I64 *r)
{
 CCmpCtrl *cc=CmpCtrlNew(StrNew("APProbe"),0,"APProbe.HC");
 CLexHashTableContext saved;CAOTCtrl ctrl;CAOT packet;CAOTBinBlk *bin;
 CHashTable *table,*old_local;CHashExport *good,*bad,*pending;
 CAsmUnresolvedRef *prefix,*failed,*tail,*left,*next;CAOTImportExport *ie;
 CDoc *old_doc=Fs->put_doc,*doc=DocNew;U8 *name=NULL,*old_fix=dbg.fix_file_line;
 I64 caught=0,value,kind=IET_IMM_U32,count=0;Bool old_raw=Raw(ON);
 Fs->put_doc=doc;dbg.fix_file_line=NULL;ap_calls=0;
 MemCpy(&saved,&cc->htc,sizeof(CLexHashTableContext));
 MemSet(&ctrl,0,sizeof(CAOTCtrl));MemSet(&packet,0,sizeof(CAOT));QueInit(&packet.next_ie);
 ctrl.bin=CAlloc(sizeof(CAOTBinBlk));MemSet(ctrl.bin->body,0xA5,AOT_BIN_BLK_SIZE);
 ctrl.last_label=StrNew("APRoot");cc->aotc=&ctrl;cc->aot=&packet;
 cc->htc.glbl_hash_table=HashTableNew(16);cc->htc.local_hash_table=HashTableNew(16);
 cc->htc.local_hash_table->next=cc->htc.glbl_hash_table;
 cc->htc.hash_table_lst=old_local=cc->htc.local_hash_table;table=old_local;
 if(global)table=cc->htc.glbl_hash_table;
 good=APSymbol("APGood",0,table);bad=APSymbol("APBad",0,table);pending=APSymbol("APPending",0,table);
 if(global){good->type|=HTF_UNRESOLVED|HTF_IMPORT|HTF_IMM;good->import_name=StrNew("APExternal");good->use_cnt=1;}
 else bad->type|=HTF_UNRESOLVED;
 APAdd(cc,pending,33,IET_IMM_U32,208,global);
 value=22;if(global){value=32768;kind=IET_REL_I16;}
 APAdd(cc,bad,value,kind,204,global);APAdd(cc,good,11,IET_IMM_U32,200,global);
 prefix=ctrl.local_unresolved;if(global)prefix=ctrl.glbl_unresolved;
 failed=prefix->next;tail=failed->next;name=prefix->str;
 try{if(global)AOTGlblsResolve(cc,&packet);else AOTLocalsResolve(cc);}
 catch{caught=Fs->except_ch;Fs->catch_except=TRUE;}
 value=1;if(global)value=2;
 r[0]=caught=='Compiler' && cc->error_cnt==1 && ap_calls==value;
#if AP_REPAIRED
 if(global)r[1]=ctrl.glbl_unresolved==failed;else r[1]=ctrl.local_unresolved==failed;
#else
 if(global)r[1]=ctrl.glbl_unresolved==prefix;else r[1]=ctrl.local_unresolved==prefix;
#endif
 value=0;MemCpy(&value,ctrl.bin->body+200,4);
 r[2]=value==11 && *(ctrl.bin->body+204)(U32*)==0xA5A5A5A5 && *(ctrl.bin->body+208)(U32*)==0xA5A5A5A5;
 r[3]=failed->next==tail && !tail->next && failed->machine_code && failed->asm_undef_hash->hash==bad;
 r[3]&=cc->htc.local_hash_table==old_local && cc->htc.hash_table_lst==old_local && cc->aotc==&ctrl && cc->aot==&packet;
 if(global){
  r[6]=good->ie_lst && !good->ie_lst->next && good->ie_lst->rip==200 && good->ie_lst->aot==&packet;
  r[6]&=packet.next_ie==&packet.next_ie;
 }
#if !AP_REPAIRED
 //Legacy capture repairs the observed dangling head before touching the suffix.
 if(global)ctrl.glbl_unresolved=failed;else ctrl.local_unresolved=failed;
#endif
 if(abandon){
  left=ctrl.local_unresolved;if(global)left=ctrl.glbl_unresolved;
  while(left){
   next=left->next;
   if(global)ctrl.glbl_unresolved=next;else ctrl.local_unresolved=next;
   Free(left->machine_code);LinkedLstDel(left->asm_undef_hash);Free(left->str);Free(left);count++;left=next;
  }
  value=1;if(global)value=2;r[4]=count==2 && ap_calls==value;
  r[5]=*(ctrl.bin->body+204)(U32*)==0xA5A5A5A5 && *(ctrl.bin->body+208)(U32*)==0xA5A5A5A5;
  if(global){
   r[7]=packet.next_ie==&packet.next_ie && good->ie_lst && !good->ie_lst->str;
#if AP_ORIGINAL
   Free(name);
#endif
  }
  count=8;if(global)count=12;
  ap_values[count]=*(ctrl.bin->body+200)(U32*);ap_values[count+1]=*(ctrl.bin->body+204)(U32*);
  ap_values[count+2]=*(ctrl.bin->body+208)(U32*);ap_values[count+3]=ap_calls;
  goto ap_cleanup;
 }
 if(global){Free(failed->machine_code);failed->machine_code=APThunk(-17);}
 else bad->type&=~HTF_UNRESOLVED;
 if(global)AOTGlblsResolve(cc,&packet);else AOTLocalsResolve(cc);
 if(global){
#if AP_ORIGINAL
  r[4]=ap_calls==4 && ctrl.glbl_unresolved==failed;ctrl.glbl_unresolved=NULL;
  Free(name);
#else
  r[4]=ap_calls==4 && !ctrl.glbl_unresolved;
#endif
  r[5]=*(ctrl.bin->body+204)(U16*)==0xFFEF && *(ctrl.bin->body+206)(U16*)==0xA5A5 && *(ctrl.bin->body+208)(U32*)==33;
  ie=packet.next_ie;r[7]=ie!=&packet.next_ie && ie->next==&packet.next_ie && ie->rip==200;
  r[7]&=ie->type==IET_IMM_U32 && ie->aot==&packet && !StrCmp(ie->str,"APExternal") && !good->ie_lst;
  QueRem(ie);Free(ie->str);Free(ie->src_link);Free(ie);
  ap_values[4]=*(ctrl.bin->body+200)(U32*);ap_values[5]=*(ctrl.bin->body+204)(U32*);ap_values[6]=*(ctrl.bin->body+208)(U32*);ap_values[7]=ap_calls;
 }else{
  r[4]=ap_calls==3 && !ctrl.local_unresolved && cc->htc.local_hash_table->mask==15 && cc->htc.local_hash_table->next==cc->htc.glbl_hash_table;
  r[5]=*(ctrl.bin->body+204)(U32*)==22 && *(ctrl.bin->body+208)(U32*)==33;
  ap_values[0]=*(ctrl.bin->body+200)(U32*);ap_values[1]=*(ctrl.bin->body+204)(U32*);ap_values[2]=*(ctrl.bin->body+208)(U32*);ap_values[3]=ap_calls;
 }
ap_cleanup:
 HashTableDel(cc->htc.local_hash_table);HashTableDel(cc->htc.glbl_hash_table);MemCpy(&cc->htc,&saved,sizeof(CLexHashTableContext));
 while(ctrl.bin){bin=ctrl.bin->next;Free(ctrl.bin);ctrl.bin=bin;}Free(ctrl.last_label);
 cc->aotc=NULL;cc->aot=NULL;CmpCtrlDel(cc);Raw(old_raw);Free(dbg.fix_file_line);dbg.fix_file_line=old_fix;
 Fs->put_doc=old_doc;DocDel(doc);
}
U0 APErrorCost()
{
 CDoc *display=Fs->display_doc;Bool unlock=FALSE,old;CCmpCtrl *cc;
 U8 *saved;I64 data,code,i;
 if(display)unlock=DocLock(display);data=Fs->data_heap->used_u8s;code=Fs->code_heap->used_u8s;
 cc=CmpCtrlNew(StrNew("APProbe"),0,"APProbe.HC");saved=dbg.fix_file_line;dbg.fix_file_line=NULL;
 old=Raw(ON);ap_diag_ok=TRUE;
 for(i=0;i<4;i++){try{LexExcept(cc);ap_diag_ok=FALSE;}catch{if(Fs->except_ch!='Compiler')ap_diag_ok=FALSE;Fs->catch_except=TRUE;}}
 if(cc->error_cnt!=4)ap_diag_ok=FALSE;
 Raw(old);Free(dbg.fix_file_line);dbg.fix_file_line=saved;CmpCtrlDel(cc);
 ap_diag_data=Fs->data_heap->used_u8s-data;ap_diag_code=Fs->code_heap->used_u8s-code;
 if(unlock)DocUnlock(display);
}
U0 APCheck()
{
 CDoc *display=Fs->display_doc,*put=Fs->put_doc;Bool ud=FALSE,up=FALSE;I64 data,code;
 if(display)ud=DocLock(display);if(put && put!=display)up=DocLock(put);
 data=Fs->data_heap->used_u8s;code=Fs->code_heap->used_u8s;
 APScenario(FALSE,FALSE,ap_state);APScenario(TRUE,FALSE,ap_state+6);
 APScenario(FALSE,TRUE,ap_state+14);APScenario(TRUE,TRUE,ap_state+20);
 ap_heap[0]=Fs->data_heap->used_u8s-data-ap_diag_data;ap_heap[1]=Fs->code_heap->used_u8s-code-ap_diag_code;
 ap_heap[2]=ap_diag_data;ap_heap[3]=ap_diag_code;ap_heap[4]=ap_diag_ok;ap_heap[5]=AP_REPAIRED;
 if(up)DocUnlock(put);if(ud)DocUnlock(display);
 APExport("progress-state.bin",ap_state,sizeof(ap_state));APExport("progress-values.bin",ap_values,sizeof(ap_values));
 APExport("progress-heap.bin",ap_heap,sizeof(ap_heap));APLog("ASM PROGRESS DONE\n");Sleep(1000);
}
while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
APErrorCost;APCheck;
