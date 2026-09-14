//Included after the native expression and type cores.
#include "/Compiler/I386/NativeDeclaration.HH"
#include "/Compiler/PrsDeclarationCore.HC"
Bool I386DeclarationServicesValid(CPrsDeclarationServices *services)
{
  return !(!services || !I386ExpressionServicesValid(services->expression) || !I386TypeServicesValid(services->types) ||
      !services->define_match || !services->evaluate || !services->snapshot_restore ||
      !services->initialize_static || !services->static_init || !services->store_u64 ||
      !services->store_u8_at || !services->data_range || !services->compile_expression ||
      !services->execute || !services->release);
}
Bool I386ParseDeclarations(CI386Heap *heap,CCmpCtrl *cc,CPrsDeclarationServices *services,
  CHashClass *type,I64 mode,I64 union_base=0)
{
  if(!I386CmpCodeOwner(heap,cc) || !type || !I386DeclarationServicesValid(services)) return FALSE;
  if(!I386ParserStackCheck(cc)) return FALSE;
  PrsVarLstCore(services,cc,type,mode,union_base);
  return TRUE;
}
