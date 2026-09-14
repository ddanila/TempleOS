U8 *IncludeText(U8 *name)
{
  if(!StrCmp(name,"T:/First.HC")) return "11\n#include \"T:/Second.HC\"\n#define IncludeValue 42\n13\n";
  if(!StrCmp(name,"T:/Second.HC")) return "#ifdef Missing\n#include \"T:/Never.HC\"\n#else\n22\n#endif\n";
  if(!StrCmp(name,"T:/Empty.HC")) return "";
  if(!StrCmp(name,"T:/Name.HC")) return "\"T:/Second.HC\"";
  return 0;
}
