U0 InputFilterTask()
{
  CJob *tmpc,*tmpc1;
  Bool old_filter;
  I64 old_flags=GetRFlags;
  Fs->win_inhibit=WIG_USER_TASK_DFT;
  LBts(&Fs->task_flags,TASKf_INPUT_FILTER_TASK);
  old_filter=LBts(&Fs->last_input_filter_task->task_flags,TASKf_FILTER_INPUT);
  LBEqu(&Fs->task_flags,TASKf_FILTER_INPUT,old_filter);
  while (TRUE) {
    CLI
    JobsHndlr(old_flags);
    tmpc1=&Fs->srv_ctrl.next_waiting;
    tmpc=tmpc1->next;
    if (tmpc==tmpc1)
      break;
    else {
      if (tmpc->job_code==JOBT_TEXT_INPUT) {
	QueRem(tmpc);
	SetRFlags(old_flags);
	try
		ExePrint("%s",tmpc->aux_str);
	catch
	  Fs->catch_except=TRUE;
	JobDel(tmpc);
      } else
	break;
    }
  }
  Fs->next_input_filter_task->last_input_filter_task=Fs->last_input_filter_task;
  Fs->last_input_filter_task->next_input_filter_task=Fs->next_input_filter_task;
  if (!old_filter)
    LBtr(&Fs->last_input_filter_task->task_flags,TASKf_FILTER_INPUT);
  SetRFlags(old_flags);
}

I64 ScanMsg(I64 *_arg1=NULL,I64 *_arg2=NULL,I64 mask=~1,CTask *task=NULL)
{/*Check for a message of type specified by a one in the mask.
Throw-out messages not in mask.
If no message fit mask, return NULL immediately.
Remove desired message, return $LK,"msg_code",A="MN:MSG_CMD"$.
Note: This delivers messages from parent down to pop-up.
*/
  I64 res,old_flags;
  CJob *tmpc,*tmpc1;
  if (!task) task=Fs;
  old_flags=GetRFlags;
  tmpc1=&task->srv_ctrl.next_waiting;
  while (TRUE) {
    CLI
    if (task==Fs)
      JobsHndlr(old_flags);
    tmpc=tmpc1->next;
    if (tmpc==tmpc1)
      break;
    else {
      if (tmpc->job_code==JOBT_MSG) {
	QueRem(tmpc);
	SetRFlags(old_flags);
	res=tmpc->msg_code;
	if (_arg1)
	  *_arg1=tmpc->aux1;
	if (_arg2)
	  *_arg2=tmpc->aux2;
	JobDel(tmpc);
	if ((res!=MSG_KEY_DOWN || !(tmpc->aux2&SCF_KEY_DESC) ||
	      !Bt(&task->win_inhibit,WIf_SELF_KEY_DESC)) && Bt(&mask,res))
	  goto sm_done;
      }
    }
    SetRFlags(old_flags);
  }
  res=MSG_NULL;
  if (_arg1)
    *_arg1=0;
  if (_arg2)
    *_arg2=0;
  if (task->parent_task&&task->parent_task->popup_task==task) {
    SetRFlags(old_flags);
    return ScanMsg(_arg1,_arg2,mask,task->parent_task);
  }
sm_done:
  SetRFlags(old_flags);
  return res;
}

I64 FlushMsgs(CTask *task=NULL)
{//Throw away all messages.  Return count.
  I64 res=0,arg1,arg2;
  while (ScanMsg(&arg1,&arg2,~1,task))
    res++;
  return res;
}

I64 GetMsg(I64 *_arg1=NULL,I64 *_arg2=NULL,I64 mask=~1,CTask *task=NULL)
{//Wait for a message of type specified by a one in the mask.
//Throw-out all messages not in mask.
  //Returns $LK,"msg_code",A="MN:MSG_CMD"$. See $LK,"::/Demo/MsgLoop.HC"$.
  I64 res;
  if (!task) task=Fs;
  LBtr(&task->task_flags,TASKf_IDLE);
  while (!(res=ScanMsg(_arg1,_arg2,mask,task))) {
    LBts(&task->task_flags,TASKf_IDLE);
    Yield;
  }
  LBtr(&task->task_flags,TASKf_IDLE);
  return res;
}

I64 ScanChar()
{//Checks for $LK,"MSG_KEY_DOWN",A="MN:MSG_KEY_DOWN"$ and returns 0 immediately if no key.
//Waits for $LK,"MSG_KEY_UP",A="MN:MSG_KEY_UP"$ of non-zero $LK,"ASCII",A="MN:CH_CTRLA"$ key and returns $LK,"ASCII",A="MN:CH_CTRLA"$ if key.
  //$LK,"ScanMsg",A="MN:ScanMsg"$() throws away other message types.
  I64 arg1a,arg2a,arg1b,arg2b;
  if (!ScanMsg(&arg1a,&arg2a,1<<MSG_KEY_DOWN)||!arg1a)
    return 0;
  else
    do GetMsg(&arg1b,&arg2b,1<<MSG_KEY_UP);
    while (!arg1b);  //Be careful of $LK,"SC_SHIFT",A="MN:SC_SHIFT"$ and $LK,"SC_CTRL",A="MN:SC_CTRL"$, etc.
  return arg1a;
}

#include "/Kernel/KeyScanCore.HC"

U0 KeyGetDebugPoll()
{
      PUSHFD
      CLI
      KbdMsHndlr(TRUE,FALSE);
      KbdMsgsQue;
      POPFD
}
#include "/Kernel/KeyGetCore.HC"

I64 GetChar(I64 *_scan_code=NULL,Bool echo=TRUE,Bool raw_cursor=FALSE)
{//Waits for non-zero $LK,"ASCII",A="MN:CH_CTRLA"$ key.
//Sets $LK,"scan_code",A="FI:::/Doc/CharOverview.DD"$.
  I64 ch1;
  do ch1=GetKey(_scan_code,FALSE,raw_cursor);
  while (!ch1);
  if (echo)
    "$$PT$$%c$$FG$$",ch1;
  return ch1;
}

#include "/Kernel/GetStrCore.HC"

I64 GetS(U8 *buf,I64 size,Bool allow_ext=TRUE)
{//Prompt into fixed length string. Size must include terminator.
  U8 *st;
  I64 ch,i=0;
  if (!size || !buf) return 0;
  if (allow_ext) {
    st=GetStr;
    if (StrLen(st)>size-1) {
      MemCpy(buf,st,size-1);
      buf[size-1]=0;
    } else
      StrCpy(buf,st);
    i=StrLen(buf);
    Free(st);
  } else {
    while (TRUE) {
      ch=GetChar(,FALSE,IsDbgMode);
      if (ch=='\n') {
	'' ch;
	break;
      } else if (ch==CH_BACKSPACE) {
	if (i>0) {
	  i--;
	  '' ch;
	}
      } else {
	if (i<size-1) {
	  buf[i++]=ch;
	  '' ch;
	}
      }
    }
    buf[i]=0;
  }
  return i;
}
