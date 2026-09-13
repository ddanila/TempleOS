#include "/Kernel/I386/Kbc.HH"
#include "/Kernel/I386/KeyboardSetup.HH"
public Bool I386KeyboardCommand(U8 value,I64 polls=100000,I64 attempts=3)
{//Exclusive command owner, IF clear; caller must quiesce scanning/auxiliary traffic.
  I64 i;
  U8 reply,status;
  if (polls<1 || polls>100000 || attempts<1 || attempts>3) return FALSE;
  for (i=0;i<attempts;i++) {
    if (!I386KbcWrite(FALSE,value,polls) || !I386KbcReadWait(&reply,&status,polls) ||
        (status&0xE0)) return FALSE;
    if (reply==0xFA) return TRUE;
    if (reply!=0xFE) return FALSE;
  }
  return FALSE;
}
public Bool I386KeyboardSetup(I64 polls=100000)
{//Boot-only, quiet input, exclusive 8042 owner, IF clear and PIC IRQ1/12 masked.
  U8 config,status;
  if (polls<1 || polls>100000) return FALSE;
  if (!I386KbcDrain(polls) || !I386KbcWrite(TRUE,0x20,polls) ||
      !I386KbcReadWait(&config,&status,polls) || (status&0xE0)) return FALSE;
  //Enable the keyboard clock and translation; disable auxiliary clock and both IRQs.
  config=(config|0x60)&~0x13;
  if (!I386KbcWrite(TRUE,0x60,polls) || !I386KbcWrite(FALSE,config,polls)) return FALSE;
  //Defaults with scanning disabled, explicit scan set 2, then scanning enabled.
  if (!I386KeyboardCommand(0xF5,polls) || !I386KeyboardCommand(0xF0,polls) ||
      !I386KeyboardCommand(2,polls) || !I386KeyboardCommand(0xF4,polls)) return FALSE;
  if (!I386KbcWrite(TRUE,0x60,polls) || !I386KbcWrite(FALSE,config|1,polls)) return FALSE;
  return TRUE;
}
