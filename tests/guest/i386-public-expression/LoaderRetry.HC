#include "/Kernel/I386/PublicCompilerContext.HH"
U0 PRLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 PRRun()
{
  I64 value=0;
  CCmpCtrl *cc=CmpCtrlNew(StrNew("6*7;"));
  try{Lex(cc);value=LexExpression(cc);}
  catch{CmpCtrlDel(cc);}
  if(cc->token!=';' || cc->error_cnt || cc->warning_cnt)value=0;
  CmpCtrlDel(cc);return value;
}
U0 PRCheck()
{
  I64 r[13],bytes,attr,used;Bool caught=FALSE;
  U8 *path="C:/Compiler/I386/PublicPrsStream.HC",*saved,*fault="throw('PrsTest');\n",*message;
  CHashTable *table=adam_task->hash_table;
  saved=FileRead(path,&bytes,&attr);r[0]=saved && bytes>0;
  if(!FileWrite(path,fault,StrLen(fault),0,attr))throw;
  used=Fs->data_heap->used_u8s;
  try{PRRun;}
  catch{caught=Fs->except_ch=='PrsLoad';Fs->catch_except=TRUE;}
  r[1]=caught;
  r[2]=native_jit_support.prs_stage==10;
  r[3]=!native_jit_support.expression && !native_jit_support.expression_i64 &&
    !native_jit_support.expression_f64 && !native_jit_support.expression_bin &&
    !native_jit_support.is_expression_bin && !native_jit_support.stream;
  r[4]=adam_task->hash_table==table;
  r[5]=Fs->data_heap->used_u8s==used;
  r[6]=FileWrite(path,saved,bytes,0,attr)!=0;
  used=Fs->data_heap->used_u8s;
  r[7]=PRRun==42;
  r[8]=native_jit_support.prs_stage==12 && native_jit_support.expression &&
    native_jit_support.expression_i64 && native_jit_support.expression_f64 &&
    native_jit_support.expression_bin && native_jit_support.is_expression_bin && native_jit_support.stream;
  r[9]=adam_task->hash_table==table;
  r[10]=Fs->data_heap->used_u8s==used;
  r[11]=PRRun==42;
  r[12]=Fs->data_heap->used_u8s==used;
  Free(saved);
  message=MStrPrint("EXPORT public-parser-retry.bin %X 68\n",r);PRLog(message);Free(message);
  PRLog("PUBLIC PARSER RETRY DONE\n");Sleep(1000);
}
PRCheck;
