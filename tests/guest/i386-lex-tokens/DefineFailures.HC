#include "/Compiler/LexDefine.HH"
class CDefineFault {
  U8 *input; I64 reads,stop,appends,stop_append,length; U8 output[2050];
};
I64 DefineFaultRead(U8 *context,CCmpCtrl *cc)
{
  CDefineFault *fault=context;
  if(fault->reads++==fault->stop) return -1;
  if(cc->flags&CCF_USE_LAST_U16) { cc->flags&=~CCF_USE_LAST_U16; return cc->last_U16; }
  cc->last_U16=*fault->input;
  if(cc->last_U16) fault->input++;
  return cc->last_U16;
}
Bool DefineFaultAppend(U8 *context,U8 *text,I64 count)
{
  CDefineFault *fault=context; I64 i;
  if(fault->appends++==fault->stop_append) return FALSE;
  if(count<1 || fault->length+count>2049) return FALSE;
  for(i=0;i<count;i++) fault->output[fault->length+i]=text[i];
  fault->length+=count-1;
  return TRUE;
}
I64 DefineFaultCase(U8 *input,U8 *expected)
{
  CDefineFault fault; CCmpCtrl cc; CLexFile file;
  CLexCharSource source; CLexDefineSink sink;
  I64 i,total,appends;
  source.context=&fault; source.read=&DefineFaultRead;
  sink.context=&fault; sink.append=&DefineFaultAppend;
  IdentZero(&fault,sizeof(CDefineFault)); IdentSeed(&cc,&file,input);
  fault.input=input; fault.stop=fault.stop_append=-1;
  if(!LexDefineRead(&cc,&source,&sink) || StrCmp(fault.output,expected)) return 450;
  total=fault.reads; appends=fault.appends;
  for(i=0;i<total;i++) {
    IdentZero(&fault,sizeof(CDefineFault)); IdentSeed(&cc,&file,input);
    fault.input=input; fault.stop=i; fault.stop_append=-1;
    if(LexDefineRead(&cc,&source,&sink) || fault.reads!=i+1) return 451;
  }
  for(i=0;i<appends;i++) {
    IdentZero(&fault,sizeof(CDefineFault)); IdentSeed(&cc,&file,input);
    fault.input=input; fault.stop=-1; fault.stop_append=i;
    if(LexDefineRead(&cc,&source,&sink) || fault.appends!=i+1) return 452;
  }
  return 0;
}
I64 DefineFailures()
{
  I64 result;
  result=DefineFaultCase(define_input0,define_expected0); if(result) return result+0*1000;
  result=DefineFaultCase(define_input1,define_expected1); if(result) return result+1*1000;
  result=DefineFaultCase(define_input2,define_expected2); if(result) return result+2*1000;
  result=DefineFaultCase(define_input3,define_expected3); if(result) return result+3*1000;
  result=DefineFaultCase(define_input4,define_expected4); if(result) return result+4*1000;
  result=DefineFaultCase(define_input5,define_expected5); if(result) return result+5*1000;
  result=DefineFaultCase(define_input6,define_expected6); if(result) return result+6*1000;
  result=DefineFaultCase(define_input7,define_expected7); if(result) return result+7*1000;
  result=DefineFaultCase(define_input8,define_expected8); if(result) return result+8*1000;
  result=DefineFaultCase(define_input9,define_expected9); if(result) return result+9*1000;
  result=DefineFaultCase(define_input10,define_expected10); if(result) return result+10*1000;
  result=DefineFaultCase(define_input11,define_expected11); if(result) return result+11*1000;
  result=DefineFaultCase(define_input12,define_expected12); if(result) return result+12*1000;
  result=DefineFaultCase(define_input13,define_expected13); if(result) return result+13*1000;
  result=DefineFaultCase(define_input14,define_expected14); if(result) return result+14*1000;
  result=DefineFaultCase(define_input15,define_expected15); if(result) return result+15*1000;
  result=DefineFaultCase(define_input16,define_expected16); if(result) return result+16*1000;
  result=DefineFaultCase(define_input17,define_expected17); if(result) return result+17*1000;
  result=DefineFaultCase(define_input18,define_expected18); if(result) return result+18*1000;
  result=DefineFaultCase(define_input19,define_expected19); if(result) return result+19*1000;
  result=DefineFaultCase(define_input20,define_expected20); if(result) return result+20*1000;
  result=DefineFaultCase(define_input21,define_expected21); if(result) return result+21*1000;
  result=DefineFaultCase(define_input22,define_expected22); if(result) return result+22*1000;
  result=DefineFaultCase(define_input23,define_expected23); if(result) return result+23*1000;
  result=DefineFaultCase(define_input24,define_expected24); if(result) return result+24*1000;
  result=DefineFaultCase(define_input25,define_expected25); if(result) return result+25*1000;
  result=DefineFaultCase(define_input26,define_expected26); if(result) return result+26*1000;
  result=DefineFaultCase(define_input27,define_expected27); if(result) return result+27*1000;
  result=DefineFaultCase(define_input28,define_expected28); if(result) return result+28*1000;
  return 0;
}
