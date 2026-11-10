//Complete shared optimizer and diagnostics, built as a private native module.
#include "/Kernel/Types.HH"
#include "/Kernel/QueueTypes.HH"
#include "/Kernel/NumericLimits.HH"
#include "/Kernel/MathConstants.HH"
#include "/Kernel/DirEntryTypes.HH"
#include "/Kernel/WindowInhibitFlags.HH"
#include "/Kernel/RunLevelTypes.HH"
#include "/Kernel/BlkDev/DriveTypes.HH"
#include "/Kernel/BlkDev/CFileTypes.HH"
#define TRUE 1
#define FALSE 0
#define ON 1
#define OFF 0

#define NULL 0
#include "/Kernel/I386/ConsoleRuntime.HH"
#include "/Kernel/I386/Intrinsic.HH"

#include "/Compiler/Keywords.HH"
#include "/Kernel/StringLimits.HH"
#include "/Compiler/CompilerA.HH"
#include "/Kernel/CharCodes.HH"
import U64 I386F64Add(U64 a,U64 b);
import U64 I386F64Sub(U64 a,U64 b);
import U64 I386F64Mul(U64 a,U64 b);
import U64 I386F64Div(U64 a,U64 b);
import U64 I386F64Mod(U64 a,U64 b);
import U64 I386F64FromI64(I64 value);
import I64 I386F64ToI64(U64 value);
import I64 I386F64Compare(U64 a,U64 b);
import CCmpGlbls cmp;
import U8 *MAlloc(I64 size,CTask *task=NULL);
import U0 Free(U8 *allocation);
import U0 LexExcept(CCmpCtrl *cc,U8 *message=NULL);
import U0 LexWarn(CCmpCtrl *cc,U8 *message=NULL);
import CCodeMisc *COCMiscNew(CCmpCtrl *cc,I64 type);
import U0 Print(U8 *format,...);
import U0 PutChars(U64 chars);
import U0 PrintErr(U8 *format,...);
import U0 Yield();
import U0 throw(I64 ch=0,Bool no_log=FALSE);
#include "/Compiler/ICInfo.HC"
#include "/Compiler/PrsStack.HC"
#include "/Compiler/TargetSize.HC"
#include "/Compiler/OptCode.HC"
#include "/Compiler/ICDetachCore.HC"
#include "/Compiler/OptFreeCore.HC"
#include "/Compiler/OptTypes.HC"
#include "/Compiler/OptBranch.HC"
#include "/Compiler/OptSize.HC"
#include "/Compiler/ICDiagnosticsCore.HC"
#define OPT_PASS012_IMPL NativeSystemOptPass012
#include "/Compiler/OptPass012.HC"
#define OPT_PASS012_IMPL OptPass012
class CI386OptProvider {
 U32 version,bytes;
 CIntermediateCode *(*optimize)(CCmpCtrl *cc);
};
I64 Main(CI386OptProvider *services,I64 bytes)
{
 if(!services || bytes!=sizeof(CI386OptProvider))return 0;
 ICInfoInit;
 services->version=1;services->bytes=sizeof(CI386OptProvider);
 services->optimize=&NativeSystemOptPass012;return 1;
}
