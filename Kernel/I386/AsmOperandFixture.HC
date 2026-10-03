//Compile-only operand fixture for the first instructions of I386HeapValid.
#include "/Kernel/I386/Heap.HH"
public U0 I386AsmOperandFixture(CI386Heap *hc)
{
  asm {
    MOV EBX,U32 &hc[EBP]
    MOV ESI,U32 CI386Heap.base[EBX]
    MOV ECX,U32 CI386Heap.size[EBX]
    XOR EDI,EDI
    XOR EDX,EDX
    OR ECX,U32 CI386Heap.size[EBX]
    TEST U32 CI386Heap.size[EBX],1<<2|1<<9
    TEST ECX,(1+2)*3^~(-1)
    CMP U32 CI386Heap.base+4[EBX],ESI
    JL I32 @@50
@@50:
    JG I32 @@51
@@51:
  }
}
