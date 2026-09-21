//Retain the original document services in the console module.
#include "/Kernel/I386/Intrinsic.HH"
#include "/Kernel/I386/Queue.HH"
#define NULL 0
public _intern 0x15 CTask *Fs();
#include "/Kernel/DefineTypes.HH"
#include "/Kernel/ColorNames.HH"
import U8 *MAlloc(I64 size,CTask *task=0);
import U8 *CAlloc(I64 size,CTask *task=0);
import U0 Free(U8 *allocation);
import I64 MSize2(U8 *allocation);
import U8 *MAllocIdent(U8 *allocation,CTask *task=0);
import U8 *StrNew(U8 *str,CTask *task=0);
import U8 *MemCpy(U8 *dst,U8 *src,I64 count);
import U8 *MemSet(U8 *dst,I64 value,I64 count);
import CHashTable *HashTableNew(I64 size,CTask *task=0);
import I64 HashDefineLstAdd(U8 *name,I64 type,CHashTable *table);
import CHashDefineStr *DefineLstLoad(U8 *name,U8 *list);
#include "/Adam/DolDoc/DocGlobalsCore.HC"
#include "/Adam/DolDoc/DocInitCore.HC"
#include "/Adam/DolDoc/DocEntryAlloc.HC"
#include "/Adam/DolDoc/DocFormNav.HC"
extern U0 DocReportLiteral(I64 mS,U8 *message);
import CHash *HashFind(U8 *name,CHashTable *table,I64 mask,I64 instance=1);
extern U0 UndefinedDefine(U8 *name);
#include "/Kernel/ListFlags.HH"
#include "/Kernel/ListCore.HC"
#include "/Kernel/DefineLookupCore.HC"
extern U0 DocEntryDel(CDoc *doc,CDocEntry *doc_e);
import I64 StrCmp(U8 *left,U8 *right);
#define I32_MAX 0x7FFFFFFF
Bool DocLock(CDoc *doc) { return I386DocLock(doc); }
Bool DocUnlock(CDoc *doc) { return I386DocUnlock(doc); }
#include "/Adam/DolDoc/DocBinLife.HC"
#include "/Adam/DolDoc/DocEntryLife.HC"
CTask *console_document_owner;
U0 ConsoleDocumentStart()
{//Data belongs to the live console task; code and global record are retained.
  CTask *task=Fs;
  if(console_document_owner) {
    if(console_document_owner!=task) throw('DocOwner',TRUE);
    return;
  }
  DocGlobalsInit;
  DefineLstLoad("ST_COLORS",COLOR_NAMES_LIST);
  DocInit;
  console_document_owner=task;
}
