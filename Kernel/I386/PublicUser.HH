#ifndef I386_PUBLIC_USER_INCLUDED
#define I386_PUBLIC_USER_INCLUDED
//Declarations for a user terminal without rerunning singleton initialization.
#define NULL 0
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/PublicKernel.HH"
#include "/Kernel/I386/Intrinsic.HH"
#include "/Kernel/I386/PublicDocument.HH"
#include "/Kernel/I386/PublicFiles.HH"
#include "/Kernel/I386/PublicHash.HH"
#include "/Kernel/I386/PublicTextBase.HH"
#include "/Kernel/I386/PublicMath.HH"
#include "/Kernel/I386/PublicDate.HH"
#include "/Kernel/I386/PublicGraphicsContext.HH"
#include "/Kernel/I386/PublicWindow.HH"
#include "/Kernel/I386/PublicFormat.HH"
#include "/Kernel/I386/PublicSound.HH"
#include "/Kernel/I386/PublicMouse.HH"
#include "/Kernel/I386/PublicMacro.HH"
#include "/Kernel/I386/PublicMenu.HH"
#include "/Kernel/I386/PublicExecution.HH"
#ifdef I386_GRAPHICS_STARTED
#include "/Kernel/I386/PublicRaster.HH"
#endif
#endif
