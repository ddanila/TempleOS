//The fixed table span contains no pointers and has identical byte layout on both targets.
U64 DocDefaultsFingerprint(CDolDocGlbls *state)
{
  U8 *bytes=&state->dft_de_flags;
  U64 hash=0xCBF29CE484222325;
  I64 i;
  for(i=0;i<sizeof(CDolDocGlbls)-offset(CDolDocGlbls.dft_de_flags);i++)
    hash=(hash^bytes[i])*0x100000001B3;
  return hash;
}
