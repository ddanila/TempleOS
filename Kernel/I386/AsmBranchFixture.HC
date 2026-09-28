//Compile-only forward/backward local-label fixture. Never call this function.
public U0 I386AsmBranchFixture()
{
  asm {
    JMP @@20
@@10:
    NOP
@@20:
    NOP
    JB @@10
  }
}
