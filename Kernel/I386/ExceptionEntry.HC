//Same-ring 386 exception entries; CS=8, flat DS=ES=16, intact stack.
//Dispatcher receives an eight-byte pointer slot, keeps IF clear and must not yield.
#include "/Kernel/Types.HH"
asm {
USE32
IMPORT I386ExceptionDispatch;
i386_exception_0::
  PUSH 0
  PUSH 0
  JMP i386_exception_common
i386_exception_1::
  PUSH 0
  PUSH 1
  JMP i386_exception_common
i386_exception_2::
  PUSH 0
  PUSH 2
  JMP i386_exception_common
i386_exception_3::
  PUSH 0
  PUSH 3
  JMP i386_exception_common
i386_exception_4::
  PUSH 0
  PUSH 4
  JMP i386_exception_common
i386_exception_5::
  PUSH 0
  PUSH 5
  JMP i386_exception_common
i386_exception_6::
  PUSH 0
  PUSH 6
  JMP i386_exception_common
i386_exception_7::
  PUSH 0
  PUSH 7
  JMP i386_exception_common
i386_exception_8::
  PUSH 8
  JMP i386_exception_common
i386_exception_9::
  PUSH 0
  PUSH 9
  JMP i386_exception_common
i386_exception_10::
  PUSH 10
  JMP i386_exception_common
i386_exception_11::
  PUSH 11
  JMP i386_exception_common
i386_exception_12::
  PUSH 12
  JMP i386_exception_common
i386_exception_13::
  PUSH 13
  JMP i386_exception_common
i386_exception_14::
  PUSH 14
  JMP i386_exception_common
i386_exception_15::
  PUSH 0
  PUSH 15
  JMP i386_exception_common
i386_exception_16::
  PUSH 0
  PUSH 16
  JMP i386_exception_common
i386_exception_common:
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
  CALL I386ExceptionDispatch
  POP GS
  POP FS
  POP ES
  POP DS
  POPAD
  ADD ESP,8
  IRET
}
