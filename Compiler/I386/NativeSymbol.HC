//Included after native declarations. All target symbols must be privately owned.
#include "/Compiler/I386/NativeSymbol.HH"
#include "/Compiler/MemberBuild.HC"
#include "/Compiler/PrsSymbolCore.HC"
Bool I386SymbolServicesValid(CPrsSymbolServices *services)
{
  return services && I386DeclarationServicesValid(services->declarations) &&
    services->class_new && services->fun_new && services->single_find &&
    services->class_members_delete && services->members_delete && services->source &&
    services->option && services->warning;
}
CHashClass *I386ParseClass(CI386Heap *heap,CCmpCtrl *cc,CPrsSymbolServices *services,
  I64 keyword,I64 flags,Bool is_extern)
{
  if(!I386CmpCodeOwner(heap,cc) || !I386SymbolServicesValid(services) ||
      keyword!=KW_CLASS && keyword!=KW_UNION) return 0;
  if(!I386ParserStackCheck(cc)) return 0;
  return PrsClassCore(services,cc,keyword,flags,is_extern);
}
CHashFun *I386ParseFunJoin(CI386Heap *heap,CCmpCtrl *cc,CPrsSymbolServices *services,
  CHashClass *return_type,U8 *name,I64 flags)
{
  if(!I386CmpCodeOwner(heap,cc) || !return_type || !I386SymbolServicesValid(services) ||
      cc->flags&CCF_AOT_COMPILE && !cc->aotc) return 0;
  if(!I386ParserStackCheck(cc)) return 0;
  return PrsFunJoinCore(services,cc,return_type,name,flags);
}
