#include "/Kernel/KeyDevOutputCore.HC"

#include "/Kernel/KeyDescriptionCore.HC"

#include "/Kernel/KeyRawOutputCore.HC"

Bool KDInputFilterPutKey(I64 ch,I64 scan_code)
{
  if (Bt(&Fs->task_flags,TASKf_INPUT_FILTER_TASK)) {
    Msg(MSG_KEY_DOWN,ch,scan_code);
    return TRUE;
  } else
    return FALSE;
}

Bool KDInputFilterPutS(U8 *st)
{
  I64 ch;
  if (Bt(&Fs->task_flags,TASKf_INPUT_FILTER_TASK)) {
    while (ch=*st++)
      Msg(MSG_KEY_DOWN,ch,0);
    return TRUE;
  } else
    return FALSE;
}

U0 CtrlAltDel(I64)
{
  LBts(sys_ctrl_alt_flags,CTRL_ALT_DEL);
}

U0 CtrlAltC(I64)
{
  LBts(sys_ctrl_alt_flags,CTRL_ALT_C);
}

U0 CtrlAltD(I64)
{
  if (!IsDbgMode) {
    if (Fs==Gs->idle_task)
      BptS(sys_winmgr_task->rip,sys_winmgr_task);
    else
      BptS(*keydev.ctrl_alt_ret_addr);
  }
}

U0 CtrlAltF(I64)
{
  SwapI64(&text.font,&text.aux_font);
}

U0 CtrlAltM(I64)
{
  Mute(!IsMute);
}

U0 CtrlAltN(I64)
{
  LBts(sys_ctrl_alt_flags,CTRL_ALT_TAB);
}

U0 CtrlAltT(I64)
{
  User;
}

U0 CtrlAltV(I64)
{
  VGAFlush;
}

U0 CtrlAltX(I64)
{
  LBts(sys_ctrl_alt_flags,CTRL_ALT_X);
}

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

U0 KeyDevInit()
{
  keydev.fp_ctrl_alt_cbs	=CAlloc(26*sizeof(U8 *));
  keydev.ctrl_alt_no_shift_descs=CAlloc(26*sizeof(U8 *));
  keydev.ctrl_alt_shift_descs	=CAlloc(26*sizeof(U8 *));
  keydev.ctrl_alt_in_irq_flags	=0;
  MemSet(&keydev.put_key_head,0,sizeof(CKeyDevEntry));
  QueInit(&keydev.put_key_head);
  KeyDevAdd(&KDInputFilterPutKey,&KDInputFilterPutS,0x40000000,FALSE);
  KeyDevAdd(&KDRawPutKey,&KDRawPutS,0x60000000,FALSE);
  CtrlAltCBSet('C',&CtrlAltC,"Cmd /Break Execution",,TRUE);
  CtrlAltCBSet('D',&CtrlAltD,"Cmd /Enter Debugger",,TRUE);
  CtrlAltCBSet('F',&CtrlAltF,"Cmd /Toggle Aux Font");
  CtrlAltCBSet('M',&CtrlAltM,"Cmd /Toggle Mute");
  CtrlAltCBSet('N',&CtrlAltN,"Cmd /Next Focus Task",,TRUE);
  CtrlAltCBSet('T',&CtrlAltT,"Cmd /Terminal Window");
  CtrlAltCBSet('V',&CtrlAltV,"Cmd /VGA Flush",,TRUE);
  CtrlAltCBSet('X',&CtrlAltX,"Cmd /Kill Focused Task",,TRUE);
}
