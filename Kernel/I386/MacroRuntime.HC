//Original macro serialization, retained in the console provider.
#include "/Kernel/SemaTypes.HH"
#include "/Kernel/MessageCodes.HH"
CSema *sys_semas;
U32 char_bmp_macro[16]={
  0x80002600,0xFFFFFFDF,0xFFFFFFFF,0x7FFFFFFF,
  0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,
  0,0,0,0,0,0,0,0
};
U0 JobDel(CJob *job)
{
  if(job->job_code==JOBT_TEXT_INPUT) Free(job->fun_arg);
  Free(job->aux_str); Free(job);
}
#include "/Adam/DolDoc/DocMacroCore.HC"
