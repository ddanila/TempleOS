//Loaded once in Adam: public prompt/debugger helpers have system lifetime.
#include "/Kernel/I386/PublicDocument.HH"
#include "/Kernel/I386/PublicHash.HH"
#include "/Kernel/I386/PublicDebug.HH"
#include "/Kernel/I386/PublicWindow.HH"
#include "/Kernel/I386/PublicTextBase.HH"
#include "/Kernel/I386/PublicFormat.HH"
#include "/Kernel/I386/PublicFiles.HH"
#include "/Kernel/I386/PublicKeyDev.HH"
#include "/Kernel/UAsmTypes.HH"
CUAsmGlbls uasm;
MemSet(&uasm,0,sizeof(uasm));
#include "/Compiler/CompilerDefinesCore.HC"
CmpLoadDefines;
#include "/Kernel/PutSrcLinkCore.HC"
#define UASM_CODE_BITS 32
#include "/Compiler/UAsmCore.HC"
#include "/Compiler/I386/UAsmTables.HC"
NativeUAsmTablesInit;
#define RAWDR_REG_COUNT 8
#define RAWDR_REG_NAMES "ST_U32_REGS"
#define RAWDR_HEX_WIDTH 8
#define RAWDR_IP_NAME "EIP"
#define RAWDR_CODE_BITS 32
#include "/Kernel/RawRegistersCore.HC"
#include "/Compiler/CommandPromptCore.HC"
