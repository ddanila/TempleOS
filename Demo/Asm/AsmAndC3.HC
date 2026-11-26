#ifdef I386_PUBLIC_USER_INCLUDED
U0 AsmAndC3()
{
  I64 i;
  U32 value,delay=cnts.time_stamp_freq>>5;

  for (i=0;i<3;i++) {
    "Meaning of life:";
    asm {
      MOV EAX,0x41
      STC
      ADC EAX,0
      MOV U32 &value[EBP],EAX
    }
    "%02X",value;
    if (delay)
      asm {
        MOV ECX,U32 &delay[EBP]
@@1:    LOOP @@1
      }
    '\n';
  }
}

AsmAndC3;
#else
/*Asm labels can only be defined once
in a task.  <F5> will spawn a new task
each time, so you don't get redefine
error, like when repeatedly #including
it from the cmd line.
*/

U0 AsmAndC3()
{
  I64 i;
  for (i=0;i<3;i++) {
    "Meaning of life:";
    MOV	AL,0x41
    STC
    ADC	AL,0 //Round-about way to make the not-special constant, 0x42.
    CALL	PUT_HEX_U8
    MOV	RCX,cnts.time_stamp_freq>>5 //JIT Const.  Simple delay loop.
@@1:	LOOP	@@1
    '\n';
  }
}

AsmAndC3;
#endif
