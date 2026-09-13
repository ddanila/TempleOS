#ifndef I386_A20_INCLUDED
#define I386_A20_INCLUDED
public extern Bool I386A20Test();
public extern I64 I386A20Enable(Bool allow_fast=FALSE,I64 poll_limit=100000);
#endif
