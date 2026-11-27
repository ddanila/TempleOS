#include "::/Demo/Templates/ODE1.HC"
U0 ODETemplateProbe()
{
  CMathODE *first=Fs->next_ode,*last=Fs->last_ode;
  U8 *s;
  Init;
  if (Fs->last_ode!=ode || ode->derive!=&MyDerivative ||
      ode->drag_v2!=0.002 || ode->drag_v3!=0.00001 ||
      ode->acceleration_limit!=5e3)
    throw('ODEInit',TRUE);
  I64 deadline=cnts.jiffies+2*JIFFY_FREQ;
  while (!(ode->flags&ODEF_STARTED) || ode->t<=0)
  {
    if (cnts.jiffies>deadline) throw('ODESched',TRUE);
    Sleep(10);
  }
  CleanUp;
  if (Fs->next_ode!=first || Fs->last_ode!=last)
    throw('ODEList',TRUE);
  s="DONE ODE template\n";
  while (*s) OutU8(0xE9,*s++);
}
ODETemplateProbe;
