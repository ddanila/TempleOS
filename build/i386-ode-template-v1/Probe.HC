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
  CleanUp;
  if (Fs->next_ode!=first || Fs->last_ode!=last)
    throw('ODEList',TRUE);
  s="DONE ODE template\n";
  while (*s) OutU8(0xE9,*s++);
}
ODETemplateProbe;
