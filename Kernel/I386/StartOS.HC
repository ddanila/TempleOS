//Native HolyC startup, read from RedSea by the console task before its first prompt.
//Add definitions and commands here to customize the initial interactive scope.
//The compiler executes this source on the target; it is not an AOT startup module.
//Successful definitions persist for subsequent commands. A failed input unwinds
//its private definitions but does not undo side effects already executed.
//Only the currently integrated native language and runtime providers are available.
#define NULL 0
#define TRUE 1
#define FALSE 0

//Resident system exports borrow kernel-lifetime code; declarations own metadata.
#include "/Kernel/I386/Intrinsic.HH"

#include "/Kernel/I386/PublicDocument.HH"
#include "/Kernel/I386/PublicFiles.HH"

#include "/Kernel/I386/PublicHash.HH"

//Initialize task-owned dictionaries through retained original document code.
ConsoleDocumentStart;
BibleInit;

#include "/Kernel/I386/PublicTextBase.HH"

#include "/Kernel/I386/PublicMath.HH"

#include "/Kernel/I386/PublicDate.HH"

#include "/Kernel/I386/PublicGraphicsContext.HH"

#include "/Kernel/I386/PublicWindow.HH"
#include "/Kernel/I386/PublicFormat.HH"
#include "/Kernel/I386/PublicStream.HH"

#include "/Kernel/I386/PublicSound.HH"

#include "/Kernel/I386/PublicMouse.HH"

if(!NativeGraphicsStart) throw('Graphics',TRUE);

#define I386_GRAPHICS_STARTED 1
#include "/Kernel/I386/PublicRaster.HH"

if(!NativeWinMgrStart) throw('WinMgr',TRUE);
