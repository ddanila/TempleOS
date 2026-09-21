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
extern I64 StrCmp(U8 *left,U8 *right);
extern U0 SysTry(U8 *catch_start,U8 *untry_start);
extern U0 SysUntry();
extern U0 throw(I64 ch=0,Bool no_log=FALSE);

#include "/Kernel/I386/Intrinsic.HH"

#include "/Kernel/I386/PublicDocument.HH"

#include "/Kernel/I386/PublicHash.HH"

//Initialize task-owned dictionaries through retained original document code.
ConsoleDocumentStart;

#include "/Kernel/I386/PublicTextBase.HH"

#include "/Kernel/I386/PublicMath.HH"
