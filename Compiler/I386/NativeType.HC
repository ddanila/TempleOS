//Included after the native expression parser and its task-stack check.
#include "/Compiler/I386/NativeType.HH"
#include "/Compiler/PrsKeyword.HC"
#include "/Compiler/PrsTypeCore.HC"
CHashClass *I386ParseType(CI386Heap *heap,CCmpCtrl *cc,CPrsTypeServices *services,
  CHashClass **first,I64 *mode,CMemberLst *member,U8 **ident,CHashFun **fun,
  CHashExport **export_entry,CArrayDim *dim,I64 flags)
{
  if(!I386CmpCodeOwner(heap,cc) || !services || !services->types || !first || !mode || !dim ||
      !services->lex || !services->report || !services->snapshot_drop || !services->snapshot_push ||
      !services->integer_expression || !services->class_join || !services->fun_join ||
      !services->allocate || !services->duplicate || !services->member_new || !services->member_add)
    return 0;
  if(!I386ParserStackCheck(cc)) return 0;
  return PrsTypeCore(services,cc,first,mode,member,ident,fun,export_entry,dim,flags);
}
