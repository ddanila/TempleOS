U0 Snd(I8 ona=0)
{//Play ona, a piano key num. 0 means rest.
  I64 period;
  CSndData *d;
  if (!Bt(&sys_semas[SEMA_MUTE],0) &&
	!LBts(&sys_semas[SEMA_SND],0)) { //Mutex. Just throw-out if in use
    if (!ona) {
      scrncast.ona=ona;
      OutU8(0x61,InU8(0x61)&~3);
    } else if (ona!=scrncast.ona) {
      scrncast.ona=ona;
      period=ClampI64(SYS_TIMER_FREQ/Ona2Freq(ona),1,U16_MAX);
      OutU8(0x43,0xB6);
      OutU8(0x42,period);
      OutU8(0x42,period.u8[1]);
      OutU8(0x61,3|InU8(0x61));
    }
    if (!IsDbgMode && scrncast.record) {
      d=ACAlloc(sizeof(CSndData));
      d->ona=ona;
      d->tS=tS;
      QueIns(d,scrncast.snd_head.last);
    }
    LBtr(&sys_semas[SEMA_SND],0);
  }
}

Bool ScrnCast(Bool val=ON,Bool just_audio=FALSE,U8 *print_fmt="B:/Tmp/%X.GR")
{//WinMgr saves GR files to a dir.
  Bool old_val;
  scrncast.just_audio=just_audio;
  if (val) {
    if (!(old_val=LBtr(&scrncast.record,0))) {
      Free(scrncast.print_fmt);
      scrncast.print_fmt=AStrNew(print_fmt);
      scrncast.t0_now=Now;
      scrncast.snd_head.tS=scrncast.t0_tS=tS;
      scrncast.snd_head.ona=scrncast.ona;
      LBts(&scrncast.record,0);
    }
  } else
    old_val=LBtr(&scrncast.record,0);
  Snd;
  return old_val;
}

U0 SndRst()
{//Fix stuck sound.
  if (Bt(&sys_semas[SEMA_SND],0)) {
    Sleep(1);
    if (Bt(&sys_semas[SEMA_SND],0)) {
      Sleep(1);
      LBtr(&sys_semas[SEMA_SND],0);
    }
  }
  Snd;
}

