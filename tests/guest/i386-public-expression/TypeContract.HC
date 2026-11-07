U0 PTLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 PTCheck()
{
  CCmpCtrl *cc;CHashClass *type,*base;CArrayDim dim;
  I64 mode=PRS0_TYPECAST,*r=CAlloc(6*8);U8 *s;
  cc=CmpCtrlNew(StrNew("***;"),CCF_TARGET_I386);Lex(cc);
  base=cmp.internal_types[RT_U8];
  type=PrsType(cc,&base,&mode,NULL,NULL,NULL,NULL,&dim,0);
  r[0]=type->ptr_stars_cnt==3 && type->size==4 && cc->token==';';
  CmpCtrlDel(cc);
  cc=CmpCtrlNew(StrNew("[2+3][4];"),CCF_TARGET_I386);Lex(cc);
  mode=PRS0_TYPECAST;base=cmp.internal_types[RT_I64];
  type=PrsType(cc,&base,&mode,NULL,NULL,NULL,NULL,&dim,0);
  r[1]=type==base && dim.total_cnt==20 && dim.next->cnt==5 && dim.next->total_cnt==4 &&
    dim.next->next->cnt==4 && dim.next->next->total_cnt==1 && cc->token==';';
  LinkedLstDel(dim.next);CmpCtrlDel(cc);
  cc=CmpCtrlNew(StrNew("[];"),CCF_TARGET_I386);Lex(cc);
  mode=PRS0_NULL|PRS1_NULL;base=cmp.internal_types[RT_U8];
  type=PrsType(cc,&base,&mode,NULL,NULL,NULL,NULL,&dim,0);
  r[2]=dim.total_cnt==-1 && dim.next->cnt==-1 && cc->token==';';
  LinkedLstDel(dim.next);CmpCtrlDel(cc);
  cc=CmpCtrlNew(StrNew("5.5(I64);"),CCF_TARGET_I386);Lex(cc);
  r[3]=LexExpressionI64(cc)==0x4016000000000000 && cc->token==';';
  CmpCtrlDel(cc);
  cc=CmpCtrlNew(StrNew("3.75;"),CCF_TARGET_I386);Lex(cc);
  r[4]=LexExpressionI64(cc)==3 && cc->token==';';CmpCtrlDel(cc);
  cc=CmpCtrlNew(StrNew("6*7;"),CCF_TARGET_I386);Lex(cc);
  r[5]=LexExpressionI64(cc)==42 && cc->token==';';CmpCtrlDel(cc);
  s=MStrPrint("EXPORT public-types.bin %X 30\n",r);PTLog(s);Free(s);
  PTLog("PUBLIC TYPES DONE\n");Sleep(1000);
}
PTCheck;
