//Executable public APIs: calls, mutable storage, target pointers and heap recovery.
I64 px_integer=9;
F64 px_float;
px_float(I64)=0x3FF4000000000000;
U8 px_bytes[3]={97,98,0};
I64 PXAdd(I64 a,I64 b){return a+b;}
I64 PXSecond(U8 *s){return s[1];}
U0 PXLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 PXCase(I64 *state,I64 *value,U8 *source)
{
  CCmpCtrl *cc=CmpCtrlNew(StrNew(source),0,"C:/Probe/Runtime.HC");
  try {
    Lex(cc);*value=LexExpression(cc);
    *state=cc->token==';' && !cc->error_cnt && !cc->warning_cnt;
  }catch{Fs->catch_except=TRUE;}
  CmpCtrlDel(cc);
}
U0 PXCheck()
{
  I64 *r=CAlloc(24*8),i,used=Fs->data_heap->used_u8s,code_used=Fs->code_heap->used_u8s;
  I64 state,value;U8 *s;
  PXCase(r+0,r+11,"PXAdd(3,4);");
  PXCase(r+1,r+12,"PXAdd(PXAdd(3,4),5);");
  PXCase(r+2,r+13,"px_integer+=3;");
  PXCase(r+3,r+14,"px_integer;");
  PXCase(r+4,r+15,"px_float+2.5;");
  PXCase(r+5,r+16,"px_float*=2;");
  PXCase(r+6,r+17,"px_float;");
  PXCase(r+7,r+18,"px_bytes[1];");
  PXCase(r+8,r+19,"5.5(I64);");
  PXCase(r+9,r+20,"1<<40;");
  PXCase(r+10,r+21,"PXSecond(\"ab\");");
  for(i=0;i<16;i++)PXCase(&state,&value,"PXAdd(6,7);");
  r[22]=state && value==13 && Fs->data_heap->used_u8s==used;
  r[23]=Fs->code_heap->used_u8s==code_used;
  s=MStrPrint("EXPORT public-expression-runtime.bin %X %X\n",r,24*8);PXLog(s);Free(s);
  PXLog("PUBLIC EXPRESSION RUNTIME DONE\n");Sleep(1000);
}
PXCheck;
