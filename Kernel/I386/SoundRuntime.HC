U32 native_snd_base_periods[12]={86777,81906,77309,72970,68875,65009,
                                 61361,57917,54666,51598,48702,45968};
I8 native_snd_ona;

public U0 Snd(I8 ona=0)
{//Drive the PC speaker from PIT channel 2. Ona 60 is concert A (440 Hz).
  U32 flags;
  I64 note=ona,period,octave;
  flags=I386IrqSave;
  if(!note) {
    OutU8(0x61,InU8(0x61)&~3); native_snd_ona=0;
  } else {
    if(note<0) period=0xFFFF;
    else {
      octave=note/12;
      period=native_snd_base_periods[note%12];
      if(octave<31) period>>=octave; else period=1;
      if(period>0xFFFF) period=0xFFFF;
      if(period<1) period=1;
    }
    if(ona!=native_snd_ona) {
      OutU8(0x43,0xB6);
      OutU8(0x42,period); OutU8(0x42,period.u8[1]);
      native_snd_ona=ona;
    }
    OutU8(0x61,InU8(0x61)|3);
  }
  I386IrqRestore(flags);
}

public U0 SndRst() { Snd; }
