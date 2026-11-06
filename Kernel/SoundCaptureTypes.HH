#ifndef SOUND_CAPTURE_TYPES_INCLUDED
#define SOUND_CAPTURE_TYPES_INCLUDED
public class CAUData
{//Fmt of AU files
  CDate	cdt;
  I8	ona;
};

class CSndData
{//Fmt recorded in mem
  CSndData *next,*last;
  F64	tS;
  I8	ona;
};

public class CScrnCastGlbls
{
  CSndData snd_head;
  CDate	t0_now;
  F64	t0_tS;
  U8	*print_fmt;
  CDC	*dc,*dc2_alias;
  Bool	record,just_audio;
  I8	ona;
};
#endif
