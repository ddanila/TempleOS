//Original Ctrl-Alt callback registration.
U0 CtrlAltCBSet(U8 ch,U0 (*fp_hndlr)(I64 sc),
	U8 *no_shift_desc=NULL,U8 *shift_desc=NULL,Bool in_irq=FALSE)
{//Set callback for <CTRL-ALT-letter>.
  ch=ToUpper(ch)-'A';
  if (ch<26) {
    keydev.fp_ctrl_alt_cbs[ch]=fp_hndlr;

    Free(keydev.ctrl_alt_no_shift_descs[ch]);
    if (no_shift_desc)
      keydev.ctrl_alt_no_shift_descs[ch]=AStrNew(no_shift_desc);
    else
      keydev.ctrl_alt_no_shift_descs[ch]=NULL;

    Free(keydev.ctrl_alt_shift_descs[ch]);
    if (shift_desc)
      keydev.ctrl_alt_shift_descs[ch]=AStrNew(shift_desc);
    else
      keydev.ctrl_alt_shift_descs[ch]=NULL;

    BEqu(&keydev.ctrl_alt_in_irq_flags,ch,in_irq);
  }
}
