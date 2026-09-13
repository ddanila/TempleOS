#ifndef I386_KBC_INCLUDED
#define I386_KBC_INCLUDED
public extern Bool I386KbcWrite(Bool controller,U8 value,I64 polls=100000);
public extern Bool I386KbcRead(U8 *data,U8 *status);
public extern Bool I386KbcReadWait(U8 *data,U8 *status,I64 polls=100000);
public extern Bool I386KbcDrain(I64 polls=100000);
#endif
