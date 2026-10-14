#include "/Kernel/KeyDevTypes.HH"
#include "/Kernel/ScanFlags.HH"
CKeyDevGlbls keydev;
Bool native_keydev_ready;
U8 *ACAlloc(I64 size)
{
  return CAlloc(size,I386TaskSelf->owner->root);
}
#define KEYDEV_SCAN_CODE (console_config->reader->state.keys.locks)
#include "/Kernel/KeyDevOutputCore.HC"
I64 ScanMsg(I64 *a=NULL,I64 *b=NULL,I64 mask=~1,CTask *task=NULL)
{
  return (*native_public_scan_msg)(a,b,mask,task);
}
#include "/Kernel/KeyScanCore.HC"
Bool NativeKeyDevFilterKey(I64 ch,I64 sc)
{
  if(!Bt(&Fs->task_flags,TASKf_INPUT_FILTER_TASK)) return FALSE;
  (*native_output_msg)(MSG_KEY_DOWN,ch,sc,0);
  return TRUE;
}
Bool NativeKeyDevFilterString(U8 *s)
{
  if(!Bt(&Fs->task_flags,TASKf_INPUT_FILTER_TASK)) return FALSE;
  while(*s) {
    (*native_output_msg)(MSG_KEY_DOWN,*s++,0,0);
    I386TaskBreakPoll;
  }
  return TRUE;
}
Bool NativeKeyDevConsoleKey(I64 ch,I64 sc)
{
  CDoc *doc=DocPut;
  if(sc&SCF_KEY_DESC) return FALSE;
  if(doc) DocPutKey(doc,ch,sc);
  if(!(sc&(SCF_CTRL|SCF_ALT))) I386TextPut(&console_text,ch);
  ConsolePresent;
  return FALSE;
}
Bool NativeKeyDevConsoleString(U8 *s)
{
  NativeConsoleWrite(s);ConsolePresent;
  return FALSE;
}
U0 NativeKeyDevStart()
{
  if(native_keydev_ready) return;
  MemSet(&keydev,0,sizeof(CKeyDevGlbls));
  QueInit(&keydev.put_key_head);
  KeyDevAdd(&NativeKeyDevFilterKey,&NativeKeyDevFilterString,0x40000000,FALSE);
  KeyDevAdd(&NativeKeyDevConsoleKey,&NativeKeyDevConsoleString,0x80000000,TRUE);
  native_keydev_ready=TRUE;
}
