Bool RTCheck(F64 before,F64 now,F64 wanted)
{
  CWinMgrGlbls state;
  MemSet(&state,0,sizeof(state));
  state.updates=17;state.ode_time=7;state.last_refresh_tS=before;
  WinMgrRefreshTime(&state,now);
  return Abs(state.fps-wanted)<0.000000001 &&
    state.last_refresh_tS==now && state.updates==17 && state.ode_time==7;
}
I64 JRContract(I64 unused)
{
  I64 mask=0;
  if(RTCheck(0,0,99))mask|=1;
  if(RTCheck(0,0.01,99))mask|=2;
  if(RTCheck(0,0.02,50))mask|=4;
  if(RTCheck(0,2,1))mask|=8;
  if(RTCheck(2,1,99))mask|=16;
  if(RTCheck(1,1,99))mask|=32;
  return mask;
}
