#ifndef I386_PUBLIC_DEBUG_INCLUDED
#define I386_PUBLIC_DEBUG_INCLUDED
#include "/Kernel/NumericLimits.HH"
public _extern _DBG U0 Dbg(U8 *msg=0,I64 msg_num=0);
public _extern _DEBUG_GO U0 G(U8 *ip=U32_MAX,CTask *task=0);
public _extern _DBG_MODE Bool DbgMode(Bool value);
public _extern _IS_DBG_MODE Bool IsDbgMode();
#endif
