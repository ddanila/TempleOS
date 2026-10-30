//Exercise the original Budget account views with deliberately unsorted entries.
U0 Report(U8 *text) {while(*text)OutU8(0xE9,*text++);}
Cd("B:/");DirMk("B:/Home");HomeSet("B:/Home");
#include "T:/Apps/Budget/Load.HC"
#include "T:/Apps/Budget/Install.HC"
U0 BRAdd(I64 day,F64 amount,U8 *credit,U8 *debit,U8 *desc)
{
  CBgtEntry *entry=CAlloc(sizeof(CBgtEntry));
  entry->date=day<<32;entry->amount=amount;
  entry->credit=StrNew(credit);entry->debit=StrNew(debit);entry->desc=StrNew(desc);
  BgtIns(entry);
}
U0 BRExport(U8 *name)
{
  I64 size;U8 *data=DocSave(DocPut,&size),*line;
  line=MStrPrint("EXPORT %s %X %X\n",name,data,size);Report(line);Free(line); //Keep exported buffers alive for host readback.
}
U0 BudgetReportReference()
{
  Cd("~/Budget");bgt_accts_file=FileNameAbs("Accts.DD.Z");BgtAcctsRead;
  QueInit(&b_head);QueInit(&t_head);
  BRAdd(730002,30,"BANK","RENT","rent");
  BRAdd(730000,100,"WAGES","BANK","salary");
  BRAdd(730001,20,"BANK","FOOD","groceries");
  StrCpy(view_acct,"BANK");BgtRegen;BRExport("budget-bank.DD");
  StrCpy(view_acct,"RENT");BgtRegen;BRExport("budget-rent.DD");
  BgtDel;Report("DONE original Budget account views\n");
}
BudgetReportReference;
