//Shared public job records; callers declare CTask and CJobCtrl.
#define JOBf_WAKE_MASTER	0
#define JOBf_FOCUS_MASTER	1
#define JOBf_EXIT_ON_COMPLETE	2
#define JOBf_DONT_FILTER	3
#define JOBf_HIGHEST_PRIORITY	4
//MP flags
#define JOBf_DONE		5
#define JOBf_DISPATCHED		6
#define JOBf_FREE_ON_COMPLETE	7
#define JOBf_ADD_TO_QUE		8

#define JOBT_TEXT_INPUT		0 //$LK,"TaskText",A="MN:TaskText"$()	Feed StdIn
#define JOBT_MSG		1 //$LK,"TaskMsg",A="MN:TaskMsg"$()	Post msg
#define JOBT_EXE_STR		2 //$LK,"TaskExe",A="MN:TaskExe"$()	Compile & execute src code text
//MP cmds
#define JOBT_CALL		3 //$LK,"JobQue",A="MN:JobQue"$()	Tell MP to call function
#define JOBT_SPAWN_TASK		4 //$LK,"Spawn",A="MN:Spawn"$()	Tell MP to spawn task

class CJob
{
  CJob *next,*last;
  CJobCtrl *ctrl;
  I64	job_code,flags,msg_code;

  I64	(*addr)(U8 *fun_arg);
  U8	*fun_arg;

  U8	*aux_str;
  I64	aux1,aux2, //Sometimes called arg1 and arg2. (Windows msg param1 param2)
	res;

  CTask	*spawned_task,
	*master_task;
};

