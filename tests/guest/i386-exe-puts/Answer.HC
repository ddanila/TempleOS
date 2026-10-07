#include "/Kernel/RawTypes.HH"
I64 JRContract()
{
  I64 mask=0,value;
  Fs->new_answer=FALSE;Fs->answer_time=-1.0;
  value=ExePutS("21*2;","Answer.HC");
  if(value==42 && Fs->answer==42)mask|=1;
  if(Fs->answer_type==RT_I64)mask|=2;
  if(Fs->new_answer)mask|=4;
  if(Fs->answer_time>=0.0)mask|=8;
  Fs->answer=17;Fs->answer_type=RT_U8;
  Fs->new_answer=FALSE;Fs->answer_time=123.0;
  if(ExePutS("99;","NoAnswer.HC",64)==1 && Fs->answer==17 &&
      Fs->answer_type==RT_U8 && !Fs->new_answer && Fs->answer_time==123.0)mask|=16;
  ExePutS("42.0;","FloatAnswer.HC");
  if(Fs->answer_type==RT_F64 && Fs->answer(F64)==42.0)mask|=32;
  return mask;
}
