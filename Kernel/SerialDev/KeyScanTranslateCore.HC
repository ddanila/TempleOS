//Original scan-code and character translation.
I64 Char2ScanCode(I64 ch,I64 sc_flags=0)
{//ASCII val to scan code (Slow).
  I64 i;
  U8 *table;
  if (sc_flags) {
    table=NORMAL_KEY_SCAN_DECODE_TABLE;
    if (sc_flags & SCF_CTRL || ch<26)
      table=CTRL_KEY_SCAN_DECODE_TABLE;
    else if (sc_flags & SCF_SHIFT || 'A'<=ch<='Z') {
      if (!(sc_flags & SCF_CAPS))
	table=SHIFT_KEY_SCAN_DECODE_TABLE;
    } else {
      if (sc_flags & SCF_CAPS)
	table=SHIFT_KEY_SCAN_DECODE_TABLE;
    }
    for (i=0;i<0x50;i++)
      if (table[i]==ch)
	return i|sc_flags;
    return sc_flags;
  } else {
    table=NORMAL_KEY_SCAN_DECODE_TABLE;
    for (i=0;i<0x50;i++)
      if (table[i]==ch)
	return i;
    table=SHIFT_KEY_SCAN_DECODE_TABLE;
    for (i=0;i<0x50;i++)
      if (table[i]==ch)
	return i|SCF_SHIFT;
    table=CTRL_KEY_SCAN_DECODE_TABLE;
    for (i=0;i<0x50;i++)
      if (table[i]==ch)
	return i|SCF_CTRL;
    return 0;
  }
}

U8 ScanCode2Char(I64 sc)
{//Scan code to ASCII val.
  U8 *table=NORMAL_KEY_SCAN_DECODE_TABLE;
  if (sc&SCF_E0_PREFIX)
    return 0;
  if (sc&SCF_CTRL)
    table=CTRL_KEY_SCAN_DECODE_TABLE;
  else if (sc&SCF_SHIFT) {
    if (!(sc&SCF_CAPS))
      table=SHIFT_KEY_SCAN_DECODE_TABLE;
  } else {
    if (sc&SCF_CAPS)
      table=SHIFT_KEY_SCAN_DECODE_TABLE;
  }
  sc&=0x7F;
  if (sc>=0x50)
    return 0;
  else
    return table[sc];
}

