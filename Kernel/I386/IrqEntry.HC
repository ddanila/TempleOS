//Same-ring 386 irq entries; CS=8, flat DS=ES=16, intact stack.
//Dispatcher receives an eight-byte pointer slot, keeps IF clear and must not yield.
#include "/Kernel/Types.HH"
asm {
USE32
IMPORT I386IrqDispatch;
i386_irq_0::
  PUSH 0
  JMP i386_irq_common
i386_irq_1::
  PUSH 1
  JMP i386_irq_common
i386_irq_2::
  PUSH 2
  JMP i386_irq_common
i386_irq_3::
  PUSH 3
  JMP i386_irq_common
i386_irq_4::
  PUSH 4
  JMP i386_irq_common
i386_irq_5::
  PUSH 5
  JMP i386_irq_common
i386_irq_6::
  PUSH 6
  JMP i386_irq_common
i386_irq_7::
  PUSH 7
  JMP i386_irq_common
i386_irq_8::
  PUSH 8
  JMP i386_irq_common
i386_irq_9::
  PUSH 9
  JMP i386_irq_common
i386_irq_10::
  PUSH 10
  JMP i386_irq_common
i386_irq_11::
  PUSH 11
  JMP i386_irq_common
i386_irq_12::
  PUSH 12
  JMP i386_irq_common
i386_irq_13::
  PUSH 13
  JMP i386_irq_common
i386_irq_14::
  PUSH 14
  JMP i386_irq_common
i386_irq_15::
  PUSH 15
  JMP i386_irq_common
i386_irq_common:
  PUSHAD
  PUSH DS
  PUSH ES
  PUSH FS
  PUSH GS
  CLD
  MOV AX,16
  MOV DS,AX
  MOV ES,AX
  MOV EAX,ESP
  PUSH 0
  PUSH EAX
  CALL I386IrqDispatch
  POP GS
  POP FS
  POP ES
  POP DS
  POPAD
  ADD ESP,4
  IRET
}
