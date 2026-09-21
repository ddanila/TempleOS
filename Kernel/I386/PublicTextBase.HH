#ifndef I386_PUBLIC_TEXT_BASE_INCLUDED
#define I386_PUBLIC_TEXT_BASE_INCLUDED
#include "/Kernel/I386/PublicTaskTypes.HH"
public extern U32 *i386_text_base;
public _extern _TEXT_CHAR Bool TextChar(CTask *task,Bool allow_border=FALSE,I64 x,I64 y,I64 d);
public _extern _TEXT_LEN_STR Bool TextLenStr(CTask *task,I64 x,I64 y,I64 len,I64 attr,U8 *s);
public _extern _TEXT_LEN_ATTR_STR Bool TextLenAttrStr(CTask *task,I64 x,I64 y,I64 len,U32 *attrs);
public _extern _TEXT_LEN_ATTR Bool TextLenAttr(CTask *task,I64 x,I64 y,I64 len,I64 attr);
public _extern _TEXT_BASE_PRESENT Bool NativeTextBasePresent(Bool blink=FALSE,I64 pan_x=0,I64 pan_y=0,Bool hide_col=FALSE,Bool hide_row=FALSE);
public _extern _TEXT_BASE_RESTORE U0 NativeTextBaseRestore();
#endif
