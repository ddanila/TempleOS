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
  }
}
