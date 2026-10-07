#ifndef I386_PUBLIC_DEBUG_INCLUDED
#define I386_PUBLIC_DEBUG_INCLUDED
#include "/Kernel/NumericLimits.HH"
public _extern _CALLER U8 *Caller(I64 num=1);
public _extern _DBG U0 Dbg(U8 *msg=0,I64 msg_num=0);
public _extern _DEBUG_GO U0 G(U8 *ip=U32_MAX,CTask *task=0);
public _extern _DBG_MODE Bool DbgMode(Bool value);
public _extern _IS_DBG_MODE Bool IsDbgMode();
public _extern _DEBUG_STEP U0 S(U8 *ip=U32_MAX,CTask *task=0);
public _extern _TASK_REG_ADDR I64 *TaskRegAddr(CTask *task,I64 reg_num);
#include "/Kernel/I386/PublicDebugTypes.HH"
public _extern _BPT_FIND CBpt *BptFind(U8 *addr,CTask *task=0,Bool rem=0);
public _extern _BPT_SET Bool BptS(U8 *addr,CTask *task=0,Bool live=1);
public _extern _BPT_REMOVE Bool BptR(U8 *addr,CTask *task=0,Bool live=1,Bool rem=1);
public _extern _BPT_TOGGLE Bool B(U8 *addr,CTask *task=0,Bool live=1);
public _extern _BPT_CLEAR I64 B2(CTask *task=0,Bool live=1);
public _extern _DEBUG_GO_CLEAR U0 G2(U8 *ip=U32_MAX,CTask *task=0);
public _extern _SRC_LINE_NUM I64 SrcLineNum(U8 *addr,I64 cnt=1);
public _extern _SRC_FILE_NAME U8 *SrcFileName(U8 *addr,I64 cnt=1,CTask *mem_task=NULL);
public _extern _SRC_ED_LINK U8 *SrcEdLink(U8 *addr,I64 cnt=1,CTask *mem_task=NULL);
#endif
