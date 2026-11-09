#ifndef I386_PUBLIC_MOUSE_INCLUDED
#define I386_PUBLIC_MOUSE_INCLUDED
#include "/Kernel/NumericLimits.HH"
#include "/Kernel/MouseStateTypes.HH"
#include "/Kernel/GraphicsTypes.HH"
#help_index "Mouse"
public _extern _MS_GLOBALS CMsStateGlbls ms;
public _extern _MS_GRID_GLOBALS CGridGlbls ms_grid;
public _extern _MOUSE_GET Bool MouseGet(I64 *x,I64 *y,I64 *buttons=0,I64 *packets=0);
public _extern _MS_SET U0 MsSet(I64 x=I64_MAX,I64 y=I64_MAX,I64 z=I64_MAX,I64 l=I64_MAX,I64 r=I64_MAX);
public _extern _GRID_INIT U0 GridInit();
public _extern _DRAW_MS U0 DrawMs(CDC *dc);
public _extern _DRAW_STD_MS U0 DrawStdMs(CDC *dc,I64 x,I64 y);
public _extern _DRAW_WAIT_MS U0 DrawWaitMs(CDC *dc,I64 x,I64 y);
#endif
