public _extern _NATIVE_ODE_BIND Bool NativeODEBind(U0 (*update)(CTask *task));
#include "/Kernel/ODETypes.HH"
#include "/Kernel/I386/ODEScalar.HC"
#define I386_NATIVE_SERIAL_ODE
#include "/Adam/AMathODE.HC"
if(!NativeODEBind(&ODEsUpdate))throw('ODEBind');
