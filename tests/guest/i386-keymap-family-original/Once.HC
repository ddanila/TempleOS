U8 *keymap_capture;I64 keymap_length;
Bool KeyMapProbeKey(I64 ch,I64 sc)
{
  no_warn ch;
  if(sc&SCF_KEY_DESC && (sc&255)==0x10) {KeyDescSet("Edit/Probe Q");return TRUE;}
  if(sc&SCF_KEY_DESC && (sc&255)==0x11) {KeyDescSet("Cmd /Probe W");return TRUE;}
  return FALSE;
}
Bool KeyMapProbeText(U8 *s)
{
  I64 n=StrLen(s);
  if(keymap_length+n<65535) {MemCpy(keymap_capture+keymap_length,s,n);keymap_length+=n;}
  return TRUE;
}
U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
CKeyDevEntry *hook;Bool inhibited;U8 *line;
keymap_length=0;keymap_capture=CAlloc(65536);hook=KeyDevAdd(&KeyMapProbeKey,&KeyMapProbeText,10,TRUE);
inhibited=LBtr(&Fs->win_inhibit,WIf_SELF_KEY_DESC);
KeyMapFamily(Fs,0,TRUE,TRUE);
LBEqu(&Fs->win_inhibit,WIf_SELF_KEY_DESC,inhibited);KeyDevRem(hook);
if(keymap_length<128 || keymap_length>=65536){Report("FAIL invalid keymap length\n");throw;}
line=MStrPrint("EXPORT keymap.bin %X %X\n",keymap_capture,keymap_length);Report(line);Free(line);
Report("DONE key map family\n");
