U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("B:/");DirMk("B:/Home");HomeSet("B:/Home");
#include "T:/Apps/Budget/Install.HC"
#include "T:/Apps/Budget/Install.HC"
U0 InstalledTemplate()
{
  I64 size;U8 *data=FileRead("~/Budget/Accts.DD.Z",&size),*line;
  if(!data){Report("FAIL Budget accounts missing\n");return;}
  line=MStrPrint("EXPORT installed-accounts.DD %X %X\n",data,size);Report(line);
  Report("DONE Budget installation\n");
}
InstalledTemplate;
