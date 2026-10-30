//Original Budget storage code with an explicitly constructed transaction.
U0 Report(U8 *text) { while(*text) OutU8(0xE9,*text++); }
Cd("B:/");DirMk("B:/Home");HomeSet("B:/Home");
#include "T:/Apps/Budget/Load.HC"
#include "T:/Apps/Budget/Install.HC"
U0 ExportBudget(U8 *path,U8 *name)
{
  I64 size; U8 *data=FileRead(path,&size),*line;
  if(!data) {Report("FAIL Budget missing file\n");return;}
  line=MStrPrint("EXPORT %s %X %X\n",name,data,size);Report(line);Free(line);
}
U0 BudgetReference()
{
  CBgtEntry *entry;
  Cd("~/Budget");
  bgt_string_file=FileNameAbs("Strs.DD.Z");
  bgt_accts_file=FileNameAbs("Accts.DD.Z");
  bgt_data_file=FileNameAbs("Bgt.DATA.Z");
  BgtAcctsRead;
  QueInit(&b_head);QueInit(&t_head);
  entry=CAlloc(sizeof(CBgtEntry));
  entry->date=(730000<<32)+0x10000000;
  entry->amount=125;
  entry->credit=StrNew("BANK");entry->debit=StrNew("RENT");entry->desc=StrNew("rent payment");
  BgtIns(entry);BgtDataWrite;
  ExportBudget(bgt_data_file,"budget.DATA");
  ExportBudget(bgt_string_file,"budget-strs.DD");
  BgtDel;
  BgtAcctsRead;BgtDataRead;
  entry=b_head.next;
  if(entry==&b_head || entry->next!=&b_head || entry->date!=(730000<<32)+0x10000000 ||
      entry->amount!=125 || StrCmp(entry->credit,"BANK") || StrCmp(entry->debit,"RENT") ||
      StrCmp(entry->desc,"rent payment")) {
    Report("FAIL Budget reopen\n");return;
  }
  Report("DONE original Budget storage reopen\n");
}
BudgetReference;
