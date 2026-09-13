#ifndef I386_EXCEPTION_INCLUDED
#define I386_EXCEPTION_INCLUDED
class CI386ExceptionFrame
{
  U32 gs,fs,es,ds,edi,esi,ebp,saved_esp,ebx,edx,ecx,eax;
  U32 vector,error,eip,cs,eflags;
};
#assert sizeof(CI386ExceptionFrame)==68
#endif
