#help_index "DolDoc/Misc"

U8 captured_macro_name[STR_LEN];
StrCpy(captured_macro_name,"Test");

I64 sys_macro_repeat_n=1;

#include "/Adam/DolDoc/DocMacroCore.HC"

#include "/Adam/DolDoc/DocMacroPlaybackCore.HC"

U0 PlaySysMacro(I64 n=1)
{
  PlaySysMacroCore(n,sys_focus_task,&sys_macro_head);
}

U0 EdInsCapturedMacro()
{
  U8 *st=SysMacro2Str(&sys_macro_head);
  if (sys_focus_task) {
    XTalk(sys_focus_task,"$$MA+LIS,T=\"%s\",LM=\"%$$Q\"$$",
	  captured_macro_name,st);
    Free(st);
  }
}

#define SM_RECORD	0
#define SM_INS		1
#define SM_PLAY		2
#define SM_REPEAT_N	3
#define SM_STOP		4

I64 PopUpMacroMenu()
{
  I64 res=0;
  U8 buf[STR_LEN];
  CJob *tmpc;
  CDoc *doc=DocNew;
  CDocEntry *doc_e=DocPrint(doc,"$$DA-P,LEN=STR_LEN-1,A=\"Name:%%s\"$$");
  doc_e->data=captured_macro_name;
  DocDataFmt(doc,doc_e);

  doc_e=DocPrint(doc,"\n$$DA,A=\"Repeat N:%%d\"$$");
  doc_e->data=&sys_macro_repeat_n;
  DocDataFmt(doc,doc_e);

  DocPrint(doc,"\n"
	"$$CM+LX,1,3$$$$BT,\"RECORD\",LE=SM_RECORD$$"
	"$$CM+LX,17,0$$$$BT,\"INSERT\",LE=SM_INS$$"
	"$$CM+LX,1,3$$$$BT,\"PLAY\",LE=SM_PLAY$$"
	"$$CM+LX,17,0$$$$BT,\"REPEAT N\",LE=SM_REPEAT_N$$"
	"$$CM+LX,1,3$$$$BT,\"STOP\",LE=SM_STOP$$"
	"$$CM+LX,17,0$$$$BT,\"CANCEL\",LE=DOCM_CANCEL$$"
	"\n\n\n$$GREEN$$SHIFT-F2$$FG$$ will play macro.\n");
  doc->flags|=DOCF_SIZE_MIN | DOCF_FORM;
  StrPrint(buf,"DocMenu(%d);",doc);
  sys_macro_task=Spawn(&SrvCmdLine,NULL,"Macro Popup",,Fs);
  Fs->popup_task=sys_macro_task;
  LBts(&sys_macro_task->display_flags,DISPLAYf_WIN_ON_TOP);
  tmpc=TaskExe(sys_macro_task,Fs,buf,
	1<<JOBf_WAKE_MASTER|1<<JOBf_FOCUS_MASTER);
  JobResScan(tmpc,&res);
  Fs->popup_task=NULL;
  Kill(sys_macro_task);
  sys_macro_task=NULL;
  DocDataScan(doc,doc_e);
  DocDel(doc);
  return res;
}

U0 MacroTask(I64)
{
  I64 i;
  StrCpy(captured_macro_name,"Click Here");
  sys_macro_repeat_n=1;
  do {
    i=PopUpMacroMenu;
    WinRefocus(sys_focus_task);
    switch (i) {
      case SM_RECORD:
	LBtr(&sys_semas[SEMA_RECORD_MACRO],0);
	QueDel(&sys_macro_head,TRUE);
	LBts(&sys_semas[SEMA_RECORD_MACRO],0);
	break;
      case SM_PLAY:
	PlaySysMacro;
	break;
      case SM_REPEAT_N:
	PlaySysMacro(sys_macro_repeat_n);
	break;
      case SM_STOP:
	LBtr(&sys_semas[SEMA_RECORD_MACRO],0);
	break;
      case SM_INS:
	LBtr(&sys_semas[SEMA_RECORD_MACRO],0);
	EdInsCapturedMacro;
	break;
    }
  } while (i>=0);
}

U0 EdMacroUtil()
{
  if (!sys_macro_task)
    Spawn(&MacroTask,NULL,"Macro");
}
