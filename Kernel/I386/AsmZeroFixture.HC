//Compile-only 386 inline assembly fixture. Never call this function.
public U0 I386AsmZeroFixture()
{
  asm {
    CLI
    STI
    HLT
    CLD
    STD
    NOP
    CLC
    STC
  }
}
