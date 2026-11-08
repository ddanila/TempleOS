#ifndef AF_REFERENCE
#define AF_REFERENCE 0
#endif
I64 af_offsets[8]={0,1,2,4,8,12,16,24},af_widths[8]={1,1,2,2,4,4,8,8};
I64 af_masks[5]={0,0xFF,0xFFFF,0xFFFFFFFF,-1};
I64 af_types[16]={2,3,4,5,6,7,8,9,10,11,16,17,18,19,25,20};
I64 af_min[2]={-128,-32768},af_max[2]={127,32767};
I64 af_negative[2],af_heap[5],af_diag_cost;Bool af_diag_ok;
U0 AFLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 AFExport(U8 *name,U8 *data,I64 size)
{U8 *s=MStrPrint("EXPORT %s %X %X\n",name,data,size);AFLog(s);Free(s);}
U0 AFSetup(CAOT *child,CAOT *parent,CAOTCtrl *ctrl,U8 *buf)
{
  MemSet(child,0,sizeof(CAOT));MemSet(parent,0,sizeof(CAOT));MemSet(ctrl,0,sizeof(CAOTCtrl));
  QueInit(child);QueInit(parent);QueInit(&child->next_ie);QueInit(&parent->next_ie);
  child->buf=buf;child->rip=16;child->parent_aot=parent;ctrl->rip=0x10000;
}
CAOTImportExport *AFRecord(CAOT *a,I64 type,I64 rip,U8 *name=NULL,I64 flags=0)
{
  CAOTImportExport *e=CAlloc(sizeof(CAOTImportExport));e->type=type;e->rip=rip;e->flags=flags;e->aot=a;
  if(name)e->str=StrNew(name);e->src_link=StrNew("AFSource,7");QueIns(e,a->last_ie);return e;
}
U0 AFRecordsDel(CAOT *a)
{
  CAOTImportExport *e,*next;
  for(e=a->next_ie;e!=&a->next_ie;e=next){next=e->next;QueRem(e);Free(e->str);Free(e->src_link);Free(e);}
}
I64 AFErrorCost()
{
  CDoc *display=Fs->display_doc;Bool unlock=FALSE;
  if(display)unlock=DocLock(display);
  I64 before=Fs->data_heap->used_u8s,i,after;
  CCmpCtrl *cc=CmpCtrlNew(StrNew("AFProbe"),0,"AFProbe.HC");
  U8 *saved=dbg.fix_file_line;Bool old=Raw(ON);
  dbg.fix_file_line=NULL;af_diag_ok=TRUE;
  for(i=0;i<5;i++){
    try{LexExcept(cc,"Branch out of range at ");af_diag_ok=FALSE;}
    catch{if(Fs->except_ch!='Compiler')af_diag_ok=FALSE;Fs->catch_except=TRUE;}
  }
  if(cc->error_cnt!=5)af_diag_ok=FALSE;
  Raw(old);Free(dbg.fix_file_line);dbg.fix_file_line=saved;CmpCtrlDel(cc);
  after=Fs->data_heap->used_u8s;if(unlock)DocUnlock(display);
  return after-before;
}
I64 AFWarm()
{
  CDoc *display=Fs->display_doc,*put=Fs->put_doc;
  Bool unlock_display=FALSE,unlock_put=FALSE;
  I64 before,after;CCmpCtrl *cc;CAOT child,parent;CAOTCtrl ctrl;
  //A visible document can shed soft-line entries during the loader's yield.
  //Hold its queues stable while measuring allocations owned by this call.
  if(display)unlock_display=DocLock(display);
  if(put && put!=display)unlock_put=DocLock(put);
  before=Fs->data_heap->used_u8s;
  cc=CmpCtrlNew();AFSetup(&child,&parent,&ctrl,NULL);cc->aotc=&ctrl;
  try{CmpFixUpAOTAsm(cc,&child);}
  catch{cc->aotc=NULL;CmpCtrlDel(cc);if(unlock_put)DocUnlock(put);if(unlock_display)DocUnlock(display);}
  cc->aotc=NULL;CmpCtrlDel(cc);after=Fs->data_heap->used_u8s;
  if(unlock_put)DocUnlock(put);if(unlock_display)DocUnlock(display);
  return after-before;
}
U0 AFCheck()
{
  CDoc *locked_display=Fs->display_doc;Bool unlock_display=FALSE;
  if(locked_display)unlock_display=DocLock(locked_display);
  I64 *r=CAlloc(32*8),used=Fs->data_heap->used_u8s,i,j,k,width,actual,expected,base=0x10010;
  I64 seed=0x123456789ABCDEF0,caught,delta,before,cost,flags,n,target,site;
  Bool good=TRUE,accept=TRUE,reject=TRUE,detached=TRUE,names=TRUE,old_raw;
  U8 *buf=CAlloc(0x20000),*text,*saved,*name;
  CAOT child,parent;CAOTCtrl ctrl;CAOTAbsAddr *abs,*next_abs,*tail,*aa[8];
  CAOTImportExport *e,*next,*prefix,*records[16];CCodeMisc *label,*forward,*range;
  CCmpCtrl *cc=CmpCtrlNew(StrNew("AFProbe"),0,"AFProbe.HC");
  CDoc *old_doc=Fs->put_doc,*doc=DocNew;
  Fs->put_doc=doc;flags=cc->flags;COCInit(cc);AFSetup(&child,&parent,&ctrl,buf);cc->aotc=&ctrl;
  MemSet(buf,0xA5,0x20000);tail=CAlloc(sizeof(CAOTAbsAddr));tail->rip=0x777;ctrl.abss=tail;
  for(i=0;i<8;i++){
    aa[i]=CAlloc(sizeof(CAOTAbsAddr));aa[i]->type=i;aa[i]->rip=af_offsets[i];
    if(i)aa[i-1]->next=aa[i];else child.abss=aa[i];
    expected=seed;if(i&1)expected+=base;else expected-=base;
    MemCpy(buf+16+af_offsets[i],&expected,af_widths[i]);
  }
  CmpFixUpAOTAsm(cc,&child);
  for(i=0;i<8;i++){actual=0;MemCpy(&actual,buf+16+af_offsets[i],af_widths[i]);r[i]=actual==(seed&af_masks[Bsf(af_widths[i])+1]);}
  r[8]=TRUE;r[9]=TRUE;abs=ctrl.abss;
  for(i=7;i>=0;i--){if(abs!=aa[i])r[8]=FALSE;if(aa[i]->rip!=af_offsets[i]+base)r[9]=FALSE;abs=aa[i]->next;}
  if(abs!=tail || tail->rip!=0x777)r[8]=FALSE;
  r[10]=TRUE;for(i=0;i<16;i++)if(buf[i]!=0xA5)r[10]=FALSE;for(i=48;i<0x20000;i++)if(buf[i]!=0xA5)r[10]=FALSE;
  r[11]=child.buf==buf && child.next==&child && child.last==&child && ctrl.rip==0x10000 && child.abss==aa[0];
  for(abs=ctrl.abss;abs;abs=next_abs){next_abs=abs->next;Free(abs);}ctrl.abss=NULL;child.abss=NULL;
  AFSetup(&child,&parent,&ctrl,buf);prefix=AFRecord(&parent,IET_MAIN,0x777);
  for(i=0;i<16;i++){
    records[i]=AFRecord(&child,af_types[i],i*8,"AFPending",0x800);
    actual=seed;if(i==8)actual=0;MemCpy(buf+16+i*8,&actual,8);
  }
  CmpFixUpAOTAsm(cc,&child);e=prefix->next;r[12]=parent.next_ie==prefix;r[13]=TRUE;r[14]=TRUE;r[15]=TRUE;
  for(i=0;i<16;i++){
    if(e!=records[i])r[12]=FALSE;
    if(records[i]->aot || records[i]->flags!=0x800 || StrCmp(records[i]->str,"AFPending") || StrCmp(records[i]->src_link,"AFSource,7"))r[13]=FALSE;
    expected=i*8;if(i<14)expected+=base;if(records[i]->rip!=expected)r[14]=FALSE;
    width=0;if(i==2)width=1;if(i==4)width=2;if(i==6)width=4;if(i==8)width=8;
    expected=seed;if(i==8)expected=0;
    if(width){actual=expected-base;MemCpy(&expected,&actual,width);}
    actual=0;MemCpy(&actual,buf+16+i*8,8);if(actual!=expected)r[15]=FALSE;
    e=records[i]->next;
  }
  if(e!=&parent.next_ie || parent.last_ie!=records[15])r[12]=FALSE;
  af_negative[1]=*(buf+80)(I64 *);r[16]=!HashFind("AFPending",Fs->hash_table,HTT_EXPORT_SYS_SYM);
  r[17]=child.next_ie==&child.next_ie && child.last_ie==&child.next_ie;AFRecordsDel(&parent);
  AFSetup(&child,&parent,&ctrl,buf);MemSet(buf,0xA5,256);
  label=COCMiscNew(cc,CMT_GOTO_LABEL);label->str=StrNew("AFLocal");label->flags=CMF_DEFINED;
  forward=COCMiscNew(cc,CMT_ASM_LABEL);forward->str=StrNew("AFForward");forward->flags=CMF_DEFINED;forward->addr=96;forward->use_cnt=1;label->fwd=forward;
  for(i=0;i<10;i++){name=NULL;if(!i)name="AFLocal";records[i]=AFRecord(&child,2+i,32+i*8,name,IEF_GOTO_LABEL);}
  name=records[0]->str;cost=0;for(i=0;i<10;i++)cost+=MSize2(records[i])+MSize2(records[i]->src_link);
#if !AF_REFERENCE
  cost+=MSize2(name);
#endif
  before=Fs->data_heap->used_u8s;CmpFixUpAOTAsm(cc,&child);r[20]=before-Fs->data_heap->used_u8s==cost;
#if AF_REFERENCE
  Free(name);
#endif
  r[18]=TRUE;target=buf+96;
  for(i=0;i<10;i++){
    width=0;if(i>=2)width=1<<((i-2)/2);
    expected=target;site=buf+48+i*8;if(!(i&1))expected-=site+width;
    actual=0;if(width)MemCpy(&actual,buf+48+i*8,width);
    if(width && actual!=(expected&af_masks[Bsf(width)+1]))r[18]=FALSE;
    for(j=width;j<8;j++)if(buf[48+i*8+j]!=0xA5)r[18]=FALSE;
  }
  af_negative[0]=*(buf+112)(I64 *);r[19]=label->use_cnt==1 && forward->use_cnt==1;
  r[20]&=child.next_ie==&child.next_ie && parent.next_ie==&parent.next_ie;
  AFSetup(&child,&parent,&ctrl,buf);MemSet(buf+16,0,32);
  records[0]=AFRecord(&child,IET_REL_I8,0,"AFMissing",IEF_GOTO_LABEL);records[1]=AFRecord(&child,IET_REL_I16,8);
  CmpFixUpAOTAsm(cc,&child);doc->flags|=DOCF_NO_CURSOR;text=DocSave(doc,&n);
  r[21]=StrMatch("Unresolved Reference:AFMissing",text) && !cc->error_cnt;Free(text);DocRst(doc,TRUE);
  r[22]=parent.next_ie==records[0] && parent.last_ie==records[1] && records[0]->rip==base && records[1]->rip==base+8 && !records[0]->aot && !records[1]->aot;
  r[22]&=buf[16]==((-base)&0xFF) && *(buf+24)(U16 *)==((-base)&0xFFFF);AFRecordsDel(&parent);
  range=COCMiscNew(cc,CMT_GOTO_LABEL);range->str=StrNew("AFRange");range->flags=CMF_DEFINED;
  saved=dbg.fix_file_line;dbg.fix_file_line=NULL;old_raw=Raw(ON);
  for(i=0;i<3;i++)for(j=0;j<4;j++){
    if(i==2 && j==3)break;
    width=1<<i;
    if(i<2){delta=af_min[i];if(j==1)delta=af_max[i];if(j==2)delta=af_min[i]-1;if(j==3)delta=af_max[i]+1;}
    else {delta=0x7FFFFFFF;if(j==1)delta++;if(j==2)delta=-32;}
    AFSetup(&child,&parent,&ctrl,buf);e=AFRecord(&child,4+i*2,0x10000,"AFRange",IEF_GOTO_LABEL);
    range->addr=0x10010+width+delta;MemSet(buf+0x10010,0x5A,8);caught=0;name=e->str;
    before=Fs->data_heap->used_u8s;cost=MSize2(e)+MSize2(e->src_link);
#if !AF_REFERENCE
    cost+=MSize2(name);
#endif
    try{CmpFixUpAOTAsm(cc,&child);}catch{caught=Fs->except_ch;Fs->catch_except=TRUE;}
    good=TRUE;if(i<2 && j>=2)good=FALSE;if(i==2 && j==1)good=FALSE;
    if(good){
      actual=0;MemCpy(&actual,buf+0x10010,width);if(caught || actual!=(delta&af_masks[i+1]))accept=FALSE;
      for(k=width;k<8;k++)if(buf[0x10010+k]!=0x5A)accept=FALSE;
      if(before-Fs->data_heap->used_u8s!=cost)names=FALSE;
#if AF_REFERENCE
      Free(name);
#endif
    }else{
      if(caught!='Compiler')reject=FALSE;for(k=0;k<8;k++)if(buf[0x10010+k]!=0x5A)reject=FALSE;
      if(child.next_ie!=&child.next_ie || child.last_ie!=&child.next_ie || parent.next_ie!=&parent.next_ie || e->aot!=&child || e->rip!=0x10000)detached=FALSE;
      Free(e->str);Free(e->src_link);Free(e);
    }
  }
  Raw(old_raw);Free(dbg.fix_file_line);dbg.fix_file_line=saved;
  r[23]=accept;r[24]=reject;r[25]=detached;r[26]=cc->error_cnt==5;r[27]=names;
  r[28]=child.buf==buf && child.next==&child && child.last==&child;r[30]=cc->aotc==&ctrl && ctrl.rip==0x10000 && cc->flags==flags && !cc->aot_depth;
  AFSetup(&child,&parent,&ctrl,buf);CmpFixUpAOTAsm(cc,&child);r[31]=parent.next_ie==&parent.next_ie && child.next_ie==&child.next_ie && !ctrl.abss;
  cc->aotc=NULL;COCDel(cc,&cc->coc);CmpCtrlDel(cc);Fs->put_doc=old_doc;DocDel(doc);Free(buf);
  af_heap[0]=used;af_heap[1]=Fs->data_heap->used_u8s;af_heap[2]=af_diag_cost;
  r[29]=af_diag_ok && af_heap[1]-used==af_diag_cost;
  if(unlock_display)DocUnlock(locked_display);
  AFExport("aot-fixup.bin",r,32*8);AFExport("aot-negative.bin",af_negative,16);AFExport("aot-heap.bin",af_heap,40);
  AFLog("AOT FIXUP DONE\n");Sleep(1000);
}
while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
af_heap[4]=0;af_diag_cost=AFErrorCost;af_heap[3]=AFWarm;AFCheck;
