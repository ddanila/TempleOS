U8 *km_capture;I64 km_length,km_calls;Bool km_normal,km_shift;
U0 KMProbeCtrl(I64 sc){no_warn sc;}
Bool KMProbeKey(I64 ch,I64 sc)
{
  no_warn ch;
  if(sc&SCF_KEY_DESC && ((sc&255)==0x10 || (sc&255)==0x11)) {
    km_calls++;if(sc&SCF_SHIFT)km_shift=TRUE;else km_normal=TRUE;
    if((sc&255)==0x10)KeyDescSet("Edit/Probe Q");else KeyDescSet("Cmd /Probe W");
    return TRUE;
  }
  return FALSE;
}
Bool KMProbeText(U8 *s)
{
  I64 n=StrLen(s);
  if(km_length+n<65535){MemCpy(km_capture+km_length,s,n);km_length+=n;}
  return TRUE;
}
I64 KeyMapPublicContract()
{
  CKeyDevEntry *hook;CDoc *doc=DocPut;I64 mask=0,old_max=doc->max_entries;Bool inhibited,old_silent;
  km_capture=CAlloc(65536);km_length=0;km_calls=0;km_normal=km_shift=FALSE;
  old_silent=LBtr(&Fs->display_flags,DISPLAYf_SILENT);
  inhibited=LBtr(&Fs->win_inhibit,WIf_SELF_KEY_DESC);
  hook=KeyDevAdd(&KMProbeKey,&KMProbeText,10,TRUE);
  KeyMapFamily(Fs,0,TRUE,TRUE);
  if(km_calls>=4 && km_normal && km_shift)mask|=1;
  if(km_length>128 && km_length<65536 && StrMatch("Probe",km_capture))mask|=2;
  km_length=0;MemSet(km_capture,0,65536);
  CtrlAltCBSet('Z',&KMProbeCtrl,"Edit/Custom plain","Cmd /Custom shifted",TRUE);
  KeyMapCtrlAltFamily(TRUE,TRUE);
  if(StrMatch("Custom",km_capture) && StrMatch("Reboot",km_capture) &&
     keydev.fp_ctrl_alt_cbs[25]==&KMProbeCtrl && Bt(&keydev.ctrl_alt_in_irq_flags,25))mask|=8;
  CtrlAltCBSet('Z',NULL);
  km_length=0;km_calls=0;MemSet(km_capture,0,65536);
  KeyMap(Fs);
  if(km_calls>=12 && StrMatch("KeyMap Completed",km_capture) &&
     !Bt(&Fs->win_inhibit,WIf_SELF_KEY_DESC))mask|=16;
  doc->max_entries=old_max;
  KeyDevRem(hook);LBEqu(&Fs->win_inhibit,WIf_SELF_KEY_DESC,inhibited);
  LBEqu(&Fs->display_flags,DISPLAYf_SILENT,old_silent);Free(km_capture);km_capture=NULL;
  mask|=4;return mask;
}
