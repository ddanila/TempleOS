//Shared public records; callers provide their declared dependencies.
#include "/Kernel/StringLimits.HH"
#include "/Kernel/TaskFlags.HH"
#define TASK_SIGNATURE_VAL		'TskS'
#define TASK_NAME_LEN			32
#define TASK_EXCEPT_CALLERS		8
class CTaskStk
{
  CTaskStk *next_stk;
  I64	stk_size,stk_ptr;
  U0	stk_base;
};

#define DYING_JIFFIES	ToI64(JIFFY_FREQ/5)
class CTaskDying
{
  CTask *next;
  union { CTask *last; U64 last_slot; };
  I64	wake_jiffy;
};

public class CTask //The Fs segment reg points to current CTask.
{
  CTask *addr; //Self-addressed ptr
  U32	task_signature,win_inhibit;
#assert $$==offset(CTaskDying.wake_jiffy)
  I64	wake_jiffy;
  U32	task_flags,display_flags;

  CHeapCtrl *code_heap,*data_heap;

  CDoc	*put_doc,*display_doc, //When double buffering, these two differ.
	*border_doc;
  I64	win_left,win_right,win_top,win_bottom;

  CDrv	*cur_dv;
  U8	*cur_dir;

  CTask *parent_task,
	*next_task,*last_task,
	*next_input_filter_task,*last_input_filter_task,
	*next_sibling_task,*last_sibling_task,
	*next_child_task,*last_child_task;

  //These are derived from left,top,right,bottom
  I64	win_width,win_height,
	pix_left,pix_right,pix_width, //These are in pixs, not characters
	pix_top,pix_bottom,pix_height,
	scroll_x,scroll_y,scroll_z;

  //These must be in this order
  //for $LK,"TASK_CONTEXT_SAVE",A="FF:::/Kernel/Sched.HC,TASK_CONTEXT_SAVE"$ and $LK,"_TASK_CONTEXT_RESTORE",A="FF:::/Kernel/Sched.HC,_TASK_CONTEXT_RESTORE"$
  I64	rip,rflags,rsp,rsi,rax,rcx,rdx,rbx,rbp,rdi,
	r8,r9,r10,r11,r12,r13,r14,r15;
  CCPU	*gs;
  CFPU	*fpu_mmx;
  I64	swap_cnter;

  U0	(*draw_it)(CTask *task,CDC *dc);

  U8	task_title[STR_LEN],
	task_name[TASK_NAME_LEN],
	wallpaper_data[STR_LEN],

	title_src,border_src,
	text_attr,border_attr;
  U16	win_z_num,pad;

  CTaskStk *stk;

  CExcept *next_except,*last_except;
  I64	except_rbp,	//throw routine's RBP
	except_ch;	//throw(ch)
  U8	*except_callers[TASK_EXCEPT_CALLERS];

  Bool	catch_except;
  Bool	new_answer;
  U8	answer_type,pad[5];
  I64	answer;
  F64	answer_time;
  CBpt	*bpt_lst;
  CCtrl	*next_ctrl,*last_ctrl;
  CMenu	*cur_menu;
  CTaskSettings *next_settings;
  CMathODE *next_ode,*last_ode;
  F64	last_ode_time;
  CHashTable *hash_table;

  CJobCtrl srv_ctrl;
  CCmpCtrl *next_cc,*last_cc;
  CHashFun *last_fun;

  U0	(*task_end_cb)();
  CTask *song_task,*animate_task;
  I64	rand_seed,
	task_num,
	fault_num,fault_err_code;
  CTask *popup_task,
	*dbg_task;
  CWinScroll horz_scroll,vert_scroll;

  I64	user_data;
  $$=($$+7)&~7;
#assert !($$&7)
};
