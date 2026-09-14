#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Except.HH"
class CExceptControl {
  U0 (*save)(CI386ExceptCapture *out,U8 *catch_start,U8 *untry_start);
  U0 (*invoke)(CI386ExceptCapture *capture);
  U0 (*resume)(CI386ExceptCapture *capture);
  I64 (*test)();
};
CExceptControl *active;
CI386ExceptCapture registered;
U32 removed,resume_requested;
extern U0 SysTry(U8 *catch_start,U8 *untry_start);
extern U0 SysUntry();
extern U0 Fire();
I64 Main(CExceptControl *control,I64 unused)
{
  CI386ExceptCapture capture;
  U8 *frame=GetRBP;
  I64 local=0x1234567800000001,before;
  if((*control->test)()) return 1;
  (*control->save)(&capture,&Main,&Main);
  if(capture.ebp!=(frame+0)(U64) || capture.esp>capture.ebp ||
      capture.esp&3 || capture.catch_start!=&Main || capture.untry_start!=&Main)
    return 2;
  active=control;
  try { Fire; local+=10; }
  catch { local+=0x100000007; }
  if(local!=0x1234567900000012 || removed!=1) return 3;
  before=local; resume_requested=1;
  try { Fire; local+=100; }
  catch { local+=0x200000003; }
  if(local!=before+0x200000003 || removed!=2) return 4;
  return 0;
}
//Fixture registration only: retain the real enclosing frame and compiler labels.
//This does not supply the production SysTry entry or its register capture.
U0 SysTry(U8 *catch_start,U8 *untry_start)
{
  U8 *frame=GetRBP;
  registered.ebp=*frame(U32 *);
  registered.esp=frame+24;
  registered.catch_start=catch_start; registered.untry_start=untry_start;
  registered.eflags=2;
}
U0 SysUntry() { removed++; }
U0 Fire()
{
  (*active->invoke)(&registered);
  if(resume_requested) (*active->resume)(&registered);
}

