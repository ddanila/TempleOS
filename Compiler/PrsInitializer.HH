#ifndef PRS_INITIALIZER_INCLUDED
#define PRS_INITIALIZER_INCLUDED
#include "/Compiler/PrsDeclaration.HH"
#include "/Kernel/PatchTypes.HH"
//One parser owner controls destinations, temporary rows, code and relocation lists.
class CPrsInitializerServices {
  U8 *context;
  CPrsDeclarationServices *declarations;
  U0 (*copy)(U8 *context,U8 *destination,U8 *source,I64 bytes);
  U0 (*set)(U8 *context,U8 *destination,U8 value,I64 bytes);
  U0 (*store_u8)(U8 *context,CCmpCtrl *cc,U8 value);
  U8 *(*compile_code)(U8 *context,CCmpCtrl *cc,I64 *bytes);
};
extern U0 PrsVarInitCore(CPrsInitializerServices *services,CCmpCtrl *cc,U8 **_dst,CHashClass *tmpc,CArrayDim *tmpad,
	U8 *data_addr_rip,U8 **_base,Bool data_heap,I64 pass);
extern U0 PrsVarInit2Core(CPrsInitializerServices *services,CCmpCtrl *cc,U8 **_dst,CHashClass *tmpc,
	CArrayDim *tmpad,U8 *data_addr_rip,U8 **_base,Bool data_heap,I64 pass);
extern U0 PrsGlblInitCore(CPrsInitializerServices *services,CCmpCtrl *cc,CHashGlblVar *tmpg,I64 pass);
extern U0 PrsStaticInitCore(CPrsInitializerServices *services,CCmpCtrl *cc,CMemberLst *tmpm,I64 pass);
#endif
