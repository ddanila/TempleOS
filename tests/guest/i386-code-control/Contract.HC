U0 CCLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 CCCheck()
{
  CCmpCtrl *cc=CmpCtrlNew(StrNew("")),*other=CmpCtrlNew(StrNew(""));
  CIntermediateCode *first,*second;
  CCodeMisc *misc,*more;
  CCodeCtrl *saved;
  CHashClass *type=CAlloc(sizeof(CHashClass));
  I64 mask=0,*result;
  U8 *s;
  type->raw_type=RT_I64;type->size=8;
  COCInit(cc);
  if(cc->coc.coc_head.next==&cc->coc.coc_head.next &&
      cc->coc.coc_head.last==&cc->coc.coc_head.next &&
      !cc->coc.coc_head.ic_code && cc->coc.coc_next_misc==&cc->coc.coc_next_misc)mask|=1;
  cc->last_line_num=37;
  first=ICAdd(cc,0x3000A,0x123456789ABCDEF,type,0x20);
  if(first->ic_code==10 && first->ic_precedence==3 &&
      first->ic_data==0x123456789ABCDEF && first->ic_class==type &&
      first->ic_line==37 && first->ic_flags==0x20 &&
      cc->coc.coc_head.next==first && first->next==&cc->coc.coc_head.next)mask|=2;
  cc->pass_trace=1;cc->lock_cnt=1;
  second=ICAdd(cc,1,0,NULL);
  if((second->ic_flags&(ICF_PASS_TRACE|ICF_LOCK))==(ICF_PASS_TRACE|ICF_LOCK) &&
      Bt(&cc->flags,CCf_PASS_TRACE_PRESENT))mask|=4;
  cc->pass_trace=0;cc->lock_cnt=0;
  misc=COCMiscNew(cc,CMT_STR_CONST);misc->str=StrNew("owned");
  if(misc->type==CMT_STR_CONST && misc->addr==0x7FFFFFFFFFFFFFFF(U8 *) &&
      !misc->flags && !misc->use_cnt && misc->next==&cc->coc.coc_next_misc)mask|=8;
  COCPush(cc);COCInit(cc);ICAdd(cc,1,9,NULL);COCDel(cc,&cc->coc);COCPop(cc);
  if(cc->coc.coc_head.next==first && cc->coc.coc_head.last==second &&
      cc->coc.coc_next_misc==misc && first->ic_data==0x123456789ABCDEF)mask|=16;
  COCPush(cc);COCInit(cc);saved=COCPopNoFree(cc);
  if(saved && saved->coc_head.next==first && cc->coc.coc_head.next==first)mask|=32;
  Free(saved);
  COCInit(other);ICAdd(other,1,21,NULL);more=COCMiscNew(other,CMT_STR_CONST);more->str=StrNew("append");
  saved=MAlloc(sizeof(CCodeCtrl));MemCpy(saved,&other->coc,sizeof(CCodeCtrl));
  COCAppend(cc,saved);COCInit(other);
  if(cc->coc.coc_head.next==first && second->next->ic_data==21 &&
      cc->coc.coc_head.last->next==&cc->coc.coc_head.next &&
      misc->next==more && more->next==&cc->coc.coc_next_misc)mask|=64;
  COCDel(cc,&cc->coc);COCInit(cc);
  if(cc->coc.coc_head.next==&cc->coc.coc_head.next &&
      cc->coc.coc_next_misc==&cc->coc.coc_next_misc && !cc->warning_cnt && !cc->error_cnt)mask|=128;
  if(type->size==8 && type->raw_type==RT_I64)mask|=256;
  Free(type);CmpCtrlDel(other);CmpCtrlDel(cc);
  result=MAlloc(8);*result=mask;
  s=MStrPrint("EXPORT code-control-mask.bin %X 8\n",result);CCLog(s);Free(s);
  CCLog("CODE CONTROL DONE\n");Sleep(1000);
}
CCCheck;
