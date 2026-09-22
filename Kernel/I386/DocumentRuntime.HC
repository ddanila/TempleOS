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
import U0 StrCpy(U8 *dst,U8 *src);
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
U0 NativeDocRstUnlocked(CDoc *doc,Bool is_old)
{
  CDocEntry *entry,*next;
  CDocUndo *undo,*next_undo;
  CDocBin *bin,*next_bin;
  CDocSettings *settings;
  if(is_old) {
    entry=doc->head.next;
    while(entry!=doc) { next=entry->next; DocEntryDel(doc,entry); entry=next; }
    undo=doc->undo_head.next;
    while(undo!=&doc->undo_head) { next_undo=undo->next; DocUndoDel(doc,undo); undo=next_undo; }
    bin=doc->bin_head.next;
    while(bin!=&doc->bin_head) {
      next_bin=bin->next; QueRem(bin); Free(bin->data); Free(bin); bin=next_bin;
    }
  }
  doc->flags&=DOCF_BREAK_UNLOCKED;
  doc->head.next=doc; doc->head.last=doc;
  QueInit(&doc->bin_head); QueInit(&doc->undo_head);
  doc->undo_head.time_stamp=0; doc->undo_cnt=0; doc->cur_bin_num=1;
  doc->dollar_buf_ptr=0; doc->cmd_U8=CH_SPACE; doc->page_line_num=0;
  doc->best_d=I64_MAX;
  settings=&doc->settings_head;
  settings->left_margin=DOC_DFT; settings->right_margin=DOC_DFT;
  settings->indent=0; settings->page_len=66;
  settings->header=DOC_DFT; settings->footer=DOC_DFT;
  settings->state=DOCSS_NORMAL; settings->comment_depth=0;
  settings->paren_depth=0; settings->brace_depth=0;
  settings->shifted_x=0; settings->shifted_y=0;
  //The original DOC_ATTR_DFT_TEXT is WHITE<<4+BLACK (0xF0).
  settings->cur_text_attr=0xF0;
  settings->dft_text_attr=0xF0;
  doc->head.type=DOCT_ERROR; doc->head.de_flags=0;
  doc->head.x=0; doc->head.y=0; doc->head.min_col=0; doc->head.max_col=0;
  doc->head.page_line_num=0;
  MemCpy(&doc->head.settings,settings,sizeof(CDocSettings));
  doc->cur_entry=&doc->head; doc->cur_col=0;
  doc->x=0; doc->y=0; doc->line_start_col=0; doc->top_line_num=0;
}
public U0 DocRst(CDoc *doc,Bool is_old)
{
  Bool unlock;
  if(!doc || doc->doc_signature!=DOC_SIGNATURE_VAL) return;
  unlock=DocLock(doc); NativeDocRstUnlocked(doc,is_old);
  if(unlock) DocUnlock(doc);
}
public CDoc *DocNew(U8 *filename=NULL,CTask *task=NULL)
{
  CDoc *doc;
  if(!task) task=Fs;
  doc=CAlloc(sizeof(CDoc),task);
  if(!doc) return NULL;
  if(filename) StrCpy(doc->filename.name,filename);
  else StrCpy(doc->filename.name,"C:/Tmp.DD.Z");
  doc->find_replace=CAlloc(sizeof(CEdFindText),task);
  doc->dollar_buf_size=84; doc->dollar_buf=MAlloc(84,task);
  if(!doc->find_replace || !doc->dollar_buf) {
    Free(doc->find_replace); Free(doc->dollar_buf); Free(doc); return NULL;
  }
  doc->find_replace->scan_fwd=TRUE; doc->find_replace->match_case=TRUE;
  doc->find_replace->pmt=TRUE; doc->max_entries=I64_MAX;
  doc->win_task=task; doc->mem_task=task;
  NativeDocRstUnlocked(doc,FALSE); doc->doc_signature=DOC_SIGNATURE_VAL;
  return doc;
}
public U0 DocDel(CDoc *doc)
{
  Bool unlock;
  if(!doc || doc->doc_signature!=DOC_SIGNATURE_VAL) return;
  unlock=DocLock(doc); NativeDocRstUnlocked(doc,TRUE);
  doc->doc_signature=0; Free(doc->find_replace); Free(doc->dollar_buf);
  if(unlock) DocUnlock(doc);
  Free(doc);
}
public I64 DocSize(CDoc *doc)
{
  CDocEntry *entry;
  CDocUndo *undo;
  CDocBin *bin;
  I64 result=0;
  Bool unlock;
  if(!doc || doc->doc_signature!=DOC_SIGNATURE_VAL) return 0;
  unlock=DocLock(doc);
  for(entry=doc->head.next;entry!=doc;entry=entry->next) result+=DocEntrySize(doc,entry);
  for(undo=doc->undo_head.next;undo!=&doc->undo_head;undo=undo->next) {
    result+=MSize2(undo->body); result+=MSize2(undo);
  }
  for(bin=doc->bin_head.next;bin!=&doc->bin_head;bin=bin->next) {
    result+=MSize2(bin->data); result+=MSize2(bin);
  }
  result+=MSize2(doc->find_replace)+MSize2(doc->dollar_buf)+MSize2(doc);
  if(unlock) DocUnlock(doc);
  return result;
}
#include "/Adam/DolDoc/DocBasicEditCore.HC"
public U0 DocPutKey(CDoc *doc,I64 ch=0,I64 sc=0)
{
  DocBasicEditCore(doc,ch,sc);
}
#include "/Adam/DolDoc/DocBasicSaveCore.HC"
public U8 *DocSave(CDoc *doc,I64 *_size=NULL)
{
  return DocBasicSaveCore(doc,_size);
}
#include "/Adam/DolDoc/DocBasicLoadCore.HC"
public Bool DocWrite(CDoc *doc,Bool prompt=FALSE)
{
  U8 *buffer;
  I64 size;
  Bool result;
  if(!doc || prompt || !console_config || !console_config->files ||
      !console_config->files->write) return FALSE;
  buffer=DocSave(doc,&size);
  if(!buffer) return FALSE;
  result=(*console_config->files->write)(doc->filename.name,buffer,size,doc->file_attr);
  Free(buffer); return result;
}
public CDoc *DocRead(U8 *name=NULL,I64 flags=0)
{
  CDoc *doc;
  U8 *buffer;
  I64 size=0,attr=0;
  if(!name || !console_config || !console_config->files || !console_config->files->read) return NULL;
  doc=DocNew(name,Fs); if(!doc) return NULL;
  doc->flags|=flags;
  buffer=(*console_config->files->read)(console_config->heap,name,&size,&attr,NULL);
  if(!buffer || !DocBasicLoadCore(doc,buffer,size)) {
    if(buffer) I386HeapFree(console_config->heap,buffer);
    DocDel(doc); return NULL;
  }
  doc->file_attr=attr; I386HeapFree(console_config->heap,buffer); return doc;
}
U0 NativeDocEditDraw(CDoc *doc)
{
  U8 *saved;
  I64 size,index;
  if(!I386TextInit(&console_text,console_planes,sys_font_std)) KernelStop;
  I386TextWrite(&console_text,"TempleOS i386\nDolDoc editor\n");
  I386TextWrite(&console_text,doc->filename.name); I386TextWrite(&console_text,"\n\n");
  saved=DocSave(doc,&size);
  if(!saved) return;
  for(index=0;index<size;index++) {
    if(saved[index]==CH_CURSOR) I386TextPut(&console_text,0xDB);
    else I386TextPut(&console_text,saved[index]);
  }
  Free(saved); ConsolePresent;
}
public Bool DocEd(CDoc *doc,I64 flags=0)
{//Native keyboard/VGA session over the canonical document model. Escape exits.
  CI386KeyEvent event;
  CDoc *old_put,*old_display;
  I64 decoded;
  Bool done=FALSE,changed;
  if(!doc || doc->doc_signature!=DOC_SIGNATURE_VAL || flags) return FALSE;
  old_put=Fs->put_doc; old_display=Fs->display_doc;
  Fs->put_doc=Fs->display_doc=doc;
  KernelLog("DOC EDIT begin\n"); NativeDocEditDraw(doc);
  while(!done) {
    decoded=I386KeyboardRead(console_config->reader,&event,TRUE);
    changed=FALSE;
    if(decoded>0) {
      if(event.type==2 && event.ch==27) done=TRUE;
      else if(event.type==2 && (event.ch==8 || 0x20<=event.ch<0x100)) {
        DocPutKey(doc,event.ch,0); changed=TRUE;
      } else if(event.type==3 && event.scan.u8[0]==0x4B) {
        DocPutKey(doc,0,event.scan); changed=TRUE;
      }
    }
    if(changed) NativeDocEditDraw(doc);
  }
  Fs->put_doc=old_put; Fs->display_doc=old_display;
  if(!I386TextInit(&console_text,console_planes,sys_font_std)) KernelStop;
  I386TextWrite(&console_text,"TempleOS i386\nHolyC console\n\n");
  ConsolePresent; KernelLog("DOC EDIT end\n"); return TRUE;
}
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

#include "/Kernel/I386/Date.HC"

#include "/Kernel/I386/GraphicsContext.HC"
