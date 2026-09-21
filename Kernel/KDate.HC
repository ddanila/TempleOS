//See $LK,"::/Doc/TimeDate.DD"$

#include "/Kernel/DateCore.HC"

U0 NowDateTimeStruct(CDateStruct *_ds)
{
  I64 i;
  U8 *b=_ds;
  Bool is_bcd;

  MemSet(_ds,0,sizeof(CDateStruct));
  PUSHFD
  CLI
  while (LBts(&sys_semas[SEMA_SYS_DATE],0))
    PAUSE

  OutU8(0x70,0x0A);
  do {
    while (InU8(0x71) & 0x80)
      PAUSE

    OutU8(0x70,0);
    b[2]=InU8(0x71);
    OutU8(0x70,2);
    b[3]=InU8(0x71);
    OutU8(0x70,4);
    b[4]=InU8(0x71);

    OutU8(0x70,6);
    b[5]=InU8(0x71);
    OutU8(0x70,7);
    b[6]=InU8(0x71);
    OutU8(0x70,8);
    b[7]=InU8(0x71);
    OutU8(0x70,9);
    b[8]=InU8(0x71);

    OutU8(0x70,0x0A);
  } while (InU8(0x71) & 0x80);

  OutU8(0x70,0x0B);
  if (InU8(0x71) & 4)
    is_bcd=FALSE;
  else
    is_bcd=TRUE;

  LBtr(&sys_semas[SEMA_SYS_DATE],0);
  POPFD
  if (is_bcd)
    for (i=2;i<9;i++)
      b[i]=Bcd2Bin(b[i]);

  if (_ds->year>255)	_ds->year=255;
  _ds->year+=2000;
  if (_ds->mon>12)	_ds->mon=12;
  if (_ds->day_of_mon>31) _ds->day_of_mon=31;
  if (_ds->day_of_week>6) _ds->day_of_week=6;
  if (_ds->hour>23)	_ds->hour=23;
  if (_ds->min>59)	_ds->min=59;
  if (_ds->sec>59)	_ds->sec=59;
}

CDate Now()
{//Current datetime.
  CDateStruct ds;
  NowDateTimeStruct(&ds);
  return Struct2Date(&ds)-local_time_offset;
}
