#ifndef I386_PUBLIC_TERMINAL_INCLUDED
#define I386_PUBLIC_TERMINAL_INCLUDED
public _extern _USER_CMD_LINE U0 UserCmdLine(I64 dummy=0);
public _extern _USER_TASK_CONT U0 UserTaskCont();
public _extern _WIN_FOCUS CTask *WinFocus(CTask *task=0);
public _extern _USER CTask *User(U8 *fmt=0,...);
public _extern _XTALK U0 XTalk(CTask *task,U8 *fmt,...);
public _extern _TASK_WAIT U0 TaskWait(CTask *task=0,Bool cmd_line_pmt=0);
public _extern _TASK_TEXT CJob *TaskText(CTask *srv,CTask *master,U8 *data,I64 flags);
public _extern _IN_STR U0 InStr(U8 *fmt,...);
public _extern _XTALK_STR_WAIT U0 XTalkStrWait(CTask *task,U8 *fmt,...);
public _extern _IN U0 In(U8 *fmt,...);
public _extern _JOB_RES_SCAN Bool JobResScan(CJob *rqst=NULL,I64 *_res=NULL);
public _extern _JOB_DEL U0 JobDel(CJob *job);
public _extern _TASK_EXE CJob *TaskExe(CTask *srv,CTask *master,U8 *data,I64 flags);
public _extern _SRV_TASK_CONT U0 SrvTaskCont();
public _extern _SRV_CMD_LINE U0 SrvCmdLine(I64 dummy=0);
#define WIG_USER_TASK_DFT 0x1000
#endif
