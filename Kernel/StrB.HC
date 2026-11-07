#include "/Kernel/StringAllocUtilCore.HC"

#include "/Kernel/GetOutOfDollarCore.HC"

#include "/Kernel/CharacterPromptCore.HC"

U0 Help()
{//Dbg help or master help index file.
  if (IsDbgMode)
    DbgHelp;
  else
    PopUp("Type(\"::/Doc/HelpIndex.DD\");DocTop;View;");
}

#include "/Kernel/ScanFlagsCore.HC"

U8 *StrPrintFlags(U8 *dst,U8 *lst,I64 flags)
{//Only 64 flags. Flags passed by value.
  I64 i;
  *dst=0;
  while (flags) {
    i=Bsf(flags);
    Btr(&flags,i);
    CatPrint(dst,"+%z",i,lst);
  }
  return dst;
}
