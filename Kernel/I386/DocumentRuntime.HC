//Retain the original document services in the console module.
#include "/Kernel/I386/Intrinsic.HH"
#include "/Kernel/I386/Queue.HH"
#include "/Kernel/GraphicsTypes.HH"
#define NULL 0
public _intern 0x15 CTask *Fs();
#include "/Kernel/DefineTypes.HH"
#include "/Kernel/ColorNames.HH"
#include "/Kernel/TimeTypes.HH"
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
I64 native_doc_alloc_fail_after,native_doc_alloc_count;
Bool native_dir_mouse_visible,native_help_mouse_visible;
extern U0 NativeDocMouseShow(U8 *planes,I64 x,I64 y);
extern U0 NativeMousePlaneMove(U8 *planes,I64 old_x,I64 old_y,I64 x,I64 y);
U0 NativeDocAllocArm(I64 fail_after)
{
  native_doc_alloc_fail_after=fail_after; native_doc_alloc_count=0;
}
U8 *NativeDocMAlloc(I64 size,CTask *task=0)
{
  if(native_doc_alloc_fail_after &&
      ++native_doc_alloc_count==native_doc_alloc_fail_after) throw('OutMem',TRUE);
  return MAlloc(size,task);
}
U8 *NativeDocCAlloc(I64 size,CTask *task=0)
{
  if(native_doc_alloc_fail_after &&
      ++native_doc_alloc_count==native_doc_alloc_fail_after) throw('OutMem',TRUE);
  return CAlloc(size,task);
}
#include "/Adam/DolDoc/DocGlobalsCore.HC"
#include "/Adam/DolDoc/DocInitCore.HC"
#define MAlloc NativeDocMAlloc
#define CAlloc NativeDocCAlloc
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
  CDoc *doc=NULL;
  if(!task) task=Fs;
  try {
    doc=NativeDocCAlloc(sizeof(CDoc),task);
    if(filename) StrCpy(doc->filename.name,filename);
    else StrCpy(doc->filename.name,"C:/Tmp.DD.Z");
    doc->find_replace=NativeDocCAlloc(sizeof(CEdFindText),task);
    doc->dollar_buf_size=84; doc->dollar_buf=NativeDocMAlloc(84,task);
    doc->find_replace->scan_fwd=TRUE; doc->find_replace->match_case=TRUE;
    doc->find_replace->pmt=TRUE; doc->max_entries=I64_MAX;
    doc->win_task=task; doc->mem_task=task;
    NativeDocRstUnlocked(doc,FALSE); doc->doc_signature=DOC_SIGNATURE_VAL;
  } catch {
    if(doc) { Free(doc->find_replace); Free(doc->dollar_buf); Free(doc); }
  }
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
#include "/Kernel/I386/DocRecordSaveCore.HC"
#include "/Kernel/I386/DocRecordLoadCore.HC"
public U8 *DocSave(CDoc *doc,I64 *_size=NULL)
{
  return NativeDocRecordSaveCore(doc,_size);
}
Bool NativeDocAllocationCaught(U0 (*action)(CDoc *doc),CDoc *doc)
{
  Bool caught=FALSE;
  try { (*action)(doc); }
  catch {
    if(Fs->except_ch=='OutMem') { Fs->catch_except=TRUE; caught=TRUE; }
  }
  NativeDocAllocArm(0);
  return caught;
}
U0 NativeDocAllocationPut(CDoc *doc) { DocPutKey(doc,'X',0); }
U0 NativeDocAllocationNewLine(CDoc *doc) { DocPutKey(doc,'\n',0); }
U0 NativeDocAllocationSave(CDoc *doc) { U8 *text=DocSave(doc); Free(text); }
I64 NativeDocRecordSaveCheck()
{
  CDoc *doc,*loaded;
  CDocEntry *entry;
  U8 *saved,*round_trip;
  I64 before=Fs->data_heap->used_u8s,size,round_trip_size,result=4,index;
  doc=DocNew("C:/Record.DD",Fs);
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_FOREGROUND; entry->de_flags=doldoc.dft_de_flags[DOCT_FOREGROUND];
  entry->attr=2; DocInsEntry(doc,entry);
  DocPutKey(doc,'r'); DocPutKey(doc,'e'); DocPutKey(doc,'d');
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_FOREGROUND; entry->de_flags=doldoc.dft_de_flags[DOCT_FOREGROUND];
  entry->attr=DOC_DFT; DocInsEntry(doc,entry);
  DocPutKey(doc,' '); DocPutKey(doc,'p'); DocPutKey(doc,'l');
  DocPutKey(doc,'a'); DocPutKey(doc,'i'); DocPutKey(doc,'n');
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_BACKGROUND; entry->de_flags=doldoc.dft_de_flags[DOCT_BACKGROUND];
  entry->attr=1; DocInsEntry(doc,entry);
  DocPutKey(doc,'b'); DocPutKey(doc,'l'); DocPutKey(doc,'u'); DocPutKey(doc,'e');
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_BACKGROUND; entry->de_flags=doldoc.dft_de_flags[DOCT_BACKGROUND];
  entry->attr=DOC_DFT; DocInsEntry(doc,entry);
  DocPutKey(doc,' '); DocPutKey(doc,'e'); DocPutKey(doc,'n'); DocPutKey(doc,'d');
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_INVERT; entry->de_flags=doldoc.dft_de_flags[DOCT_INVERT];
  entry->attr=1; DocInsEntry(doc,entry);
  DocPutKey(doc,' '); DocPutKey(doc,'i'); DocPutKey(doc,'n'); DocPutKey(doc,'v');
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_INVERT; entry->de_flags=doldoc.dft_de_flags[DOCT_INVERT];
  entry->attr=0; DocInsEntry(doc,entry);
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_UNDERLINE; entry->de_flags=doldoc.dft_de_flags[DOCT_UNDERLINE];
  entry->attr=1; DocInsEntry(doc,entry);
  DocPutKey(doc,' '); DocPutKey(doc,'u'); DocPutKey(doc,'n'); DocPutKey(doc,'d');
  DocPutKey(doc,'e'); DocPutKey(doc,'r');
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_UNDERLINE; entry->de_flags=doldoc.dft_de_flags[DOCT_UNDERLINE];
  entry->attr=0; DocInsEntry(doc,entry);
  DocPutKey(doc,' '); DocPutKey(doc,'d'); DocPutKey(doc,'o'); DocPutKey(doc,'n');
  DocPutKey(doc,'e');
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_BLINK; entry->de_flags=doldoc.dft_de_flags[DOCT_BLINK];
  entry->attr=1; DocInsEntry(doc,entry);
  DocPutKey(doc,' '); DocPutKey(doc,'f'); DocPutKey(doc,'l'); DocPutKey(doc,'a');
  DocPutKey(doc,'s'); DocPutKey(doc,'h');
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_BLINK; entry->de_flags=doldoc.dft_de_flags[DOCT_BLINK];
  entry->attr=0; DocInsEntry(doc,entry);
  doc->flags|=DOCF_NO_CURSOR;
  saved=NativeDocRecordSaveCore(doc,&size);
  if(!saved || size!=94) result=-20;
  else {
    for(index=0;index<94;index++) {
      if(index==0 || index==5 || index==9 || index==12 || index==19 ||
          index==24 || index==29 || index==32 || index==37 || index==42 ||
          index==47 || index==52 || index==53 || index==58 || index==65 ||
          index==70 || index==76 || index==81 || index==88 || index==93) {
        if(saved[index]!=36) result=-21-index;
      }
    }
    if(saved[1]!='F' || saved[2]!='G' || saved[3]!=',' || saved[4]!='2' ||
        saved[6]!='r' || saved[7]!='e' || saved[8]!='d' ||
        saved[10]!='F' || saved[11]!='G' ||
        saved[20]!='B' || saved[21]!='G' || saved[22]!=',' || saved[23]!='1' ||
        saved[25]!='b' || saved[26]!='l' || saved[27]!='u' || saved[28]!='e' ||
        saved[30]!='B' || saved[31]!='G' ||
        saved[38]!='I' || saved[39]!='V' || saved[41]!='1' ||
        saved[48]!='I' || saved[49]!='V' || saved[51]!='0' ||
        saved[54]!='U' || saved[55]!='L' || saved[57]!='1' ||
        saved[66]!='U' || saved[67]!='L' || saved[69]!='0' ||
        saved[77]!='B' || saved[78]!='K' || saved[80]!='1' ||
        saved[89]!='B' || saved[90]!='K' || saved[92]!='0' ||
        saved[71]!=' ' || saved[72]!='d' || saved[82]!=' ' ||
        saved[83]!='f' || saved[87]!='h') result=-40;
  }
  loaded=DocNew("C:/RecordRead.DD",Fs); loaded->flags|=DOCF_NO_CURSOR;
  if(result==4 && !NativeDocRecordLoadCore(loaded,saved,size)) result=-41;
  round_trip=NativeDocRecordSaveCore(loaded,&round_trip_size);
  if(result==4 && (!round_trip || round_trip_size!=size)) result=-42;
  else if(result==4) for(index=0;index<size;index++)
    if(round_trip[index]!=saved[index]) result=-43;
  Free(round_trip); Free(saved); DocDel(loaded); DocDel(doc);
  if(Fs->data_heap->used_u8s!=before) result=-44;
  return result;
}
I64 NativeDocBinarySaveCheck()
{
  CDoc *doc,*loaded,*truncated,*failed;
  CDocEntry *entry;
  CDocBin *bin;
  U8 *first,*second;
  I64 before=Fs->data_heap->used_u8s,first_size,second_size,index,result=5,
      fail,fail_before;
  Bool caught;
  doc=DocNew("C:/BinaryRecord.DD",Fs); doc->flags|=DOCF_NO_CURSOR;
  bin=CAlloc(sizeof(CDocBin),doc->mem_task);
  bin->num=7; bin->flags=0x1234; bin->size=5; bin->use_cnt=1;
  bin->data=MAlloc(5,doc->mem_task);
  bin->data[0]=1; bin->data[1]=2; bin->data[2]=0; bin->data[3]=0xFF; bin->data[4]=42;
  QueIns(bin,doc->bin_head.last);
  entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
  entry->type=DOCT_SPRITE;
  entry->de_flags=doldoc.dft_de_flags[DOCT_SPRITE]|DOCEF_HAS_BIN;
  entry->tag=StrNew("dot",doc->mem_task); entry->bin_num=7; entry->bin_data=bin;
  DocInsEntry(doc,entry);
  first=DocSave(doc,&first_size);
  if(!first || first_size!=37 || first[0]!=36 || first[1]!='S' || first[2]!='P' ||
      first[5]!='d' || first[7]!='t' || first[13]!='1' || first[14]!=36 ||
      first[15] || first[16]!=1 || first[20]!=0x34 || first[21]!=0x12 ||
      first[24]!=5 || first[28]!=1 || first[32]!=1 || first[33]!=2 ||
      first[34]!=0 || first[35]!=0xFF || first[36]!=42) result=-1;
  loaded=DocNew("C:/BinaryRecordRead.DD",Fs); loaded->flags|=DOCF_NO_CURSOR;
  if(result==5 && !NativeDocRecordLoadCore(loaded,first,first_size)) result=-2;
  entry=loaded->head.next; bin=loaded->bin_head.next;
  if(result==5 && (entry==loaded || entry->next!=loaded || entry->type_u8!=DOCT_SPRITE ||
      StrCmp(entry->tag,"dot") || entry->bin_num!=1 || entry->bin_data!=bin ||
      bin==&loaded->bin_head || bin->next!=&loaded->bin_head || bin->size!=5 ||
      bin->use_cnt!=1 || bin->data[0]!=1 || bin->data[4]!=42)) result=-3;
  second=DocSave(loaded,&second_size);
  if(result==5 && (!second || second_size!=first_size)) result=-4;
  else if(result==5) for(index=0;index<first_size;index++)
    if(first[index]!=second[index]) result=-5;
  for(fail=1;fail<=4 && result==5;fail++) {
    fail_before=Fs->data_heap->used_u8s;
    failed=DocNew("C:/BinaryRecordFail.DD",Fs); caught=FALSE;
    NativeDocAllocArm(fail);
    try { NativeDocRecordLoadCore(failed,first,first_size); }
    catch {
      if(Fs->except_ch=='OutMem') { Fs->catch_except=TRUE; caught=TRUE; }
    }
    NativeDocAllocArm(0); DocDel(failed);
    if(!caught || Fs->data_heap->used_u8s!=fail_before) result=-8-fail;
  }
  truncated=DocNew("C:/BinaryRecordBad.DD",Fs);
  if(result==5 && NativeDocRecordLoadCore(truncated,first,first_size-1)) result=-6;
  Free(second); Free(first); DocDel(truncated); DocDel(loaded); DocDel(doc);
  if(Fs->data_heap->used_u8s!=before) result=-7;
  return result;
}
I64 NativeDocAllocationCoreCheck()
{
  CDoc *doc=NULL;
  U8 *text;
  I64 before=Fs->data_heap->used_u8s,base,size,i,caught=0;
  for(i=1;i<=3;i++) {
    NativeDocAllocArm(i);
    try { doc=DocNew("C:/AllocFail.DD",Fs); }
    catch {
      if(Fs->except_ch=='OutMem') { Fs->catch_except=TRUE; caught++; }
    }
    NativeDocAllocArm(0);
    if(doc) { DocDel(doc); doc=NULL; }
    if(Fs->data_heap->used_u8s!=before) return -i;
  }
  doc=DocNew("C:/AllocFail.DD",Fs);
  base=Fs->data_heap->used_u8s;
  NativeDocAllocArm(1);
  if(!NativeDocAllocationCaught(&NativeDocAllocationPut,doc) ||
      doc->owning_task || Bt(&doc->locked_flags,DOClf_LOCKED) ||
      Fs->data_heap->used_u8s!=base || doc->head.next!=doc) return -4;
  NativeDocAllocArm(2);
  if(!NativeDocAllocationCaught(&NativeDocAllocationPut,doc) ||
      doc->owning_task || Bt(&doc->locked_flags,DOClf_LOCKED) ||
      Fs->data_heap->used_u8s!=base || doc->head.next!=doc) return -5;
  DocPutKey(doc,'a',0);
  doc->cur_entry=doc->head.next; doc->cur_col=1;
  base=Fs->data_heap->used_u8s;
  NativeDocAllocArm(1);
  if(!NativeDocAllocationCaught(&NativeDocAllocationPut,doc) ||
      doc->owning_task || Bt(&doc->locked_flags,DOClf_LOCKED) ||
      Fs->data_heap->used_u8s!=base || StrCmp(doc->head.next->tag,"a")) return -6;
  NativeDocAllocArm(1);
  if(!NativeDocAllocationCaught(&NativeDocAllocationNewLine,doc) ||
      doc->owning_task || Bt(&doc->locked_flags,DOClf_LOCKED) ||
      Fs->data_heap->used_u8s!=base || doc->head.next->next!=doc) return -7;
  NativeDocAllocArm(1);
  if(!NativeDocAllocationCaught(&NativeDocAllocationSave,doc) ||
      doc->owning_task || Bt(&doc->locked_flags,DOClf_LOCKED) ||
      Fs->data_heap->used_u8s!=base) return -8;
  DocPutKey(doc,'Z',0); text=DocSave(doc,&size);
  if(!text || size!=3 || text[0]!='a' || text[1]!='Z' || text[2]!=CH_CURSOR) {
    Free(text); DocDel(doc); return -9;
  }
  Free(text); DocDel(doc);
  if(Fs->data_heap->used_u8s!=before) return -10;
  return caught+5;
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
public Bool DirMk(U8 *filename,I64 entry_cnt=0)
{
  if(!console_config || !console_config->files || !console_config->files->dir_mk)
    return FALSE;
  return (*console_config->files->dir_mk)(filename,entry_cnt);
}
public I64 Dir(U8 *filename=NULL)
{
  U8 *listing;
  I64 needed,count=0;
  if(!filename) filename="C:/";
  if(!console_config || !console_config->files || !console_config->files->dir_list)
    return -1;
  needed=(*console_config->files->dir_list)(filename,NULL,0,&count);
  if(!needed || !(listing=MAlloc(needed))) return -1;
  if((*console_config->files->dir_list)(filename,listing,needed,&count)!=needed) {
    Free(listing); return -1;
  }
  I386TextWrite(&console_text,listing); Free(listing); return count;
}
public Bool FileDel(U8 *filename)
{
  if(!filename || !console_config || !console_config->files ||
      !console_config->files->del) return FALSE;
  return (*console_config->files->del)(filename);
}
public Bool FileRename(U8 *old_filename,U8 *new_filename)
{
  if(!old_filename || !new_filename || !console_config || !console_config->files ||
      !console_config->files->rename) return FALSE;
  return (*console_config->files->rename)(old_filename,new_filename);
}
public Bool DirDel(U8 *filename)
{
  if(!filename || !console_config || !console_config->files ||
      !console_config->files->dir_del) return FALSE;
  return (*console_config->files->dir_del)(filename);
}
public Bool FileMove(U8 *old_filename,U8 *new_filename)
{
  if(!old_filename || !new_filename || !console_config || !console_config->files ||
      !console_config->files->move) return FALSE;
  return (*console_config->files->move)(old_filename,new_filename);
}
extern Bool Ed(U8 *filename,I64 flags);
extern U0 NativeDocEditConsoleRestore();
Bool NativeDirListing(U8 *directory,U8 **listing,I64 *entries)
{
  I64 needed;
  *listing=NULL; *entries=0;
  if(!console_config || !console_config->files || !console_config->files->dir_list)
    return FALSE;
  needed=(*console_config->files->dir_list)(directory,NULL,0,entries);
  if(!needed || !(*listing=MAlloc(needed))) return FALSE;
  if((*console_config->files->dir_list)(directory,*listing,needed,entries)!=needed) {
    Free(*listing); *listing=NULL; *entries=0; return FALSE;
  }
  return TRUE;
}
U8 *NativeDirPathJoin(U8 *directory,U8 *name)
{
  U8 *result;
  I64 left=StrLen(directory),right=StrLen(name),at=0,i;
  Bool slash=left && directory[left-1]=='/';
  result=MAlloc(left+right+2);
  if(!result) return NULL;
  for(i=0;i<left;i++) result[at++]=directory[i];
  if(!slash) result[at++]='/';
  for(i=0;i<right;i++) result[at++]=name[i];
  result[at]=0; return result;
}
U8 *NativeDirPathCopy(U8 *path)
{
  U8 *result;
  I64 index,length=StrLen(path);
  if(!(result=MAlloc(length+1))) return NULL;
  for(index=0;index<=length;index++) result[index]=path[index];
  return result;
}
U8 *NativeDirPathTrim(U8 *path)
{
  I64 length=StrLen(path);
  while(length>1 && path[length-1]=='/' &&
        !(length==3 && path[1]==':')) path[--length]=0;
  return path;
}
U8 *NativeDirPathParent(U8 *directory)
{
  U8 *result;
  I64 index,length;
  if(!(result=NativeDirPathCopy(directory))) return NULL;
  NativeDirPathTrim(result); length=StrLen(result);
  if(length==1 && result[0]=='/' || length==3 && result[1]==':') return result;
  index=length;
  while(index && result[index-1]!='/') index--;
  if(!index) {
    Free(result);
    if(!(result=MAlloc(2))) return NULL;
    result[0]='.'; result[1]=0; return result;
  }
  if(index==3 && result[1]==':') result[3]=0;
  else if(index==1) result[1]=0;
  else result[index-1]=0;
  return result;
}
U8 **NativeDirPickerLoad(U8 *directory,U8 **listing,I64 *count)
{
  U8 *cursor,*line;
  U8 **items;
  I64 entries=0,length,at=0;
  *listing=NULL; *count=0;
  if(!NativeDirListing(directory,listing,&entries)) return NULL;
  if(!(items=CAlloc(entries*sizeof(U8 *)))) {
    Free(*listing); *listing=NULL; return NULL;
  }
  cursor=*listing;
  while(*cursor) {
    line=cursor;
    while(*cursor && *cursor!='\n') cursor++;
    length=cursor-line;
    if(*cursor) *cursor++=0;
    if(!(length==2 && line[0]=='.' && line[1]=='/' ||
         length==3 && line[0]=='.' && line[1]=='.' && line[2]=='/')) {
      items[at]=line;
      at++;
    }
  }
  *count=at;
  return items;
}
I64 NativeDirPickerFind(U8 **items,I64 count,U8 *name)
{
  I64 index;
  for(index=0;index<count;index++)
    if(!StrCmp(items[index],name)) return index;
  return 0;
}
U0 NativeDirPickerDraw(U8 *directory,U8 **items,I64 count,I64 selected,
  U8 *new_name=NULL,U8 *delete_name=NULL,Bool rename=FALSE)
{
  I64 index,top=0,end,mouse_x,mouse_y;
  if(!I386TextInit(&console_text,console_planes,sys_font_std)) KernelStop;
  I386TextWrite(&console_text,"TempleOS i386\nFile picker");
  if(new_name && rename) I386TextWrite(&console_text," - Rename");
  else if(new_name) I386TextWrite(&console_text," - New file");
  else if(delete_name) I386TextWrite(&console_text," - Delete");
  I386TextWrite(&console_text,"\n");
  I386TextWrite(&console_text,directory); I386TextWrite(&console_text,"\n\n");
  if(new_name) {
    if(rename) I386TextWrite(&console_text,"New name: ");
    else I386TextWrite(&console_text,"Name: ");
    I386TextWrite(&console_text,new_name);
    I386TextPut(&console_text,0xDB); ConsolePresent;
    if(native_dir_mouse_visible && MouseGet(&mouse_x,&mouse_y))
      NativeDocMouseShow(console_planes,mouse_x,mouse_y);
    return;
  }
  if(delete_name) {
    end=StrLen(delete_name);
    if(end && delete_name[end-1]=='/') I386TextWrite(&console_text,"Delete empty ");
    else I386TextWrite(&console_text,"Delete ");
    I386TextWrite(&console_text,delete_name);
    I386TextWrite(&console_text,"? Y/N"); ConsolePresent;
    if(native_dir_mouse_visible && MouseGet(&mouse_x,&mouse_y))
      NativeDocMouseShow(console_planes,mouse_x,mouse_y);
    return;
  }
  if(selected>=56) top=selected-55;
  end=MinI64(count,top+56);
  if(!count) I386TextWrite(&console_text,"(no files)");
  for(index=top;index<end;index++) {
    if(index==selected) I386TextWrite(&console_text,"> ");
    else I386TextWrite(&console_text,"  ");
    I386TextWrite(&console_text,items[index]);
    if(index+1<end) I386TextWrite(&console_text,"\n");
  }
  ConsolePresent;
  if(native_dir_mouse_visible && MouseGet(&mouse_x,&mouse_y))
    NativeDocMouseShow(console_planes,mouse_x,mouse_y);
}
Bool NativeDirPicker(U8 *directory,U8 **picked,Bool pick_directory=FALSE)
{//Browse/edit normally, or return one selected file/directory to the caller.
  CI386KeyEvent event;
  U8 *current=NULL,*listing=NULL,**items=NULL,*path,*new_path,*new_listing;
  U8 **new_items;
  U8 new_name[64];
  I64 count=0,new_count,selected=0,decoded,length,new_length=0,
      mouse_x,mouse_y,mouse_buttons=0,mouse_packets=0,next_mouse_x,next_mouse_y,
      next_mouse_buttons,next_mouse_packets,mouse_top,mouse_item,
      last_mouse_item=-1,last_mouse_jiffy=0,mouse_jiffy;
  Bool done=FALSE,result=FALSE,new_mode=FALSE,rename_mode=FALSE,delete_mode=FALSE;
  Bool rename_directory,delete_directory,resume_mouse,activate;
  if(!directory) directory="C:/";
  if(!(current=NativeDirPathCopy(directory))) return FALSE;
  NativeDirPathTrim(current);
  if(!(items=NativeDirPickerLoad(current,&listing,&count))) {
    Free(current); return FALSE;
  }
  MouseGet(&mouse_x,&mouse_y,&mouse_buttons,&mouse_packets);
  native_dir_mouse_visible=FALSE;
  KernelLog("FILE PICK begin\n"); NativeDirPickerDraw(current,items,count,selected);
  try {
    while(!done) {
      activate=FALSE;
      decoded=I386KeyboardRead(console_config->reader,&event,FALSE);
      if(decoded>0) {
        last_mouse_item=-1;
        if(delete_mode) {
          if(event.type==2 && (event.ch=='y' || event.ch=='Y')) {
            length=StrLen(items[selected]);
            delete_directory=length && items[selected][length-1]=='/';
            if(delete_directory) items[selected][--length]=0;
            path=NativeDirPathJoin(current,items[selected]);
            if(delete_directory) items[selected][length]='/';
            if(path) {
              if(delete_directory) DirDel(path); else FileDel(path);
              Free(path);
            }
            if((new_items=NativeDirPickerLoad(current,&new_listing,&new_count))) {
              Free(items); Free(listing); items=new_items; listing=new_listing;
              count=new_count;
              if(selected>=count && count) selected=count-1;
              if(!count) selected=0;
            }
            delete_mode=FALSE; NativeDirPickerDraw(current,items,count,selected);
          } else if(event.type==2 && (event.ch==CH_ESC || event.ch=='n' ||
                    event.ch=='N')) {
            delete_mode=FALSE; NativeDirPickerDraw(current,items,count,selected);
          }
        } else if(new_mode || rename_mode) {
          if(event.type==2 && event.ch==CH_ESC) {
            new_mode=FALSE; rename_mode=FALSE; new_length=0; new_name[0]=0;
            NativeDirPickerDraw(current,items,count,selected);
          } else if(event.type==2 && event.ch==CH_BACKSPACE && new_length) {
            new_name[--new_length]=0;
            NativeDirPickerDraw(current,items,count,selected,new_name,NULL,rename_mode);
          } else if(event.type==2 && event.ch=='\n' && new_length) {
            path=NativeDirPathJoin(current,new_name);
            if(path && rename_mode) {
              length=StrLen(items[selected]);
              rename_directory=length && items[selected][length-1]=='/';
              if(rename_directory) items[selected][--length]=0;
              new_path=NativeDirPathJoin(current,items[selected]);
              if(rename_directory) items[selected][length]='/';
              if(new_path) {
                result=FileRename(new_path,path); Free(new_path);
                if(result && (new_items=NativeDirPickerLoad(current,&new_listing,&new_count))) {
                  Free(items); Free(listing); items=new_items; listing=new_listing;
                  count=new_count;
                  if(rename_directory) {
                    new_name[new_length++]='/'; new_name[new_length]=0;
                    selected=NativeDirPickerFind(items,count,new_name);
                    new_name[--new_length]=0;
                  } else selected=NativeDirPickerFind(items,count,new_name);
                }
              }
              Free(path);
            } else if(path) {
              KernelLog("FILE PICK edit\n"); resume_mouse=native_dir_mouse_visible;
              result=Ed(path,0); Free(path);
              native_dir_mouse_visible=resume_mouse;
              if((new_items=NativeDirPickerLoad(current,&new_listing,&new_count))) {
                Free(items); Free(listing); items=new_items; listing=new_listing;
                count=new_count; selected=NativeDirPickerFind(items,count,new_name);
              }
            }
            new_mode=FALSE; rename_mode=FALSE; new_length=0; new_name[0]=0;
            NativeDirPickerDraw(current,items,count,selected);
          } else if(event.type==2 && 0x20<=event.ch<0x7F && event.ch!='/' &&
                    event.ch!='\\' && event.ch!=':' && new_length<63) {
            new_name[new_length++]=event.ch; new_name[new_length]=0;
            NativeDirPickerDraw(current,items,count,selected,new_name,NULL,rename_mode);
          }
        } else if(event.type==2 && event.ch==CH_ESC) done=TRUE;
        else if(event.type==2 && (event.ch=='n' || event.ch=='N')) {
          new_mode=TRUE; new_length=0; new_name[0]=0;
          NativeDirPickerDraw(current,items,count,selected,new_name);
        }
        else if(event.type==2 && (event.ch=='r' || event.ch=='R') && count) {
          rename_mode=TRUE; new_length=0; new_name[0]=0;
          NativeDirPickerDraw(current,items,count,selected,new_name,NULL,TRUE);
        }
        else if(event.type==3 && event.scan.u8[0]==SC_DELETE && count) {
          delete_mode=TRUE;
          NativeDirPickerDraw(current,items,count,selected,NULL,items[selected]);
        }
        else if(event.type==3 && event.scan.u8[0]==SC_CURSOR_UP && selected>0) {
          selected--; NativeDirPickerDraw(current,items,count,selected);
        } else if(event.type==3 && event.scan.u8[0]==SC_CURSOR_DOWN && selected+1<count) {
          selected++; NativeDirPickerDraw(current,items,count,selected);
        } else if(event.type==2 && event.ch==CH_BACKSPACE) {
          path=NativeDirPathParent(current);
          if(path && (new_items=NativeDirPickerLoad(path,&new_listing,&new_count))) {
            Free(items); Free(listing); Free(current);
            current=path; listing=new_listing; items=new_items;
            count=new_count; selected=0; path=NULL;
            NativeDirPickerDraw(current,items,count,selected);
          }
          if(path) Free(path);
        } else if(event.type==2 && event.ch=='\n' && count) activate=TRUE;
      }
      if(MouseGet(&next_mouse_x,&next_mouse_y,&next_mouse_buttons,&next_mouse_packets) &&
          next_mouse_packets!=mouse_packets) {
        native_dir_mouse_visible=TRUE;
        if(next_mouse_buttons&1 && !(mouse_buttons&1) &&
            !new_mode && !rename_mode && !delete_mode && count &&
            32<=next_mouse_y<480) {
          if(selected>=56) mouse_top=selected-55; else mouse_top=0;
          mouse_item=mouse_top+(next_mouse_y>>3)-4;
          if(0<=mouse_item<count) {
            selected=mouse_item;
            NativeDirPickerDraw(current,items,count,selected);
            KernelLog("FILE PICK mouse selection\n");
            if(console_config->jiffies) {
              mouse_jiffy=*console_config->jiffies;
              if(mouse_item==last_mouse_item &&
                  0<=mouse_jiffy-last_mouse_jiffy<=500) {
                activate=TRUE; last_mouse_item=-1;
                KernelLog("FILE PICK mouse activate\n");
              } else {
                last_mouse_item=mouse_item; last_mouse_jiffy=mouse_jiffy;
              }
            }
          }
        } else if(next_mouse_x!=mouse_x || next_mouse_y!=mouse_y)
          NativeMousePlaneMove(console_planes,mouse_x,mouse_y,next_mouse_x,next_mouse_y);
        mouse_x=next_mouse_x; mouse_y=next_mouse_y;
        mouse_buttons=next_mouse_buttons; mouse_packets=next_mouse_packets;
      }
      if(activate && count) {
          path=NativeDirPathJoin(current,items[selected]);
          if(path) {
            length=StrLen(items[selected]);
            if(length && items[selected][length-1]=='/') {
              NativeDirPathTrim(path);
              if(picked && pick_directory) {
                *picked=path; path=NULL; result=TRUE; done=TRUE;
              } else if((new_items=NativeDirPickerLoad(path,&new_listing,&new_count))) {
                Free(items); Free(listing); Free(current);
                current=path; listing=new_listing; items=new_items;
                count=new_count; selected=0; path=NULL;
                NativeDirPickerDraw(current,items,count,selected);
              }
            } else if(picked && !pick_directory) {
              *picked=path; path=NULL; result=TRUE; done=TRUE;
            } else {
              KernelLog("FILE PICK edit\n"); resume_mouse=native_dir_mouse_visible;
              result=Ed(path,0);
              native_dir_mouse_visible=resume_mouse;
              NativeDirPickerDraw(current,items,count,selected);
            }
            if(path) Free(path);
          }
      }
      if(!decoded) { I386SchedYield(I386TaskSelf->owner); I386TaskBreakPoll; }
    }
  } catch { NativeDocEditConsoleRestore; KernelLog("FILE PICK exception\n"); }
  Free(items); Free(listing); Free(current); NativeDocEditConsoleRestore;
  KernelLog("FILE PICK end\n"); return result;
}
public Bool EdDir(U8 *directory=NULL)
{//Browse directories and edit a selected file; Escape returns to prompt.
  return NativeDirPicker(directory,NULL,FALSE);
}
public CDoc *DocRead(U8 *name=NULL,I64 flags=0)
{
  CDoc *doc=NULL;
  U8 *buffer=NULL;
  I64 size=0,attr=0;
  if(!name || !console_config || !console_config->files || !console_config->files->read) return NULL;
  try {
    doc=DocNew(name,Fs);
    doc->flags|=flags;
    buffer=(*console_config->files->read)(console_config->heap,name,&size,&attr,NULL);
    if(!buffer || !NativeDocRecordLoadCore(doc,buffer,size)) {
      if(buffer) I386HeapFree(console_config->heap,buffer);
      DocDel(doc); return NULL;
    }
    doc->file_attr=attr; I386HeapFree(console_config->heap,buffer);
  } catch {
    if(buffer) I386HeapFree(console_config->heap,buffer);
    DocDel(doc);
  }
  return doc;
}
I64 NativeDocClipPasteAtomicCheck();
public I64 DocAllocationCheck()
{
  CDoc *doc,*read_doc=NULL;
  U8 *saved;
  I64 before,caught=0,result=NativeDocRecordSaveCheck,size;
  if(result!=4) return result;
  result=NativeDocBinarySaveCheck;
  if(result!=5) return result;
  result=NativeDocAllocationCoreCheck;
  if(result!=8) return result;
  result=NativeDocClipPasteAtomicCheck;
  if(result<=0) return result;
  doc=DocNew("C:/AllocRead.DD",Fs);
  DocPutKey(doc,'r',0); DocPutKey(doc,'e',0); DocPutKey(doc,'a',0); DocPutKey(doc,'d',0);
  if(!DocWrite(doc)) { DocDel(doc); return -11; }
  DocDel(doc); before=Fs->data_heap->used_u8s;
  NativeDocAllocArm(4);
  try { read_doc=DocRead("C:/AllocRead.DD"); }
  catch {
    if(Fs->except_ch=='OutMem') { Fs->catch_except=TRUE; caught=1; }
  }
  NativeDocAllocArm(0);
  if(read_doc) { DocDel(read_doc); read_doc=NULL; }
  if(!caught || Fs->data_heap->used_u8s!=before) return -12;
  read_doc=DocRead("C:/AllocRead.DD");
  if(read_doc) saved=DocSave(read_doc,&size); else saved=NULL;
  if(!saved || size!=5 || saved[0]!='r' || saved[1]!='e' ||
      saved[2]!='a' || saved[3]!='d' || saved[4]!=CH_CURSOR) {
    Free(saved);
    DocDel(read_doc); return -13;
  }
  Free(saved);
  DocDel(read_doc);
  if(Fs->data_heap->used_u8s!=before) return -14;
  return 12;
}
U0 NativeDocEditTextAttr(CI386Text *text,I64 foreground,I64 background,
  Bool inverted,Bool blinking,Bool blink_phase)
{
  if(inverted^^(blinking&&blink_phase)) {
    text->foreground=background; text->background=foreground;
  } else { text->foreground=foreground; text->background=background; }
}
extern U0 I386TextCell(CI386Text *text,U8 ch);
extern Bool NativeGraphicsPresent(U0 (*draw)(CDC *dc)=NULL,Bool blink=FALSE);
extern U8 *NativeGraphicsPlanes();
#define NATIVE_SPT_END   0
#define NATIVE_SPT_COLOR 1
#define NATIVE_SPT_PT    8
#define NATIVE_SPT_LINE 10
#define NATIVE_SPT_RECT 12
CDoc *native_doc_sprite_doc;
I64 native_doc_sprite_top,native_doc_sprite_left;
Bool native_doc_mouse_visible;
U0 NativeDocEditAdvance(I64 *row,I64 *column,U8 ch,Bool wrap)
{
  I64 count;
  if(ch=='\n') { *column=0; (*row)++; }
  else if(ch=='\t') {
    count=8-*column%8;
    while(count--) {
      (*column)++;
      if(wrap && *column==80) { *column=0; (*row)++; }
    }
  } else if(ch>=32) {
    (*column)++;
    if(wrap && *column==80) { *column=0; (*row)++; }
  }
}
U0 NativeDocEditVisiblePut(CI386Text *text,I64 *row,I64 *column,
  I64 top,I64 left,Bool wrap,U8 ch)
{
  I64 count;
  if(ch=='\t') {
    count=8-*column%8;
    while(count--) NativeDocEditVisiblePut(text,row,column,top,left,wrap,' ');
  } else {
    if(ch>=32 && top<=*row<top+56 && left<=*column<left+80) {
      text->row=4+*row-top; text->column=*column-left; I386TextCell(text,ch);
    }
    NativeDocEditAdvance(row,column,ch,wrap);
  }
}
I64 NativeDocEditCursorRow(CDoc *doc,Bool save_cursor,I64 *cursor_column,
  Bool wrap)
{
  CDocEntry *entry;
  U8 *src;
  I64 row=0,column=0,index,cursor_row=0;
  entry=doc->head.next;
  while(entry!=doc) {
    if(save_cursor && entry==doc->cur_entry && !IsEditableText(entry)) {
      cursor_row=row; *cursor_column=column;
      NativeDocEditAdvance(&row,&column,0xDB,wrap);
    }
    if(entry->type_u8==DOCT_TEXT) {
      src=entry->tag; index=0;
      while(src[index]) {
        if(save_cursor && entry==doc->cur_entry && index==doc->cur_col) {
          cursor_row=row; *cursor_column=column;
          NativeDocEditAdvance(&row,&column,0xDB,wrap);
        }
        NativeDocEditAdvance(&row,&column,src[index++],wrap);
      }
      if(save_cursor && entry==doc->cur_entry && index==doc->cur_col) {
        cursor_row=row; *cursor_column=column;
        NativeDocEditAdvance(&row,&column,0xDB,wrap);
      }
    } else if(entry->type_u8==DOCT_TAB)
      NativeDocEditAdvance(&row,&column,'\t',wrap);
    else if(entry->type_u8==DOCT_PAGE_BREAK || entry->type_u8==DOCT_CURSOR)
      NativeDocEditAdvance(&row,&column,0xDB,wrap);
    else if(entry->type_u8==DOCT_NEW_LINE)
      NativeDocEditAdvance(&row,&column,'\n',wrap);
    entry=entry->next;
  }
  if(save_cursor && doc->cur_entry==doc) {
    cursor_row=row; *cursor_column=column;
  }
  return cursor_row;
}
U0 NativeDocEditMouseCandidate(CDocEntry *entry,I64 column,I64 row,I64 x,
  I64 wanted_row,I64 wanted_x,CDocEntry **best_entry,I64 *best_column,
  I64 *best_row_delta,I64 *best_x_delta)
{
  I64 row_delta=row-wanted_row,x_delta=x-wanted_x;
  if(row_delta<0) row_delta=-row_delta;
  if(x_delta<0) x_delta=-x_delta;
  if(row_delta<*best_row_delta || row_delta==*best_row_delta &&
      x_delta<*best_x_delta) {
    *best_entry=entry; *best_column=column;
    *best_row_delta=row_delta; *best_x_delta=x_delta;
  }
}
Bool NativeDocEditMouseCursor(CDoc *doc,I64 mouse_x,I64 mouse_y,
  I64 scroll_rows=0,I64 scroll_columns=0)
{//Map a visible text cell back to a canonical insertion point.
  CDocEntry *entry,*best_entry=NULL;
  U8 *src;
  I64 index,count,row=0,column=0,wanted_row,wanted_x,best_column=0,
      best_row_delta=I64_MAX,best_x_delta=I64_MAX;
  Bool unlock,wrap,save_cursor;
  if(!doc || mouse_x<0 || mouse_x>=640 || mouse_y<32 || mouse_y>=480)
    return FALSE;
  wanted_row=native_doc_sprite_top+(mouse_y>>3)-4+scroll_rows;
  wanted_x=native_doc_sprite_left+(mouse_x>>3)+scroll_columns;
  unlock=DocLock(doc); wrap=doc->flags&DOCF_WORD_WRAP;
  save_cursor=!(doc->flags&DOCF_NO_CURSOR);
  for(entry=doc->head.next;entry!=doc;entry=entry->next) {
    if(save_cursor && entry==doc->cur_entry && !IsEditableText(entry)) {
      NativeDocEditMouseCandidate(entry,entry->min_col,row,column,wanted_row,
        wanted_x,&best_entry,&best_column,&best_row_delta,&best_x_delta);
      NativeDocEditAdvance(&row,&column,0xDB,wrap);
    }
    if(entry->type_u8==DOCT_TEXT) {
      src=entry->tag; index=0;
      while(src[index]) {
        if(save_cursor && entry==doc->cur_entry && index==doc->cur_col) {
          NativeDocEditMouseCandidate(entry,index,row,column,wanted_row,wanted_x,
            &best_entry,&best_column,&best_row_delta,&best_x_delta);
          NativeDocEditAdvance(&row,&column,0xDB,wrap);
        }
        NativeDocEditMouseCandidate(entry,index,row,column,wanted_row,wanted_x,
          &best_entry,&best_column,&best_row_delta,&best_x_delta);
        NativeDocEditAdvance(&row,&column,src[index++],wrap);
      }
      if(save_cursor && entry==doc->cur_entry && index==doc->cur_col) {
        NativeDocEditMouseCandidate(entry,index,row,column,wanted_row,wanted_x,
          &best_entry,&best_column,&best_row_delta,&best_x_delta);
        NativeDocEditAdvance(&row,&column,0xDB,wrap);
      }
      NativeDocEditMouseCandidate(entry,index,row,column,wanted_row,wanted_x,
        &best_entry,&best_column,&best_row_delta,&best_x_delta);
    } else if(entry->type_u8==DOCT_TAB) {
      count=8-column%8;
      while(count--) {
        NativeDocEditMouseCandidate(entry,entry->min_col,row,column,wanted_row,
          wanted_x,&best_entry,&best_column,&best_row_delta,&best_x_delta);
        NativeDocEditAdvance(&row,&column,' ',wrap);
      }
    } else {
      NativeDocEditMouseCandidate(entry,entry->min_col,row,column,wanted_row,
        wanted_x,&best_entry,&best_column,&best_row_delta,&best_x_delta);
      if(entry->type_u8==DOCT_PAGE_BREAK || entry->type_u8==DOCT_CURSOR)
        NativeDocEditAdvance(&row,&column,0xDB,wrap);
      else if(entry->type_u8==DOCT_NEW_LINE)
        NativeDocEditAdvance(&row,&column,'\n',wrap);
    }
  }
  if(save_cursor && doc->cur_entry==doc) {
    NativeDocEditMouseCandidate(doc,0,row,column,wanted_row,wanted_x,
      &best_entry,&best_column,&best_row_delta,&best_x_delta);
    NativeDocEditAdvance(&row,&column,0xDB,wrap);
  }
  NativeDocEditMouseCandidate(doc,0,row,column,wanted_row,wanted_x,
    &best_entry,&best_column,&best_row_delta,&best_x_delta);
  if(best_entry) {
    DocBasicSelectionClear(doc);
    doc->cur_entry=best_entry; doc->cur_col=best_column;
  }
  if(unlock) DocUnlock(doc);
  return best_entry!=NULL;
}
I64 NativeDocSelectWidth(CDocEntry *entry)
{
  if(entry->type_u8==DOCT_TEXT) return entry->max_col-entry->min_col;
  if(entry->type_u8==DOCT_TAB || entry->type_u8==DOCT_NEW_LINE ||
      entry->type_u8==DOCT_PAGE_BREAK || entry->type_u8==DOCT_CURSOR) return 1;
  return 0;
}
I64 NativeDocCursorOffset(CDoc *doc)
{
  CDocEntry *entry;
  I64 offset=0;
  for(entry=doc->head.next;entry!=doc;entry=entry->next) {
    if(entry==doc->cur_entry) {
      if(IsEditableText(entry)) offset+=doc->cur_col-entry->min_col;
      return offset;
    }
    offset+=NativeDocSelectWidth(entry);
  }
  return offset;
}
CDocEntry *NativeDocOffsetBoundary(CDoc *doc,I64 wanted)
{
  CDocEntry *entry;
  I64 offset=0,width,column;
  for(entry=doc->head.next;entry!=doc;entry=entry->next) {
    width=NativeDocSelectWidth(entry);
    if(wanted<=offset) return entry;
    if(width && wanted<offset+width) {
      if(IsEditableText(entry)) {
        column=entry->min_col+wanted-offset;
        return DocBasicTextSplit(doc,entry,column);
      }
      return entry;
    }
    if(wanted==offset+width && width) return entry->next;
    offset+=width;
  }
  return doc;
}
Bool NativeDocMouseSelect(CDoc *doc,I64 anchor,I64 endpoint)
{
  CDocEntry *first,*last,*entry;
  I64 low=anchor,high=endpoint;
  Bool unlock,result=FALSE;
  if(!doc) return FALSE;
  if(low>high) { low=endpoint; high=anchor; }
  unlock=DocLock(doc);
  DocBasicSelectionClear(doc);
  if(low==high) goto done;
  //Resolve the high boundary first; splitting preserves all logical offsets.
  last=NativeDocOffsetBoundary(doc,high);
  first=NativeDocOffsetBoundary(doc,low);
  if(!first || !last) goto done;
  for(entry=first;entry!=last && entry!=doc;entry=entry->next)
    entry->type|=DOCET_SEL;
  if(endpoint<anchor) doc->cur_entry=first;
  else doc->cur_entry=last;
  doc->cur_col=doc->cur_entry->min_col;
  result=TRUE;
done:
  if(unlock) DocUnlock(doc);
  return result;
}
U0 NativeDocEditDrawBody(CDoc *doc,CI386Text *text,Bool blink_phase=FALSE)
{
  CDocEntry *entry;
  U8 *src;
  I64 index,row=0,column=0,top,left,cursor_column=0,
      foreground=doc->settings_head.dft_text_attr&15,
      background=doc->settings_head.dft_text_attr>>4;
  Bool inverted=Bt(&doc->flags,DOCf_INVERT),
      blinking=Bt(&doc->flags,DOCf_BLINK),unlock=DocLock(doc),
      save_cursor=!(doc->flags&DOCF_NO_CURSOR),wrap=doc->flags&DOCF_WORD_WRAP,
      selected;
  top=NativeDocEditCursorRow(doc,save_cursor,&cursor_column,wrap)-55;
  if(top<0) top=0;
  left=cursor_column-79;
  if(left<0) left=0;
  native_doc_sprite_top=top; native_doc_sprite_left=left;
  NativeDocEditTextAttr(text,foreground,background,inverted,blinking,blink_phase);
  text->underline=Bt(&doc->flags,DOCf_UNDERLINE);
  entry=doc->head.next;
  while(entry!=doc) {
    selected=(entry->type&DOCET_SEL)!=0;
    if(selected) NativeDocEditTextAttr(text,foreground,background,!inverted,
                                      blinking,blink_phase);
    if(save_cursor && entry==doc->cur_entry && !IsEditableText(entry))
      NativeDocEditVisiblePut(text,&row,&column,top,left,wrap,0xDB);
    if(entry->type_u8==DOCT_TEXT) {
      src=entry->tag; index=0;
      while(src[index]) {
        if(save_cursor && entry==doc->cur_entry && index==doc->cur_col)
          NativeDocEditVisiblePut(text,&row,&column,top,left,wrap,0xDB);
        NativeDocEditVisiblePut(text,&row,&column,top,left,wrap,src[index++]);
      }
      if(save_cursor && entry==doc->cur_entry && index==doc->cur_col)
        NativeDocEditVisiblePut(text,&row,&column,top,left,wrap,0xDB);
    } else if(entry->type_u8==DOCT_TAB)
      NativeDocEditVisiblePut(text,&row,&column,top,left,wrap,'\t');
    else if(entry->type_u8==DOCT_PAGE_BREAK || entry->type_u8==DOCT_CURSOR)
      NativeDocEditVisiblePut(text,&row,&column,top,left,wrap,0xDB);
    else if(entry->type_u8==DOCT_NEW_LINE)
      NativeDocEditVisiblePut(text,&row,&column,top,left,wrap,'\n');
    else if(entry->type_u8==DOCT_FOREGROUND) {
      if(entry->attr==DOC_DFT) foreground=doc->settings_head.dft_text_attr&15;
      else if(0<=entry->attr<=15) foreground=entry->attr;
      NativeDocEditTextAttr(text,foreground,background,inverted,blinking,blink_phase);
    } else if(entry->type_u8==DOCT_BACKGROUND) {
      if(entry->attr==DOC_DFT) background=doc->settings_head.dft_text_attr>>4;
      else if(0<=entry->attr<=15) background=entry->attr;
      NativeDocEditTextAttr(text,foreground,background,inverted,blinking,blink_phase);
    } else if(entry->type_u8==DOCT_BLINK) {
      if(entry->attr==DOC_DFT) blinking=Bt(&doc->flags,DOCf_BLINK);
      else blinking=entry->attr!=0;
      NativeDocEditTextAttr(text,foreground,background,inverted,blinking,blink_phase);
    } else if(entry->type_u8==DOCT_INVERT) {
      if(entry->attr==DOC_DFT) inverted=Bt(&doc->flags,DOCf_INVERT);
      else inverted=entry->attr!=0;
      NativeDocEditTextAttr(text,foreground,background,inverted,blinking,blink_phase);
    } else if(entry->type_u8==DOCT_UNDERLINE) {
      if(entry->attr==DOC_DFT) text->underline=Bt(&doc->flags,DOCf_UNDERLINE);
      else text->underline=entry->attr!=0;
    }
    if(selected) NativeDocEditTextAttr(text,foreground,background,inverted,
                                      blinking,blink_phase);
    entry=entry->next;
  }
  if(save_cursor && doc->cur_entry==doc)
    NativeDocEditVisiblePut(text,&row,&column,top,left,wrap,0xDB);
  if(unlock) DocUnlock(doc);
}
U0 NativeDocSpritePixel(CDC *dc,I64 x,I64 y,I64 color)
{
  if(0<=x<dc->width && 0<=y<dc->height)
    dc->body[y*dc->width_internal+x]=color&15;
}
U0 NativeDocSpriteLine(CDC *dc,I64 x1,I64 y1,I64 x2,I64 y2,I64 color)
{
  I64 dx=x2-x1,dy=y2-y1,sx,sy,error,next;
  if(dx<0) { dx=-dx; sx=-1; } else sx=1;
  if(dy<0) { dy=-dy; sy=-1; } else sy=1;
  dy=-dy; error=dx+dy;
  while(TRUE) {
    NativeDocSpritePixel(dc,x1,y1,color);
    if(x1==x2 && y1==y2) return;
    next=error*2;
    if(next>=dy) { error+=dy; x1+=sx; }
    if(next<=dx) { error+=dx; y1+=sy; }
  }
}
Bool NativeDocSpriteDraw(CDC *dc,U8 *data,I64 size,I64 origin_x,I64 origin_y)
{//Bounded original sprite subset: color, point, line and filled rectangle.
  I64 at=0,type,color=0,x1,y1,x2,y2,x,y;
  while(at<size) {
    type=data[at]&0x7F;
    if(type==NATIVE_SPT_END) return at+1==size;
    if(type==NATIVE_SPT_COLOR) {
      if(size-at<2) return FALSE;
      color=data[at+1]&15; at+=2;
    } else if(type==NATIVE_SPT_PT) {
      if(size-at<12) return FALSE;
      x1=(data+at+4)(I32 *)[0]; y1=(data+at+8)(I32 *)[0];
      NativeDocSpritePixel(dc,origin_x+x1,origin_y+y1,color); at+=12;
    } else if(type==NATIVE_SPT_LINE || type==NATIVE_SPT_RECT) {
      if(size-at<20) return FALSE;
      x1=(data+at+4)(I32 *)[0]; y1=(data+at+8)(I32 *)[0];
      x2=(data+at+12)(I32 *)[0]; y2=(data+at+16)(I32 *)[0];
      if(type==NATIVE_SPT_LINE)
        NativeDocSpriteLine(dc,origin_x+x1,origin_y+y1,
          origin_x+x2,origin_y+y2,color);
      else if(x1<x2 && y1<y2)
        for(y=y1;y<y2;y++) for(x=x1;x<x2;x++)
          NativeDocSpritePixel(dc,origin_x+x,origin_y+y,color);
      at+=20;
    } else return FALSE;
  }
  return FALSE;
}
U0 NativeDocEditDrawSprites(CDC *dc)
{
  CDoc *doc=native_doc_sprite_doc;
  CDocEntry *entry;
  U8 *src;
  I64 row=0,column=0,index,byte,bit,plane,color;
  Bool unlock,wrap;
  if(!doc) return;
  //The editor still owns the proven planar text console.  Decode that frame
  //into the graphics callback surface before placing document sprites.
  for(byte=0;byte<38400;byte++) for(bit=0;bit<8;bit++) {
    color=0;
    for(plane=0;plane<4;plane++)
      if(console_planes[plane*38400+byte]&(1<<bit)) color|=1<<plane;
    dc->body[(byte/80)*dc->width_internal+(byte%80)*8+bit]=color;
  }
  unlock=DocLock(doc); wrap=doc->flags&DOCF_WORD_WRAP;
  for(entry=doc->head.next;entry!=doc;entry=entry->next) {
    if(entry->type_u8==DOCT_SPRITE && entry->bin_data)
      NativeDocSpriteDraw(dc,entry->bin_data->data,entry->bin_data->size,
        (column-native_doc_sprite_left)*8,(4+row-native_doc_sprite_top)*8);
    else if(entry->type_u8==DOCT_TEXT) {
      src=entry->tag; index=0;
      while(src[index]) NativeDocEditAdvance(&row,&column,src[index++],wrap);
    } else if(entry->type_u8==DOCT_TAB)
      NativeDocEditAdvance(&row,&column,'\t',wrap);
    else if(entry->type_u8==DOCT_PAGE_BREAK || entry->type_u8==DOCT_CURSOR)
      NativeDocEditAdvance(&row,&column,0xDB,wrap);
    else if(entry->type_u8==DOCT_NEW_LINE)
      NativeDocEditAdvance(&row,&column,'\n',wrap);
  }
  if(unlock) DocUnlock(doc);
}
Bool NativeDocHasSprite(CDoc *doc)
{
  CDocEntry *entry;
  for(entry=doc->head.next;entry!=doc;entry=entry->next)
    if(entry->type_u8==DOCT_SPRITE && entry->bin_data) return TRUE;
  return FALSE;
}
U8 NativeDocMouseMask(I64 row)
{//Solid eight-pixel-wide arrow in the native low-bit-left plane layout.
  switch(row) {
    case 0: return 0x01;
    case 1: return 0x03;
    case 2: return 0x07;
    case 3: return 0x0F;
    case 4: return 0x1F;
    case 5: return 0x3F;
    case 6: return 0x0F;
    case 7: return 0x1B;
    case 8: return 0x31;
    case 9: return 0x20;
  }
  return 0;
}
U0 NativeDocMouseXor(U8 *planes,I64 x,I64 y)
{
  I64 i,j,k,n;
  U8 m;
  if(!planes) return;
  for(i=0;i<10;i++) {
    m=NativeDocMouseMask(i); j=y+i;
    if(0<=j<480) {
      k=x;
      while(m) {
        if(m&1 && 0<=k<640) {
          n=j*80+(k>>3);
          planes[n]^=1<<(k&7);
          planes[38400+n]^=1<<(k&7);
          planes[76800+n]^=1<<(k&7);
          planes[115200+n]^=1<<(k&7);
        }
        m>>=1; k++;
      }
    }
  }
}
U0 NativeDocMouseShow(U8 *planes,I64 x,I64 y)
{//Upload a transient XOR overlay, retaining a clean canonical backing surface.
  I64 first=y,count=10;
  if(!planes || y>=480 || y+10<=0) return;
  if(first<0) { count+=first; first=0; }
  if(first+count>480) count=480-first;
  NativeDocMouseXor(planes,x,y);
  if(!I386VgaRows(planes,first,count)) KernelStop;
  NativeDocMouseXor(planes,x,y);
}
U8 *NativeDocEditPlanes(CDoc *doc)
{
  U8 *planes;
  if(NativeDocHasSprite(doc) && (planes=NativeGraphicsPlanes)) return planes;
  return console_planes;
}
U0 NativeDocMouseMove(CDoc *doc,I64 old_x,I64 old_y,I64 x,I64 y)
{
  NativeMousePlaneMove(NativeDocEditPlanes(doc),old_x,old_y,x,y);
}
U0 NativeMousePlaneMove(U8 *planes,I64 old_x,I64 old_y,I64 x,I64 y)
{
  I64 first=old_y,count=10;
  if(first<0) { count+=first; first=0; }
  if(first<480 && count>0) {
    if(first+count>480) count=480-first;
    if(!I386VgaRows(planes,first,count)) KernelStop;
  }
  NativeDocMouseShow(planes,x,y);
}
U0 NativeMousePlaneHide(U8 *planes,I64 x,I64 y)
{//Restore the clean backing rows underneath a transient pointer overlay.
  I64 first=y,count=10;
  if(!planes || y>=480 || y+10<=0) return;
  if(first<0) { count+=first; first=0; }
  if(first+count>480) count=480-first;
  if(count>0 && !I386VgaRows(planes,first,count)) KernelStop;
}
U0 NativeDocEditDraw(CDoc *doc,Bool blink_phase=FALSE,I64 save_status=0)
{
  I64 mouse_x,mouse_y;
  if(!I386TextInit(&console_text,console_planes,sys_font_std)) KernelStop;
  I386TextWrite(&console_text,"TempleOS i386\nDolDoc editor");
  if(save_status>0) I386TextWrite(&console_text," - Saved");
  else if(save_status==-1) I386TextWrite(&console_text," - Save failed");
  else if(save_status==-2) I386TextWrite(&console_text," - Not found");
  else if(save_status==-3) I386TextWrite(&console_text," - Line not found");
  I386TextWrite(&console_text,"\n");
  I386TextWrite(&console_text,doc->filename.name); I386TextWrite(&console_text,"\n\n");
  NativeDocEditDrawBody(doc,&console_text,blink_phase);
  if(NativeDocHasSprite(doc)) {
    native_doc_sprite_doc=doc;
    if(!NativeGraphicsPresent(&NativeDocEditDrawSprites,blink_phase)) KernelStop;
    native_doc_sprite_doc=NULL;
  } else ConsolePresent;
  if(native_doc_mouse_visible && MouseGet(&mouse_x,&mouse_y))
    NativeDocMouseShow(NativeDocEditPlanes(doc),mouse_x,mouse_y);
}
Bool NativeDocTextAt(U8 *text,I64 at,U8 *needle)
{
  I64 index=0;
  if(!text || !needle || !*needle || at<0) return FALSE;
  while(needle[index] && text[at+index] &&
        needle[index]==text[at+index]) index++;
  return !needle[index];
}
Bool NativeDocEditFind(CDoc *doc,U8 *needle,Bool backward=FALSE)
{//Search a logical projection and map the match back to canonical entries.
  CDocEntry *entry,**entry_map=NULL;
  U8 *text,*flat=NULL;
  I64 *column_map=NULL;
  I64 index,length,count=0,at=0,cursor=-1,match=-1;
  Bool unlock,result=FALSE;
  if(!doc || !needle || !*needle) return FALSE;
  unlock=DocLock(doc);
  try {
  for(entry=doc->head.next;entry!=doc;entry=entry->next)
    if(entry->type_u8==DOCT_TEXT) count+=StrLen(entry->tag);
    else if(entry->type_u8==DOCT_NEW_LINE || entry->type_u8==DOCT_TAB) count++;
  if(count && (flat=MAlloc(count+1)) &&
      (entry_map=MAlloc(count*sizeof(CDocEntry *))) &&
      (column_map=MAlloc(count*sizeof(I64)))) {
    for(entry=doc->head.next;entry!=doc;entry=entry->next) {
      if(entry==doc->cur_entry) cursor=at+doc->cur_col;
      if(entry->type_u8==DOCT_TEXT) {
        text=entry->tag; length=StrLen(text);
        for(index=0;index<length;index++) {
          flat[at]=text[index]; entry_map[at]=entry; column_map[at]=index; at++;
        }
      } else if(entry->type_u8==DOCT_NEW_LINE || entry->type_u8==DOCT_TAB) {
        if(entry->type_u8==DOCT_NEW_LINE) flat[at]='\n'; else flat[at]='\t';
        entry_map[at]=entry; column_map[at]=0; at++;
      }
    }
    flat[at]=0; if(doc->cur_entry==doc || cursor<0) cursor=at;
    if(backward) {
      index=MinI64(cursor-1,at-1);
      while(index>=0 && match<0) {
        if(entry_map[index]->type_u8==DOCT_TEXT && NativeDocTextAt(flat,index,needle))
          match=index;
        index--;
      }
      index=at-1;
      while(index>cursor && match<0) {
        if(entry_map[index]->type_u8==DOCT_TEXT && NativeDocTextAt(flat,index,needle))
          match=index;
        index--;
      }
    } else {
      index=MinI64(cursor+1,at);
      while(index<at && match<0) {
        if(entry_map[index]->type_u8==DOCT_TEXT && NativeDocTextAt(flat,index,needle))
          match=index;
        index++;
      }
      index=0;
      while(index<=cursor && index<at && match<0) {
        if(entry_map[index]->type_u8==DOCT_TEXT && NativeDocTextAt(flat,index,needle))
          match=index;
        index++;
      }
    }
    if(match>=0) {
      doc->cur_entry=entry_map[match]; doc->cur_col=column_map[match]; result=TRUE;
    }
  }
  } catch { result=FALSE; }
  Free(column_map); Free(entry_map); Free(flat);
  if(unlock) DocUnlock(doc);
  return result;
}
U0 NativeDocFindDraw(CDoc *doc,U8 *find,U8 *replace,Bool replacing)
{
  if(!I386TextInit(&console_text,console_planes,sys_font_std)) KernelStop;
  I386TextWrite(&console_text,"TempleOS i386\nFind\n");
  I386TextWrite(&console_text,doc->filename.name);
  I386TextWrite(&console_text,"\n\nSearch: "); I386TextWrite(&console_text,find);
  if(replacing) {
    I386TextWrite(&console_text,"\nReplace: "); I386TextWrite(&console_text,replace);
  }
  I386TextPut(&console_text,0xDB); ConsolePresent;
}
Bool NativeDocFindPrompt(CDoc *doc,U8 *find,I64 *length,U8 *replace,
                         I64 *replace_length,Bool *replacing)
{
  CI386KeyEvent event;
  I64 decoded;
  KernelLog("DOC FIND begin\n"); NativeDocFindDraw(doc,find,replace,*replacing);
  while(TRUE) {
    decoded=I386KeyboardRead(console_config->reader,&event,FALSE);
    if(decoded>0 && event.type==2) {
      if(event.ch==CH_ESC) { KernelLog("DOC FIND end\n"); return FALSE; }
      if(event.ch=='\n' && *length) { KernelLog("DOC FIND end\n"); return TRUE; }
      if(event.ch=='\t' && *length) {
        *replacing=TRUE; NativeDocFindDraw(doc,find,replace,*replacing);
      } else if(event.ch==CH_BACKSPACE &&
                ((!*replacing && *length) || (*replacing && *replace_length))) {
        if(*replacing) replace[--*replace_length]=0;
        else find[--*length]=0;
        NativeDocFindDraw(doc,find,replace,*replacing);
      }
      else if(0x20<=event.ch<0x100 &&
              ((!*replacing && *length<127) || (*replacing && *replace_length<127))) {
        if(*replacing) {
          replace[(*replace_length)++]=event.ch; replace[*replace_length]=0;
        } else {
          find[(*length)++]=event.ch; find[*length]=0;
        }
        NativeDocFindDraw(doc,find,replace,*replacing);
      }
    }
    if(!decoded) { I386SchedYield(I386TaskSelf->owner); I386TaskBreakPoll; }
  }
}
Bool NativeDocEditReplace(CDoc *doc,U8 *needle,U8 *replace)
{//Replace the match at the canonical cursor through the shared edit primitive.
  I64 index,length;
  if(!doc || !needle || !*needle || !replace) return FALSE;
  length=StrLen(needle);
  for(index=0;index<length;index++) DocPutKey(doc,0,SC_DELETE);
  for(index=0;replace[index];index++) DocPutKey(doc,replace[index],0);
  return TRUE;
}
Bool NativeDocEditUndoCapture(CDoc *doc,U8 **undo_bodies,I64 *undo_sizes,
                              I64 *undo_count)
{//Publish a new snapshot only after its complete canonical serialization exists.
  U8 *body=NULL;
  I64 size,index;
  if(!doc || !undo_bodies || !undo_sizes || !undo_count) return FALSE;
  try { body=DocSave(doc,&size); }
  catch { body=NULL; }
  if(!body) return FALSE;
  if(*undo_count>=16) {
    Free(undo_bodies[0]);
    for(index=1;index<16;index++) {
      undo_bodies[index-1]=undo_bodies[index];
      undo_sizes[index-1]=undo_sizes[index];
    }
    *undo_count=15;
  }
  undo_bodies[*undo_count]=body; undo_sizes[*undo_count]=size;
  (*undo_count)++;
  return TRUE;
}
Bool NativeDocEditUndoRestore(CDoc *doc,U8 **undo_bodies,I64 *undo_sizes,
                              I64 *undo_count)
{
  I64 index;
  if(!doc || !undo_bodies || !undo_sizes || !undo_count || *undo_count<=0)
    return FALSE;
  index=*undo_count-1;
  if(!NativeDocRecordLoadCore(doc,undo_bodies[index],undo_sizes[index]))
    return FALSE;
  Free(undo_bodies[index]); undo_bodies[index]=NULL; undo_sizes[index]=0;
  *undo_count=index;
  return TRUE;
}
Bool NativeDocEditUndoBegin(CDoc *doc,U8 **undo_bodies,I64 *undo_sizes,
                            I64 *undo_count,I64 kind,I64 *group_kind,
                            I64 *group_jiffy)
{//Keep one pre-edit snapshot for a continuous run of the same edit operation.
  I64 now;
  Bool capture;
  if(!group_kind || !group_jiffy || !console_config || !console_config->jiffies)
    return FALSE;
  now=*console_config->jiffies;
  capture=*group_kind!=kind || now>*group_jiffy+JIFFY_FREQ;
  if(capture && !NativeDocEditUndoCapture(doc,undo_bodies,undo_sizes,undo_count))
    return FALSE;
  *group_kind=kind; *group_jiffy=now;
  return TRUE;
}
CDoc *native_clip_doc;
Bool NativeDocClipCopy(CDoc *doc,Bool clear_selection=TRUE)
{
  CDoc *clip=NULL;
  CDocEntry *entry,*copy;
  Bool any=FALSE;
  if(!doc) return FALSE;
  try {
    clip=DocNew("C:/Clipboard.DD",Fs);
    for(entry=doc->head.next;entry!=doc;entry=entry->next)
      if(entry->type&DOCET_SEL) {
        copy=DocEntryCopy(clip,entry); copy->type&=~DOCET_SEL;
        QueIns(copy,clip->head.last);
        if(clear_selection) entry->type&=~DOCET_SEL;
        any=TRUE;
      }
  } catch { DocDel(clip); return FALSE; }
  if(!any) { DocDel(clip); return FALSE; }
  DocDel(native_clip_doc); native_clip_doc=clip;
  return TRUE;
}
Bool NativeDocClipCut(CDoc *doc)
{
  if(!NativeDocClipCopy(doc,FALSE)) return FALSE;
  return DocBasicSelectionDelete(doc);
}
Bool NativeDocClipPaste(CDoc *doc)
{
  CDoc *staged=NULL;
  CDocEntry *entry,*next,*at;
  CDocBin *bin,*next_bin;
  U8 *body=NULL;
  I64 size;
  Bool result=FALSE;
  if(!doc || !native_clip_doc || native_clip_doc->head.next==native_clip_doc)
    return FALSE;
  try {
    body=DocSave(native_clip_doc,&size);
    staged=DocNew("C:/ClipboardStage.DD",doc->mem_task);
    if(!body || !staged || !NativeDocRecordLoadCore(staged,body,size)) goto paste_done;
    at=doc->cur_entry;
    if(IsEditableText(at) && doc->cur_col>at->min_col && doc->cur_col<at->max_col) {
      at=DocBasicTextSplit(doc,at,doc->cur_col);
      if(!at) goto paste_done;
    }
    //All allocations are complete. Publish bins and entries without a failure point.
    bin=staged->bin_head.next;
    while(bin!=&staged->bin_head) {
      next_bin=bin->next; QueRem(bin); bin->num=doc->cur_bin_num++;
      QueIns(bin,doc->bin_head.last); bin=next_bin;
    }
    entry=staged->head.next;
    while(entry!=staged) {
      next=entry->next; QueRem(entry); entry->type&=~DOCET_SEL;
      if(entry->de_flags&DOCEF_HAS_BIN) entry->bin_num=entry->bin_data->num;
      QueIns(entry,at->last); entry=next;
    }
    doc->cur_entry=at; doc->cur_col=at->min_col; result=TRUE;
paste_done:
  } catch { result=FALSE; }
  Free(body); DocDel(staged);
  return result;
}
I64 NativeDocClipPasteAtomicCheck()
{//Every allocation failure must preserve exact target bytes and heap ownership.
  CDoc *source=NULL,*target=NULL,*old_clip=native_clip_doc;
  CDocEntry *entry;
  U8 *before=NULL,*after=NULL;
  I64 size,after_size,index,fail,allocations=0,used,result=-1;
  native_clip_doc=NULL;
  source=DocNew("C:/PasteSource.DD",Fs);
  DocPutKey(source,'a'); DocPutKey(source,'b');
  for(entry=source->head.next;entry!=source;entry=entry->next)
    entry->type|=DOCET_SEL;
  if(!NativeDocClipCopy(source,FALSE)) goto paste_check_done;
  target=DocNew("C:/PasteProbe.DD",Fs);
  DocPutKey(target,'x'); DocPutKey(target,'y'); DocPutKey(target,'z');
  target->cur_entry=target->head.next; target->cur_col=1;
  NativeDocAllocArm(I64_MAX);
  if(!NativeDocClipPaste(target)) { NativeDocAllocArm(0); goto paste_check_done; }
  allocations=native_doc_alloc_count; NativeDocAllocArm(0); DocDel(target); target=NULL;
  for(fail=1;fail<=allocations;fail++) {
    target=DocNew("C:/PasteFail.DD",Fs);
    DocPutKey(target,'x'); DocPutKey(target,'y'); DocPutKey(target,'z');
    target->cur_entry=target->head.next; target->cur_col=1;
    before=DocSave(target,&size); used=Fs->data_heap->used_u8s;
    NativeDocAllocArm(fail);
    if(NativeDocClipPaste(target)) {
      NativeDocAllocArm(0); result=-fail; goto paste_check_done;
    }
    NativeDocAllocArm(0); after=DocSave(target,&after_size);
    if(!after || after_size!=size) { result=-allocations-fail; goto paste_check_done; }
    for(index=0;index<size;index++) if(before[index]!=after[index]) {
      result=-allocations*2-fail; goto paste_check_done;
    }
    Free(after); after=NULL;
    if(Fs->data_heap->used_u8s!=used) {
      result=-allocations*3-fail; goto paste_check_done;
    }
    Free(before); before=NULL; DocDel(target); target=NULL;
  }
  result=allocations;
paste_check_done:
  NativeDocAllocArm(0); Free(after); Free(before); DocDel(target); DocDel(source);
  DocDel(native_clip_doc); native_clip_doc=old_clip;
  return result;
}
U0 NativeDocGotoDraw(CDoc *doc,U8 *digits)
{
  if(!I386TextInit(&console_text,console_planes,sys_font_std)) KernelStop;
  I386TextWrite(&console_text,"TempleOS i386\nGo to line\n");
  I386TextWrite(&console_text,doc->filename.name);
  I386TextWrite(&console_text,"\n\nLine: "); I386TextWrite(&console_text,digits);
  I386TextPut(&console_text,0xDB); ConsolePresent;
}
Bool NativeDocGotoPrompt(CDoc *doc,I64 *line)
{
  CI386KeyEvent event;
  U8 digits[16];
  I64 decoded,length=0,value=0,index;
  digits[0]=0; KernelLog("DOC GOTO begin\n"); NativeDocGotoDraw(doc,digits);
  while(TRUE) {
    decoded=I386KeyboardRead(console_config->reader,&event,FALSE);
    if(decoded>0 && event.type==2) {
      if(event.ch==CH_ESC) { KernelLog("DOC GOTO end\n"); return FALSE; }
      if(event.ch=='\n' && length) {
        for(index=0;index<length;index++) value=value*10+digits[index]-'0';
        if(value>0) {
          *line=value; KernelLog("DOC GOTO end\n"); return TRUE;
        }
      }
      if(event.ch==CH_BACKSPACE && length) {
        digits[--length]=0; NativeDocGotoDraw(doc,digits);
      } else if('0'<=event.ch<='9' && length<15) {
        digits[length++]=event.ch; digits[length]=0; NativeDocGotoDraw(doc,digits);
      }
    }
    if(!decoded) { I386SchedYield(I386TaskSelf->owner); I386TaskBreakPoll; }
  }
}
Bool NativeDocEditGoToLine(CDoc *doc,I64 wanted)
{//Position at the first editable byte on the requested one-based source line.
  CDocEntry *entry;
  U8 *src;
  I64 line=1,index;
  if(wanted<1) wanted=1;
  for(entry=doc->head.next;entry!=doc;entry=entry->next) {
    if(line==wanted && entry->type_u8!=DOCT_NEW_LINE) {
      doc->cur_entry=entry; doc->cur_col=0; return TRUE;
    }
    if(entry->type_u8==DOCT_NEW_LINE) line++;
    else if(entry->type_u8==DOCT_TEXT) {
      src=entry->tag; index=0;
      while(src[index]) if(src[index++]=='\n' && ++line==wanted) {
        doc->cur_entry=entry; doc->cur_col=index; return TRUE;
      }
    }
  }
  if(line==wanted) { doc->cur_entry=doc; doc->cur_col=0; return TRUE; }
  return FALSE;
}
U0 NativeDocEditExecute(CDoc *doc)
{
  CI386KeyEvent event;
  I64 decoded;
  Bool accepted;
  if(!I386TextInit(&console_text,console_planes,sys_font_std)) KernelStop;
  I386TextWrite(&console_text,"TempleOS i386\nDocument execution\n");
  I386TextWrite(&console_text,doc->filename.name); I386TextWrite(&console_text,"\n\n");
  KernelLog("DOC EXEC begin\n");
  if(DocWrite(doc)) KernelLog("DOC EXEC save ok\n");
  else {
    KernelLog("DOC EXEC save error\n");
    I386TextWrite(&console_text,"Save failed\n");
  }
  accepted=DocExe(doc);
  I386TextWrite(&console_text,"\nPress Esc to return to editor");
  ConsolePresent;
  do decoded=I386KeyboardRead(console_config->reader,&event,TRUE);
  while(decoded<=0 || event.type!=2 || event.ch!=27);
  if(!accepted && console_diagnostic_line && console_diagnostic_filename[0] &&
      !StrCmp(console_diagnostic_filename,doc->filename.name) &&
      NativeDocEditGoToLine(doc,console_diagnostic_line)) {
    KernelLog("DOC EXEC diagnostic line "); KernelHex(console_diagnostic_line);
    KernelLog("\n");
  }
  KernelLog("DOC EXEC end\n"); NativeDocEditDraw(doc);
}
Bool NativeDocEditStyle(CDoc *doc,I64 type,I64 attr)
{
  CDocEntry *entry=NULL;
  Bool result=FALSE;
  try {
    entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
    entry->type=type; entry->de_flags=doldoc.dft_de_flags[type]; entry->attr=attr;
    DocInsEntry(doc,entry); entry=NULL; result=TRUE;
  } catch { Free(entry); }
  return result;
}
I64 NativeDocEditBlinkPhase()
{
  I64 now=*console_config->jiffies;
  return (now/(JIFFY_FREQ/2))&1;
}
U0 NativeDocEditConsoleRestore()
{
  native_doc_mouse_visible=FALSE;
  native_dir_mouse_visible=FALSE;
  native_help_mouse_visible=FALSE;
  if(!I386TextInit(&console_text,console_planes,sys_font_std)) KernelStop;
  I386TextWrite(&console_text,"TempleOS i386\nHolyC console\n\n");
  ConsolePresent;
}
extern Bool NativeHelpView(U8 *name,I64 line,U8 *find,I64 occurrence,U8 *anchor);
public Bool DocEd(CDoc *doc,I64 flags=0)
{//Native keyboard/VGA session over the canonical document model. Escape exits.
  CI386KeyEvent event;
  CDoc *old_put,*old_display;
  U8 *browse_path,*picked_path=NULL;
  U8 *undo_bodies[16];
  I64 undo_sizes[16];
  U8 find[128],replace[128];
  I64 decoded,blink_phase,next_blink_phase,find_length=0,replace_length=0,
      goto_line,undo_count=0,undo_index,undo_group_kind=0,undo_group_jiffy=0,
      undo_kind,mouse_x,mouse_y,mouse_buttons=0,mouse_packets=0,
      next_mouse_x,next_mouse_y,next_mouse_buttons,next_mouse_packets,
      mouse_anchor=0,mouse_endpoint,mouse_scroll_rows,mouse_scroll_columns,
      mouse_hit_y,mouse_hold_due=0,mouse_now,mouse_old_endpoint;
  Bool done=FALSE,changed,redraw,result=TRUE,replacing=FALSE,mouse_dragging=FALSE;
  I64 save_status=0;
  if(!doc || doc->doc_signature!=DOC_SIGNATURE_VAL || flags) return FALSE;
  find[0]=0; replace[0]=0;
  MemSet(undo_bodies,0,sizeof(undo_bodies));
  MemSet(undo_sizes,0,sizeof(undo_sizes));
  old_put=Fs->put_doc; old_display=Fs->display_doc;
  Fs->put_doc=Fs->display_doc=doc;
  try {
    blink_phase=NativeDocEditBlinkPhase;
    MouseGet(&mouse_x,&mouse_y,&mouse_buttons,&mouse_packets);
    native_doc_mouse_visible=FALSE;
    KernelLog("DOC EDIT begin\n"); NativeDocEditDraw(doc,blink_phase);
    while(!done) {
      decoded=I386KeyboardRead(console_config->reader,&event,FALSE);
      changed=FALSE; redraw=FALSE;
      if(decoded>0) {
        if(event.type==2 && (event.ch==CH_ESC || event.ch==CH_SHIFT_ESC)) {
          undo_group_kind=0;
          result=event.ch==CH_ESC; done=TRUE;
        } else if(event.type==3 && event.scan.u8[0]==SC_F5) {
          undo_group_kind=0;
          NativeDocEditExecute(doc);
        }
        else if(event.type==3 && event.scan.u8[0]==SC_F1) {
          undo_group_kind=0;
          if(event.scan&0x200)
            NativeHelpView("C:/Doc/AboutTempleOS.DD",1,NULL,1,NULL);
          else NativeHelpView("C:/Doc/HelpIndex.DD",1,NULL,1,NULL);
          NativeDocEditDraw(doc,blink_phase);
        }
        else if(event.type==3 && event.scan.u8[0]==SC_F4) {
          undo_group_kind=0;
          browse_path=NativeDirPathParent(doc->filename.name);
          if(browse_path) {
            if(NativeDirPicker(browse_path,&picked_path,(event.scan&0x200)!=0) &&
                picked_path) {
              NativeDocEditUndoCapture(doc,undo_bodies,undo_sizes,&undo_count);
              for(undo_index=0;picked_path[undo_index];undo_index++)
                DocPutKey(doc,picked_path[undo_index],0);
              save_status=0;
            }
            Free(picked_path); picked_path=NULL; Free(browse_path);
            NativeDocEditDraw(doc,blink_phase);
          }
        }
        else if(event.type==2 && event.ch==CH_CTRLF) {
          undo_group_kind=0;
          find_length=0; replace_length=0; find[0]=0; replace[0]=0;
          replacing=FALSE;
          if(NativeDocFindPrompt(doc,find,&find_length,replace,&replace_length,
                                &replacing)) {
            if(NativeDocEditFind(doc,find,FALSE)) {
              if(replacing) {
                NativeDocEditUndoCapture(doc,undo_bodies,undo_sizes,&undo_count);
                NativeDocEditReplace(doc,find,replace);
              }
              save_status=0;
            }
            else save_status=-2;
          }
          NativeDocEditDraw(doc,blink_phase,save_status);
        }
        else if(event.type==3 && event.scan.u8[0]==SC_F3 && find_length) {
          undo_group_kind=0;
          if(NativeDocEditFind(doc,find,(event.scan&0x200)!=0)) save_status=0;
          else save_status=-2;
          NativeDocEditDraw(doc,blink_phase,save_status);
        }
        else if(event.type==2 && event.ch==CH_CTRLG) {
          undo_group_kind=0;
          if(NativeDocGotoPrompt(doc,&goto_line)) {
            if(NativeDocEditGoToLine(doc,goto_line)) save_status=0;
            else save_status=-3;
          }
          NativeDocEditDraw(doc,blink_phase,save_status);
        }
        else if(event.type==2 && event.ch==CH_CTRLS) {
          undo_group_kind=0;
          if(DocWrite(doc)) {
            save_status=1; KernelLog("DOC EDIT save ok\n");
          } else {
            save_status=-1; KernelLog("DOC EDIT save error\n");
          }
          redraw=TRUE;
        }
        else if(event.type==2 && event.ch==CH_CTRLC) {
          undo_group_kind=0;
          if(NativeDocClipCopy(doc)) { save_status=0; redraw=TRUE; }
        }
        else if(event.type==2 && event.ch==CH_CTRLX) {
          undo_group_kind=0;
          NativeDocEditUndoCapture(doc,undo_bodies,undo_sizes,&undo_count);
          if(NativeDocClipCut(doc)) { save_status=0; changed=TRUE; }
        }
        else if(event.type==2 && event.ch==CH_CTRLV) {
          undo_group_kind=0;
          NativeDocEditUndoCapture(doc,undo_bodies,undo_sizes,&undo_count);
          if(NativeDocClipPaste(doc)) { save_status=0; changed=TRUE; }
        }
        else if(event.type==2 && event.ch==CH_BACKSPACE && (event.scan&0x800)) {
          undo_group_kind=0;
          if(NativeDocEditUndoRestore(doc,undo_bodies,undo_sizes,&undo_count)) {
            save_status=0;
            redraw=TRUE; KernelLog("DOC EDIT undo ok\n");
          }
        }
        else if(event.type==2 && (event.ch==CH_CTRLK || event.ch==CH_CTRLU ||
            event.ch==CH_CTRLZ)) {
          undo_group_kind=0;
          NativeDocEditUndoCapture(doc,undo_bodies,undo_sizes,&undo_count);
          if(event.ch==CH_CTRLK)
            changed=NativeDocEditStyle(doc,DOCT_BLINK,(event.scan&0x200)==0);
          else if(event.ch==CH_CTRLU)
            changed=NativeDocEditStyle(doc,DOCT_UNDERLINE,
              (event.scan&0x200)==0);
          else changed=NativeDocEditStyle(doc,DOCT_INVERT,
              (event.scan&0x200)==0);
        }
        else if(event.type==2 && (event.ch==8 || event.ch=='\n' || event.ch=='\t' ||
            0x20<=event.ch<0x100)) {
          if(event.ch==8) undo_kind=2;
          else undo_kind=1;
          NativeDocEditUndoBegin(doc,undo_bodies,undo_sizes,&undo_count,
            undo_kind,&undo_group_kind,&undo_group_jiffy);
          DocPutKey(doc,event.ch,0); changed=TRUE;
        } else if(event.type==3 && (event.scan.u8[0]==SC_CURSOR_LEFT ||
            event.scan.u8[0]==SC_CURSOR_RIGHT || event.scan.u8[0]==SC_CURSOR_UP ||
            event.scan.u8[0]==SC_CURSOR_DOWN || event.scan.u8[0]==SC_HOME ||
            event.scan.u8[0]==SC_END || event.scan.u8[0]==SC_PAGE_UP ||
            event.scan.u8[0]==SC_PAGE_DOWN || event.scan.u8[0]==SC_DELETE)) {
          if(event.scan.u8[0]==SC_DELETE)
            NativeDocEditUndoBegin(doc,undo_bodies,undo_sizes,&undo_count,3,
              &undo_group_kind,&undo_group_jiffy);
          else undo_group_kind=0;
          DocPutKey(doc,0,event.scan); changed=TRUE;
        }
      }
      if(MouseGet(&next_mouse_x,&next_mouse_y,&next_mouse_buttons,&next_mouse_packets) &&
          next_mouse_packets!=mouse_packets) {
        native_doc_mouse_visible=TRUE;
        if(next_mouse_buttons&1 && !(mouse_buttons&1) &&
            NativeDocEditMouseCursor(doc,next_mouse_x,next_mouse_y)) {
          mouse_anchor=NativeDocCursorOffset(doc); mouse_dragging=TRUE;
          undo_group_kind=0; save_status=0; redraw=TRUE;
          KernelLog("DOC EDIT mouse cursor\n");
        } else if(next_mouse_buttons&1 && mouse_buttons&1 && mouse_dragging) {
          mouse_scroll_rows=0; mouse_scroll_columns=0;
          if(next_mouse_y<=32) mouse_scroll_rows=-1;
          else if(next_mouse_y==479) mouse_scroll_rows=1;
          if(next_mouse_x==0) mouse_scroll_columns=-1;
          else if(next_mouse_x==639) mouse_scroll_columns=2;
          mouse_hit_y=next_mouse_y;
          if(mouse_hit_y<32) mouse_hit_y=32;
          if((next_mouse_x!=mouse_x || next_mouse_y!=mouse_y ||
              mouse_scroll_rows || mouse_scroll_columns) &&
              NativeDocEditMouseCursor(doc,next_mouse_x,mouse_hit_y,
                mouse_scroll_rows,mouse_scroll_columns)) {
          mouse_endpoint=NativeDocCursorOffset(doc);
          NativeDocMouseSelect(doc,mouse_anchor,mouse_endpoint);
          undo_group_kind=0; save_status=0; redraw=TRUE;
          KernelLog("DOC EDIT mouse selection\n");
          if(mouse_scroll_rows || mouse_scroll_columns)
            KernelLog("DOC EDIT mouse autoscroll\n");
          }
        }
        if(!(next_mouse_buttons&1)) mouse_dragging=FALSE;
        if(!redraw && (next_mouse_x!=mouse_x || next_mouse_y!=mouse_y))
          NativeDocMouseMove(doc,mouse_x,mouse_y,next_mouse_x,next_mouse_y);
        mouse_x=next_mouse_x; mouse_y=next_mouse_y;
        mouse_buttons=next_mouse_buttons; mouse_packets=next_mouse_packets;
        if(mouse_dragging && mouse_buttons&1 && console_config &&
            console_config->jiffies && (mouse_y<=32 || mouse_y==479 ||
            mouse_x==0 || mouse_x==639))
          mouse_hold_due=*console_config->jiffies+350;
        else mouse_hold_due=0;
      }
      if(mouse_hold_due && console_config && console_config->jiffies &&
          *console_config->jiffies>=mouse_hold_due) {
        mouse_now=*console_config->jiffies;
        mouse_hold_due=mouse_now+250;
        mouse_scroll_rows=0; mouse_scroll_columns=0;
        if(mouse_y<=32) mouse_scroll_rows=-1;
        else if(mouse_y==479) mouse_scroll_rows=1;
        if(mouse_x==0) mouse_scroll_columns=-1;
        else if(mouse_x==639) mouse_scroll_columns=2;
        mouse_hit_y=mouse_y;
        if(mouse_hit_y<32) mouse_hit_y=32;
        mouse_old_endpoint=NativeDocCursorOffset(doc);
        if(NativeDocEditMouseCursor(doc,mouse_x,mouse_hit_y,
            mouse_scroll_rows,mouse_scroll_columns)) {
          mouse_endpoint=NativeDocCursorOffset(doc);
          NativeDocMouseSelect(doc,mouse_anchor,mouse_endpoint);
          if(mouse_endpoint!=mouse_old_endpoint) {
            undo_group_kind=0; save_status=0; redraw=TRUE;
            KernelLog("DOC EDIT mouse selection\n");
            KernelLog("DOC EDIT mouse autoscroll\n");
          }
        }
      }
      if(changed) save_status=0;
      next_blink_phase=NativeDocEditBlinkPhase;
      if(changed || redraw || next_blink_phase!=blink_phase) {
        blink_phase=next_blink_phase; NativeDocEditDraw(doc,blink_phase,save_status);
      }
      if(!decoded) { I386SchedYield(I386TaskSelf->owner); I386TaskBreakPoll; }
    }
  } catch {
    Free(picked_path); picked_path=NULL;
    Fs->put_doc=old_put; Fs->display_doc=old_display;
    NativeDocEditConsoleRestore;
    KernelLog("DOC EDIT exception\n");
  }
  Fs->put_doc=old_put; Fs->display_doc=old_display;
  for(undo_index=0;undo_index<undo_count;undo_index++) Free(undo_bodies[undo_index]);
  NativeDocEditConsoleRestore;
  KernelLog("DOC EDIT end\n"); return result;
}
public Bool Ed(U8 *filename,I64 flags=0)
{//File-level editor subset: Escape saves, Shift-Escape discards this session.
  CDoc *doc;
  Bool accept,result=FALSE;
  if(!filename || !*filename || flags) return FALSE;
  doc=DocRead(filename);
  if(!doc) doc=DocNew(filename,Fs);
  if(!doc) return FALSE;
  accept=DocEd(doc);
  if(accept) result=DocWrite(doc);
  DocDel(doc);
  return result;
}
class CNativeHelpLink
{
  I64 start,end,line,occurrence;
  U8 target[256],find[128],anchor[128];
};
Bool NativeHelpIndexMatch(U8 *indices,U8 *topic,I64 topic_size)
{//Match one complete semicolon-delimited #help_index component.
  I64 index=0,start,size,offset;
  if(!indices || !topic || !topic_size) return FALSE;
  while(indices[index]) {
    start=index;
    while(indices[index] && indices[index]!=';') index++;
    size=index-start;
    if(size==topic_size) {
      offset=0;
      while(offset<size && indices[start+offset]==topic[offset]) offset++;
      if(offset==size) return TRUE;
    }
    if(indices[index]==';') index++;
  }
  return FALSE;
}
Bool NativeHelpRawTarget(U8 *source,I64 target_start,I64 target_end,
                         CNativeHelpLink *link)
{//Resolve a path or an MN symbol's retained source link.
  CHashSrcSym *symbol;
  U8 symbol_name[128];
  I64 out=0,index,comma,digit,find_end;
  Bool line_target=FALSE,find_target=FALSE,anchor_target=FALSE;
  if(!source || !link || target_start<0 || target_start>=target_end) return FALSE;
  link->line=1; link->occurrence=1; link->find[0]=0; link->anchor[0]=0;
  if(target_end-target_start>=3 && source[target_start]=='M' &&
      source[target_start+1]=='N' && source[target_start+2]==':') {
    target_start+=3; index=0;
    while(target_start<target_end && source[target_start]!=',' && index<127)
      symbol_name[index++]=source[target_start++];
    symbol_name[index]=0;
    symbol=HashFind(symbol_name,Fs->hash_table,HTG_SRC_SYM);
    if(!symbol || !symbol->src_link) return FALSE;
    return NativeHelpRawTarget(symbol->src_link,0,StrLen(symbol->src_link),link);
  }
  if(target_end-target_start>=3 && source[target_start]=='H' &&
      source[target_start+1]=='I' && source[target_start+2]==':') {
    while(target_start<target_end && out<255)
      link->target[out++]=source[target_start++];
    link->target[out]=0;
    return out>3;
  }
  if(target_end-target_start>=3 && source[target_start]=='F' &&
      (source[target_start+1]=='I' || source[target_start+1]=='A' ||
       source[target_start+1]=='F' ||
       source[target_start+1]=='L') && source[target_start+2]==':') {
    line_target=source[target_start+1]=='L'; target_start+=3;
    find_target=source[target_start-2]=='F';
    anchor_target=source[target_start-2]=='A';
  }
  if(line_target) {
    comma=target_start;
    while(comma<target_end && source[comma]!=',') comma++;
    if(comma<target_end) {
      index=comma+1; digit=0;
      while(index<target_end && '0'<=source[index]<='9')
        digit=digit*10+source[index++]-'0';
      if(digit>0) link->line=digit;
    }
  }
  if(find_target) {
    comma=target_start;
    while(comma<target_end && source[comma]!=',') comma++;
    if(comma<target_end) {
      index=comma+1; find_end=target_end;
      comma=find_end-1;
      while(comma>index && source[comma]!=':') comma--;
      if(source[comma]==':') {
        digit=0; out=comma+1;
        while(out<find_end && '0'<=source[out]<='9') digit=digit*10+source[out++]-'0';
        if(out==find_end && digit>0) { link->occurrence=digit; find_end=comma; }
      }
      out=0;
      while(index<find_end && out<127) {
        if(source[index]=='\\' && index+1<find_end) index++;
        link->find[out++]=source[index++];
      }
      link->find[out]=0; out=0;
    }
  }
  if(anchor_target) {
    comma=target_start;
    while(comma<target_end && source[comma]!=',') comma++;
    if(comma<target_end) {
      index=comma+1; out=0;
      while(index<target_end && out<127) {
        if(source[index]=='\\' && index+1<target_end) index++;
        link->anchor[out++]=source[index++];
      }
      link->anchor[out]=0; out=0;
    }
  }
  if(target_end-target_start>=3 && source[target_start]==':' &&
      source[target_start+1]==':' && source[target_start+2]=='/') {
    link->target[out++]='C'; link->target[out++]=':'; target_start+=2;
  } else if(target_end-target_start<3 || source[target_start]!='C' ||
            source[target_start+1]!=':' || source[target_start+2]!='/') return FALSE;
  while(target_start<target_end && source[target_start]!=',' && out<255) {
    if(source[target_start]=='\\' && target_start+1<target_end) target_start++;
    link->target[out++]=source[target_start++];
  }
  link->target[out]=0;
  return out>2;
}
U8 *NativeHelpIndexPlain(U8 *topic,I64 *_size,CNativeHelpLink *links,
                         I64 *_link_count)
{//Build a live category page from all retained public #help_file registrations.
  CHashTable *table=Fs->hash_table;
  CHashSrcSym *symbol;
  U8 *result;
  I64 bucket,index,out=0,count=0,size,topic_size;
  if(!topic || !*topic || !(result=MAlloc(16384))) return NULL;
  topic_size=StrLen(topic);
  for(index=0;index<topic_size && out<16382;index++) result[out++]=topic[index];
  if(out<16382) result[out++]='\n';
  if(out<16382) result[out++]='\n';
  while(table && count<128) {
    for(bucket=0;bucket<=table->mask && count<128;bucket++) {
      symbol=table->body[bucket];
      while(symbol && count<128) {
        if(symbol->type&HTT_HELP_FILE && symbol->type&HTF_PUBLIC &&
            !(symbol->type&HTF_PRIVATE) && symbol->idx && symbol->str &&
            NativeHelpIndexMatch(symbol->idx,topic,topic_size)) {
          size=StrLen(symbol->str);
          if(out+size+1<16383 &&
              NativeHelpRawTarget(symbol->str,0,size,&links[count])) {
            links[count].start=out;
            for(index=0;index<size;index++) result[out++]=symbol->str[index];
            links[count].end=out; result[out++]='\n'; count++;
          }
        }
        symbol=symbol->next;
      }
    }
    table=table->next;
  }
  if(count && out<16382) result[out++]='\n';
  table=Fs->hash_table;
  while(table && count<128) {
    for(bucket=0;bucket<=table->mask && count<128;bucket++) {
      symbol=table->body[bucket];
      while(symbol && count<128) {
        if(symbol->type&HTG_SRC_SYM && !(symbol->type&HTT_HELP_FILE) &&
            symbol->type&HTF_PUBLIC && !(symbol->type&HTF_PRIVATE) &&
            symbol->idx && symbol->str && symbol->src_link &&
            NativeHelpIndexMatch(symbol->idx,topic,topic_size)) {
          size=StrLen(symbol->str);
          if(out+size+1<16383 &&
              NativeHelpRawTarget(symbol->src_link,0,StrLen(symbol->src_link),
                                  &links[count])) {
            links[count].start=out;
            for(index=0;index<size;index++) result[out++]=symbol->str[index];
            links[count].end=out; result[out++]='\n'; count++;
          }
        }
        symbol=symbol->next;
      }
    }
    table=table->next;
  }
  if(!count) {
    U8 *missing="No registered help files.\n";
    index=0; while(missing[index] && out<16383) result[out++]=missing[index++];
  }
  result[out]=0; if(_size) *_size=out; if(_link_count) *_link_count=count;
  return result;
}
Bool NativeHelpLinkTarget(U8 *source,I64 command,I64 end,I64 label_start,
                          I64 label_end,CNativeHelpLink *link)
{//Resolve the direct-file subset of original LK targets into native C: paths.
  I64 index,target_start=-1,target_end=-1;
  if(!source || !link) return FALSE;
  index=command;
  while(index+3<end) {
    if(source[index]=='A' && source[index+1]=='=' && source[index+2]=='"') {
      target_start=index+3; target_end=target_start;
      while(target_end<end && source[target_end]!='"') target_end++;
      break;
    }
    index++;
  }
  if(target_start<0) { target_start=label_start; target_end=label_end; }
  return NativeHelpRawTarget(source,target_start,target_end,link);
}
Bool NativeHelpAnchorMatch(U8 *source,I64 command,I64 end,U8 *anchor)
{
  I64 index=command,offset;
  if(!anchor || !*anchor) return FALSE;
  while(index+3<end) {
    if(source[index]=='A' && source[index+1]=='=' && source[index+2]=='"') {
      index+=3; offset=0;
      while(index<end && source[index]!='"' && anchor[offset]) {
        if(source[index]=='\\' && index+1<end) index++;
        if(source[index++]!=anchor[offset++]) return FALSE;
      }
      return !anchor[offset] && index<end && source[index]=='"';
    }
    index++;
  }
  return FALSE;
}
U8 *NativeHelpPlain(U8 *source,I64 size,I64 *_size,
                    CNativeHelpLink *links=NULL,I64 *_link_count=NULL,
                    U8 *anchor=NULL,I64 *_anchor_offset=NULL)
{//Read-only projection of common DolDoc commands; output never owns binary data.
  U8 *result;
  I64 index=0,out=0,end,quote,quote_end,label_source_start,command,
      link_count=0,link_start;
  if(!source || size<0 || !(result=MAlloc(size+1))) return NULL;
  if(_anchor_offset) *_anchor_offset=-1;
  while(index<size && source[index]) {
    if(source[index]!=36) {
      if(source[index]=='\n' || source[index]=='\t' || 0x20<=source[index]<0x100)
        result[out++]=source[index];
      index++;
    } else if(index+1<size && source[index+1]==36) {
      result[out++]=36; index+=2;
    } else {
      command=index+1; end=command;
      while(end<size && source[end] && source[end]!=36) end++;
      if(end>=size || !source[end]) { result[out++]=36; index++; }
      else {
        if(_anchor_offset && *_anchor_offset<0 && end-command>=2 &&
            source[command]=='A' && source[command+1]=='N' &&
            NativeHelpAnchorMatch(source,command,end,anchor)) *_anchor_offset=out;
        if(end-command>=2 &&
            (source[command]=='L' && source[command+1]=='K' ||
             source[command]=='T' && (source[command+1]=='X' || source[command+1]=='R') ||
             source[command]=='M' && source[command+1]=='A')) {
          quote=command;
          while(quote<end && source[quote]!='"') quote++;
          if(quote<end) {
            quote++; label_source_start=quote; quote_end=quote;
            while(quote_end<end && source[quote_end]!='"') quote_end++;
            link_start=out;
            while(quote<quote_end) {
              if(source[quote]=='\\' && quote+1<end) quote++;
              result[out++]=source[quote++];
            }
            if(links && link_count<128 && source[command]=='L' &&
                source[command+1]=='K' &&
                NativeHelpLinkTarget(source,command,end,label_source_start,quote_end,
                                     &links[link_count])) {
              links[link_count].start=link_start;
              links[link_count].end=out;
              link_count++;
            }
          }
        }
        index=end+1;
      }
    }
  }
  result[out]=0; if(_size) *_size=out;
  if(_link_count) *_link_count=link_count;
  return result;
}
I64 NativeHelpDraw(U8 *name,U8 *text,I64 size,I64 start,
                   CNativeHelpLink *links=NULL,I64 link_count=0,I64 selected=-1)
{
  I64 index=start,link_index=0,mouse_x,mouse_y;
  if(!I386TextInit(&console_text,console_planes,sys_font_std)) KernelStop;
  I386TextWrite(&console_text,"TempleOS i386\nHelp: ");
  I386TextWrite(&console_text,name); I386TextWrite(&console_text,"\n\n");
  while(link_index<link_count && links[link_index].end<=start) link_index++;
  while(index<size && console_text.row<59) {
    if(link_index==selected && index==links[link_index].start) {
      console_text.foreground=15; console_text.background=1;
    }
    I386TextPut(&console_text,text[index++]);
    if(link_index<link_count && index==links[link_index].end) {
      console_text.foreground=0; console_text.background=15; link_index++;
    }
  }
  ConsolePresent;
  if(native_help_mouse_visible && MouseGet(&mouse_x,&mouse_y))
    NativeDocMouseShow(console_planes,mouse_x,mouse_y);
  return index;
}
I64 NativeHelpMouseOffset(U8 *text,I64 start,I64 end,I64 mouse_x,I64 mouse_y)
{
  I64 index=start,row=3,column=0,count,target_row=mouse_y>>3,target_column=mouse_x>>3;
  if(!text || mouse_x<0 || mouse_x>=640 || mouse_y<32 || mouse_y>=480) return -1;
  while(index<end && row<60) {
    if(row==target_row && column==target_column) return index;
    if(text[index]=='\n') { column=0; row++; }
    else if(text[index]=='\r') column=0;
    else if(text[index]=='\t') {
      count=8-column%8;
      while(count--) if(++column==80) { column=0; row++; }
    } else if(0x20<=text[index]<0x100 && ++column==80) { column=0; row++; }
    index++;
  }
  return -1;
}
I64 NativeHelpLineOffset(U8 *text,I64 size,I64 line)
{
  I64 index=0,current=1;
  if(line<1) line=1;
  while(index<size && current<line) if(text[index++]=='\n') current++;
  return index;
}
I64 NativeHelpFindOffset(U8 *text,I64 size,U8 *needle,I64 occurrence)
{
  I64 index=0,offset,start;
  if(!needle || !*needle || occurrence<1) return -1;
  while(index<size) {
    offset=0;
    while(index+offset<size && needle[offset] && text[index+offset]==needle[offset]) offset++;
    if(!needle[offset] && !--occurrence) {
      start=index;
      while(start>0 && text[start-1]!='\n') start--;
      return start;
    }
    index++;
  }
  return -1;
}
Bool NativeHelpView(U8 *name,I64 line,U8 *find,I64 occurrence,U8 *anchor)
{//Read an original DolDoc file without rewriting it; PgUp/PgDn browse, Esc exits.
  CI386KeyEvent event;
  U8 *source=NULL,*plain=NULL;
  CNativeHelpLink *links=NULL;
  I64 source_size=0,size=0,attr=0,pages[128],page=0,next,decoded,
      link_count=0,selected=-1,index,initial,anchor_offset=-1,
      mouse_x,mouse_y,mouse_buttons=0,mouse_packets=0,next_mouse_x,next_mouse_y,
      next_mouse_buttons,next_mouse_packets,mouse_offset,last_mouse_link=-1,
      last_mouse_jiffy=0,mouse_jiffy;
  Bool done=FALSE,result=FALSE,resume_mouse,activate;
  if(!name) name="C:/Doc/HelpIndex.DD";
  if(!console_config || !console_config->files || !console_config->files->read)
    return FALSE;
  if(!(links=MAlloc(128*sizeof(CNativeHelpLink)))) return FALSE;
  if(name[0]=='H' && name[1]=='I' && name[2]==':' && name[3])
    try { plain=NativeHelpIndexPlain(name+3,&size,links,&link_count); }
    catch { plain=NULL; }
  else {
    source=(*console_config->files->read)(console_config->heap,name,&source_size,&attr,NULL);
    if(!source) { Free(links); return FALSE; }
    try { plain=NativeHelpPlain(source,source_size,&size,links,&link_count,
                                anchor,&anchor_offset); }
    catch { plain=NULL; }
    I386HeapFree(console_config->heap,source);
  }
  if(!plain) { Free(links); return FALSE; }
  initial=anchor_offset;
  if(initial<0) initial=NativeHelpFindOffset(plain,size,find,occurrence);
  if(initial<0) initial=NativeHelpLineOffset(plain,size,line);
  pages[0]=initial;
  MouseGet(&mouse_x,&mouse_y,&mouse_buttons,&mouse_packets);
  native_help_mouse_visible=FALSE;
  next=NativeHelpDraw(name,plain,size,initial,links,link_count,selected);
  KernelLog("HELP VIEW begin\n");
  try {
    while(!done) {
      activate=FALSE;
      decoded=I386KeyboardRead(console_config->reader,&event,FALSE);
      if(decoded>0) {
        last_mouse_link=-1;
        if(event.type==2 && (event.ch==CH_ESC || event.ch==CH_SHIFT_ESC)) {
          result=TRUE; done=TRUE;
        } else if(event.type==3 && (event.scan.u8[0]==SC_PAGE_DOWN ||
                  event.scan.u8[0]==SC_CURSOR_DOWN) && next<size && page<127) {
          selected=-1; pages[++page]=next;
          next=NativeHelpDraw(name,plain,size,pages[page],links,link_count,selected);
        } else if(event.type==3 && (event.scan.u8[0]==SC_PAGE_UP ||
                  event.scan.u8[0]==SC_CURSOR_UP) && page>0) {
          selected=-1; page--;
          next=NativeHelpDraw(name,plain,size,pages[page],links,link_count,selected);
        } else if(event.type==3 && event.scan.u8[0]==SC_HOME) {
          selected=-1; page=0; pages[0]=0;
          next=NativeHelpDraw(name,plain,size,0,links,link_count,selected);
        } else if(event.type==3 && (event.scan.u8[0]==SC_CURSOR_RIGHT ||
                  event.scan.u8[0]==SC_CURSOR_LEFT)) {
          if(event.scan.u8[0]==SC_CURSOR_RIGHT) {
            index=selected+1;
            while(index<link_count && (links[index].start<pages[page] ||
                  links[index].start>=next)) index++;
            if(index>=link_count) {
              index=0; while(index<link_count && links[index].start<pages[page]) index++;
            }
          } else {
            if(selected<0) index=link_count-1;
            else index=selected-1;
            while(index>=0 && (links[index].start<pages[page] ||
                  links[index].start>=next)) index--;
            if(index<0) {
              index=link_count-1;
              while(index>=0 && links[index].start>=next) index--;
            }
          }
          if(0<=index<link_count && pages[page]<=links[index].start<next) {
            selected=index;
            next=NativeHelpDraw(name,plain,size,pages[page],links,link_count,selected);
          }
        } else if(event.type==2 && event.ch=='\n' && 0<=selected<link_count)
          activate=TRUE;
      }
      if(MouseGet(&next_mouse_x,&next_mouse_y,&next_mouse_buttons,&next_mouse_packets) &&
          next_mouse_packets!=mouse_packets) {
        native_help_mouse_visible=TRUE;
        if(next_mouse_buttons&1 && !(mouse_buttons&1)) {
          mouse_offset=NativeHelpMouseOffset(plain,pages[page],next,
                                             next_mouse_x,next_mouse_y);
          index=0;
          while(index<link_count && !(links[index].start<=mouse_offset<links[index].end))
            index++;
          if(index<link_count && pages[page]<=links[index].start<next) {
            selected=index;
            next=NativeHelpDraw(name,plain,size,pages[page],links,link_count,selected);
            KernelLog("HELP mouse selection\n");
            if(console_config->jiffies) {
              mouse_jiffy=*console_config->jiffies;
              if(index==last_mouse_link &&
                  0<=mouse_jiffy-last_mouse_jiffy<=500) {
                activate=TRUE; last_mouse_link=-1;
                KernelLog("HELP mouse activate\n");
              } else {
                last_mouse_link=index; last_mouse_jiffy=mouse_jiffy;
              }
            }
          }
        } else if(next_mouse_x!=mouse_x || next_mouse_y!=mouse_y)
          NativeMousePlaneMove(console_planes,mouse_x,mouse_y,next_mouse_x,next_mouse_y);
        mouse_x=next_mouse_x; mouse_y=next_mouse_y;
        mouse_buttons=next_mouse_buttons; mouse_packets=next_mouse_packets;
      }
      if(activate && 0<=selected<link_count) {
        KernelLog("HELP OPEN "); KernelLog(links[selected].target); KernelLog("\n");
        resume_mouse=native_help_mouse_visible;
        NativeHelpView(links[selected].target,links[selected].line,
                       links[selected].find,links[selected].occurrence,
                       links[selected].anchor);
        native_help_mouse_visible=resume_mouse;
        next=NativeHelpDraw(name,plain,size,pages[page],links,link_count,selected);
      }
      if(!decoded) { I386SchedYield(I386TaskSelf->owner); I386TaskBreakPoll; }
    }
  } catch { result=FALSE; }
  Free(plain); Free(links); NativeDocEditConsoleRestore;
  KernelLog("HELP VIEW end\n"); return result;
}
public Bool Help(U8 *name=NULL)
{
  return NativeHelpView(name,1,NULL,1,NULL);
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
