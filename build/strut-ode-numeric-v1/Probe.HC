U0 ODEProbeRate(CMathODE *,F64 t,F64 *state,F64 *dt)
{ dt[0]=state[0]; }

U0 ODEProbe()
{
  CMathODE *ode=ODENew(1,1e-8);
  CD3 a,b;
  I64 mask=0,i;
  U8 line[120],*p;
  a.x=3; a.y=4; a.z=0;
  b.x=0; b.y=0; b.z=0;
  if(D3Norm(&a)==5 && D3Dist(&a,&b)==5 && D3NormSqr(&a)==25)
    mask|=1;
  ode->derive=&ODEProbeRate;
  ode->state_internal[0]=1;
  ode->state_scale[0]=1;
  ode->h=0.125;
  ODERK4OneStep(ode);
  if(ode->t==0.125 && Abs(ode->state_internal[0]-Exp(0.125))<1e-6)
    mask|=2;
  ode->state_internal[0]=1;
  ode->t=0;
  ode->h=1.0;
  for(i=0;i<5;i++)
    ODERK5OneStep(ode);
  if(0<ode->t<1.0 && Abs(ode->state_internal[0]-Exp(ode->t))<1e-6)
    mask|=4;
  ODEDel(ode);
  StrPrint(line,"ODE mask %d\n",mask);
  for(p=line;*p;p++)OutU8(0xE9,*p);
}
