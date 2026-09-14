#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/HashValue.HH"
#include "/Kernel/I386/String.HH"
#include "/Compiler/MemberLookup.HH"
#include "/Compiler/I386/SymbolAlloc.HH"
#include "/Compiler/I386/SymbolDelete.HH"
#include "/Kernel/I386/HashTable.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Ports.HH"
#assert sizeof(CHashSrcSym)==36
#assert sizeof(CHashExport)==44
#assert sizeof(CHashImport)==44
#assert sizeof(CHashGeneric)==40
#assert sizeof(CHashDefineStr)==52
#assert sizeof(CHashClass)==80
#assert sizeof(CHashFun)==108
#assert sizeof(CHashGlblVar)==92
#assert sizeof(CArrayDim)==20
#assert sizeof(CMemberLstMeta)==24
#assert sizeof(CMemberLst)==96
#assert sizeof(CExternUsage)==12
#assert sizeof(CDbgInfo)==12
#assert offset(CHashExport.val)==36
#assert offset(CHashClass.size)==36
#assert offset(CHashClass.raw_type)==57
#assert offset(CHashFun.arg_cnt)==84
#assert offset(CHashFun.exe_addr)==100
#assert offset(CHashGlblVar.data_addr)==80
#assert offset(CHashGlblVar.heap_glbl)==84
#assert offset(CMemberLst.offset)==44
#assert offset(CMemberLst.dim)==60
#assert offset(CMemberLst.dft_val)==84
#assert offset(CMemberLst.fun_ptr)==92
U64 value_oracle[28];
extern I64 MemberLookupTest();
extern I64 SymbolAllocTest();
extern I64 NativeSymbolDeleteTest();
extern I64 SymbolValueCase(I64 index);
I64 Main(I64 unused,I64 unused2)
{
  CHash base;
  CHashClass classes[2];
  CHashFun function;
  CHashGlblVar variable;
  CMemberLst member;
  CMemberLstMeta meta;
  I64 i,j,expected,result;
  for(i=0;i<28;i++) if(SymbolValueCase(i)!=value_oracle[i]) return 100+i;
  if(HashTypeNum(0)!=-1) return 1;
  base.type=HTF_PUBLIC|HTF_PRIVATE|HTF_LOCAL;
  if(HashTypeNum(&base)!=-1) return 2;
  for(i=0;i<17;i++) for(j=0;j<17;j++) {
    base.type=(1<<i)|(1<<j)|HTF_PUBLIC|HTF_PRIVATE|HTF_LOCAL;
    expected=i; if(j<i) expected=j;
    if(HashTypeNum(&base)!=expected) return 3;
  }
  classes[0].type=HTT_CLASS; classes[0].size=0x100000020;
  classes[0].neg_offset=-0x100000010;
  classes[1].type=HTT_CLASS; classes[1].ptr_stars_cnt=1; classes[1].raw_type=7;
  classes[1].size=4; classes[1].base_class=&classes[0];
  function.type=HTT_FUN; function.flags=0; function.return_class=&classes[1];
  function.arg_cnt=0xFEDCBA98; function.exe_addr=0xF1234567;
  member.member_class=&classes[1]; member.fun_ptr=&function; member.meta=&meta;
  member.offset=-0x100000008; member.size=0x100000004;
  member.dim.next=0; member.dim.cnt=0x100000002; member.dim.total_cnt=0x200000004;
  member.dft_val=0x89ABCDEF01234567;
  meta.flags=MLMF_IS_STR; meta.user_data=0xFEDCBA9876543210;
  variable.type=HTT_GLBL_VAR; variable.flags=GVF_EXTERN;
  variable.var_class=&classes[1]; variable.fun_ptr=&function;
  variable.data_addr=0xABCDEF12;
  variable.data_addr_rip=0x1122334455667788;
  variable.heap_glbl=0xAABBCCDD;
  if(member.member_class-member.member_class->ptr_stars_cnt!=classes ||
      member.member_class->base_class->size!=0x100000020 ||
      member.member_class->base_class->neg_offset!=-0x100000010 ||
      member.fun_ptr->return_class!=&classes[1] || member.fun_ptr->arg_cnt!=0xFEDCBA98 ||
      HashVal(member.fun_ptr)!=0xF1234567 || member.offset!=-0x100000008 ||
      member.size!=0x100000004 || member.dim.cnt!=0x100000002 ||
      member.dim.total_cnt!=0x200000004 || member.static_data_rip!=0x89ABCDEF01234567 ||
      member.meta->user_data!=0xFEDCBA9876543210) return 4;
  if(variable.data_addr_rip!=0x11223344AABBCCDD ||
      HashVal(&variable)!=(&variable.data_addr+0)(U64) ||
      variable.fun_ptr!=&function || variable.var_class!=member.member_class) return 5;
  result=MemberLookupTest;
  if(result) return result;
  result=SymbolAllocTest;
  if(result) return result;
  return NativeSymbolDeleteTest;
}
#include "T:/Values.HC"
#include "/Kernel/HashValue.HC"

#include "/Kernel/I386/Hash.HC"
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/HashTable.HC"
#include "/Compiler/I386/SymbolAlloc.HC"
#include "/Compiler/MemberLookup.HC"
#include "T:/Members.HC"

#include "T:/Seeds.HC"
#include "T:/Allocate.HC"

#include "/Compiler/I386/SymbolDelete.HC"
CI386Heap delete_heap;
I64 delete_free_errors;
U8 *DeleteAllocRaw(I64 size) { return I386HeapAlloc(&delete_heap,size,TRUE); }
U0 DeleteFreeRaw(U8 *allocation)
{
  if(!I386HeapFree(&delete_heap,allocation)) delete_free_errors++;
}
#include "T:/Delete.HC"
I64 NativeSymbolDeleteTest()
{
  U32 flags=I386IrqSave;
  CHashFun *fun;
  CMemberLst *member;
  I64 result;
  if(!I386HeapInit(&delete_heap,0x40000,65536)) return 64;
  delete_free_errors=0;
  result=SymbolDeleteTest;
  if(result) return result;
  if(delete_free_errors || delete_heap.used || delete_heap.allocations || !I386HeapValid(&delete_heap)) return 65;
  fun=I386PrsFunNew(&delete_heap);
  if(!fun) return 66;
  member=I386HeapAlloc(&delete_heap,sizeof(CMemberLst),TRUE);
  if(!member) return 67;
  member->str=I386HeapAlloc(&delete_heap,8,TRUE);
  if(!member->str) return 68;
  fun->member_lst_and_root=member; fun->arg_cnt=1;
  SetRFlags(GetRFlags|0x200);
  if(!I386ClassMemberLstDel(&delete_heap,fun) || !(GetRFlags&0x200) ||
      fun->arg_cnt || fun->member_lst_and_root || delete_heap.allocations!=1) return 69;
  if(!I386HashDel(&delete_heap,fun) || !I386HashDel(&delete_heap,0) || !(GetRFlags&0x200)) return 70;
  I386IrqSave;
  if(delete_heap.used || delete_heap.allocations || !I386HeapValid(&delete_heap)) return 71;
  I386IrqRestore(flags); return 0;
}
