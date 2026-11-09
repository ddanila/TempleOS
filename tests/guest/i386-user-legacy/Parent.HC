CTask *ul_task;
U0 ULPrepare()
{
  ul_task=User;
  XTalk(ul_task,"CTask *ul_return_focus=0x%X;\n#include \"C:/Probe/UserLegacyChild.HC\"\n",Fs);
}
U0 ULFinish(){Kill(ul_task);WinFocus(Fs);}
