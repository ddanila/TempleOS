#ifndef I386_PUBLIC_WINDOW_INCLUDED
#define I386_PUBLIC_WINDOW_INCLUDED
#include "/Kernel/DisplayFlags.HH"
#include "/Kernel/ControlTypes.HH"
#define TEXT_COLS 80
#define TEXT_ROWS 60
public _extern _TASK_VALIDATE Bool TaskValidate(CTask *task);
public _extern _TASK_DERIVED_VALS_UPDATE U0 TaskDerivedValsUpdate(CTask *task=NULL,Bool update_z_buf=TRUE);
public _extern _WIN_HORZ Bool WinHorz(I64 left,I64 right,CTask *task=NULL);
public _extern _WIN_VERT Bool WinVert(I64 top,I64 bottom,CTask *task=NULL);
public _extern _CTRL_FIND_UNIQUE CCtrl *CtrlFindUnique(CTask *task,I64 type);
public _extern _CTRLS_UPDATE U0 CtrlsUpdate(CTask *task);
public _extern _CTRL_INSIDE Bool CtrlInside(CCtrl *c,I64 x,I64 y);
public _extern _WIN_Z_BUF_UPDATE U0 WinZBufUpdate();
public _extern _WIN_INSIDE Bool WinInside(I64 x,I64 y,CTask *task=NULL,I64 border=0);
#endif
