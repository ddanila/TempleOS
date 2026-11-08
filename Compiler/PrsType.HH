#ifndef PRS_TYPE_INCLUDED
#define PRS_TYPE_INCLUDED
#include "/Kernel/CompilerTypes.HH"
#include "/Compiler/PrsTypeFlags.HH"
//Borrowed type descriptors and parser services. Errors and failed allocations
//must throw. Explicit-release dimensions transfer to the caller on success.
//With no release callback the environment must retain all partial allocations
//until its failed control/arena is discarded. Symbols and strings retain their
//existing environment ownership.
class CPrsTypeServices {
  U8 *context;
  CHashClass **types;
  I64 (*lex)(U8 *context,CCmpCtrl *cc);
  U0 (*report)(U8 *context,CCmpCtrl *cc,I64 kind,U8 *message);
  U0 (*snapshot_drop)(U8 *context,CCmpCtrl *cc);
  U0 (*snapshot_push)(U8 *context,CCmpCtrl *cc);
  I64 (*integer_expression)(U8 *context,CCmpCtrl *cc);
  CHashClass *(*class_join)(U8 *context,CCmpCtrl *cc,I64 keyword,I64 flags,Bool is_extern);
  CHashFun *(*fun_join)(U8 *context,CCmpCtrl *cc,CHashClass *return_type,U8 *name,I64 flags);
  U8 *(*allocate)(U8 *context,I64 bytes);
  U8 *(*duplicate)(U8 *context,U8 *source);
  CMemberLst *(*member_new)(U8 *context,I64 register_hint);
  U0 (*member_add)(U8 *context,CCmpCtrl *cc,CMemberLst *member,CHashClass *type,I64 mode);
  //Match allocate; releasing a live dimension must not allocate or throw.
  U0 (*release)(U8 *context,U8 *allocation);
  //Optional owned function-type cleanup; requires release and must not throw.
  U0 (*function_delete)(U8 *context,CHashFun *function);
};
extern U0 PrsArrayDimsCore(CPrsTypeServices *services,CCmpCtrl *cc,I64 mode,CArrayDim *dim);
extern CHashClass *PrsTypeCore(CPrsTypeServices *services,CCmpCtrl *cc,CHashClass **_tmpc1,
  I64 *_mode,CMemberLst *tmpm,U8 **_ident,CHashFun **_fun_ptr,
  CHashExport **_tmpex,CArrayDim *tmpad,I64 fsp_flags);
extern U0 PrsDotDotDotCore(CPrsTypeServices *services,CCmpCtrl *cc,CHashFun *tmpf,I64 _reg);
#endif
