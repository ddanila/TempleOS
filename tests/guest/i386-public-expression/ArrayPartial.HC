//Loaded after Errors.HC has published the real normal parser services.
U0 ADCase(I64 *r,U8 *source,I64 kind)
{
  I64 used=Fs->data_heap->used_u8s,code_used=Fs->code_heap->used_u8s,mode=PRS0_TYPECAST;
  CDoc *old_doc=Fs->put_doc,*doc=DocNew;
  CCmpCtrl *cc=CmpCtrlNew(StrNew(source),CCF_TARGET_I386|(1<<CCf_PASS_TRACE_PRESENT)|CCF_TARGET_HOST_CONST,"C:/Probe/Array.HC");
  CHashClass *base=cmp.internal_types[RT_I64],*type=NULL;
  CArrayDim dim;
  Fs->put_doc=doc;Lex(cc);
  try{type=PrsType(cc,&base,&mode,NULL,NULL,NULL,NULL,&dim,0);}
  catch{r[0]=Fs->except_ch;Fs->catch_except=TRUE;}
  r[1]=cc->error_cnt;
  if(!kind || kind==3)r[2]=!dim.next && !dim.cnt && dim.total_cnt==1;
  else if(kind==1)r[2]=dim.next && dim.total_cnt==6 && dim.next->cnt==2 && dim.next->total_cnt==3 && dim.next->next && dim.next->next->cnt==3 && !dim.next->next->next;
  else r[2]=dim.next && dim.total_cnt==-3 && dim.next->cnt==-1 && dim.next->total_cnt==3 && dim.next->next && dim.next->next->cnt==3 && !dim.next->next->next;
  r[3]=(cc->flags&((1<<CCf_PASS_TRACE_PRESENT)|CCF_TARGET_HOST_CONST))==((1<<CCf_PASS_TRACE_PRESENT)|CCF_TARGET_HOST_CONST);
  if(kind)r[7]=type==base;else r[7]=type==NULL;
  if(kind){LinkedLstDel(dim.next);dim.next=NULL;}
  CmpCtrlDel(cc);Fs->put_doc=old_doc;DocDel(doc);TaskWait(adam_task);
  r[4]=Fs->data_heap->used_u8s-used;r[5]=Fs->code_heap->used_u8s-code_used;
  //Observe ownership first, then release an old implementation's partial list.
  if(!kind)LinkedLstDel(dim.next);
  r[6]=EEGood;
}
U0 ADCheck()
{
  I64 *r=CAlloc(92*8);U8 *s;
  EECase(r,"0(I64[2][EEThrow()]);");
  EECase(r+9,"0(I64[2][3][EEThrow()]);");
  EECase(r+18,"0(I64[2);;");
  EECase(r+27,"0(I64[2][-1]);");
  ADCase(r+36,"[2][EEThrow()];",0);
  ADCase(r+44,"[2][3][EEThrow()];",0);
  ADCase(r+52,"[2);",0);
  ADCase(r+60,"[2][-1];",0);
  ADCase(r+68,"[2][3];",1);
  ADCase(r+76,"[][3];",2);
  ADCase(r+84,";",3);
  s=MStrPrint("EXPORT array-partial.bin %X 2E0\n",r);EELog(s);Free(s);
  EELog("ARRAY PARTIAL DONE\n");Sleep(1000);
}
ADCheck;
