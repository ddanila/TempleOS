U0 MassProbeLog(U8 *s)
{
  while (*s) OutU8(0xE9,*s++);
}

U0 MassProbeDerive(CMathODE *,F64 t,F64 *state,F64 *dt)
{
}

U0 ODEProbe()
{
  CMathODE *ode=ODENew(0,1e-6,ODEF_HAS_MASSES);
  CMass *fixed=CAlloc(sizeof(CMass)),*moving=CAlloc(sizeof(CMass));
  CSpring *spring=CAlloc(sizeof(CSpring));
  F64 saved_fps=winmgr.fps,expected_x,expected_v;
  U8 line[160];
  fixed->mass=1;
  fixed->flags=MSF_FIXED;
  moving->mass=1;
  moving->x=2;
  spring->end1=fixed;
  spring->end2=moving;
  spring->const=4;
  spring->rest_len=1;
  ode->derive=&MassProbeDerive;
  QueIns(fixed,ode->last_mass);
  QueIns(moving,ode->last_mass);
  QueIns(spring,ode->last_spring);
  QueIns(ode,Fs->last_ode);
  if (!(winmgr.fps>0)) winmgr.fps=30;
  try {
    MassProbeLog("ODE mass start\n");
    ODEsUpdate(Fs);
    MassProbeLog("ODE mass initialized\n");
    Sleep(100);
    ODEsUpdate(Fs);
    StrPrint(line,"ODE mass state t=%X x=%X v=%X fixed=%X\n",
        ode->t(I64),moving->x(I64),moving->DxDt(I64),fixed->x(I64));
    MassProbeLog(line);
    //Unit moving mass and spring constant four give angular frequency two.
    expected_x=1+Cos(2*ode->t);
    expected_v=-2*Sin(2*ode->t);
    if (ode->t>0.01 && moving->x<2 && moving->DxDt<0 &&
        Abs(moving->x-expected_x)<0.02 && Abs(moving->DxDt-expected_v)<0.02 &&
        fixed->x==0 && fixed->DxDt==0)
      MassProbeLog("ODE mass motion\n");
  } catch {
    StrPrint(line,"FAIL ODE mass exception %X\n",Fs->except_ch);
    MassProbeLog(line);
    Fs->catch_except=TRUE;
  }
  winmgr.fps=saved_fps;
  QueRem(ode);
  QueDel(&ode->next_spring,TRUE);
  QueDel(&ode->next_mass,TRUE);
  ODEDel(ode);
}

