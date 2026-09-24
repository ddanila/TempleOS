//Shared ordinary-text editing core used while the full DocPutKey dependency
//graph is retained on i386. It operates on canonical CDoc/CDocEntry records.
CDocEntry *DocBasicLineStart(CDoc *doc,CDocEntry *entry)
{
  if(entry==doc && entry->last!=doc) entry=entry->last;
  while(entry->last!=doc && entry->last->type_u8!=DOCT_NEW_LINE)
    entry=entry->last;
  return entry;
}

I64 DocBasicEntryWidth(CDocEntry *entry,I64 x)
{
  if(IsEditableText(entry)) return entry->max_col-entry->min_col;
  if(entry->type_u8==DOCT_TAB) return 8-(x&7);
  return 0;
}

I64 DocBasicLineColumn(CDoc *doc,CDocEntry *entry,I64 column)
{
  CDocEntry *scan=DocBasicLineStart(doc,entry);
  I64 x=0;
  while(scan!=doc && scan!=entry && scan->type_u8!=DOCT_NEW_LINE) {
    x+=DocBasicEntryWidth(scan,x); scan=scan->next;
  }
  if(scan==entry && IsEditableText(entry)) x+=column-entry->min_col;
  return x;
}

U0 DocBasicSelectionClear(CDoc *doc)
{
  CDocEntry *entry;
  for(entry=doc->head.next;entry!=doc;entry=entry->next)
    entry->type&=~DOCET_SEL;
}

CDocEntry *DocBasicTextSplit(CDoc *doc,CDocEntry *entry,I64 column)
{//Return the record beginning at column, publishing only a complete split.
  CDocEntry *right=NULL;
  U8 *tag=NULL;
  I64 length;
  if(!IsEditableText(entry) || column<=entry->min_col) return entry;
  if(column>=entry->max_col) return entry->next;
  length=entry->max_col-column;
  try {
    right=DocEntryNewBase(doc,entry->type);
    tag=MAlloc(length+1,doc->mem_task);
    MemCpy(tag,entry->tag+column,length+1);
    right->tag=tag; right->min_col=0; right->max_col=length;
    QueIns(right,entry); right=NULL; tag=NULL;
  } catch { Free(tag); Free(right); return NULL; }
  entry->tag[column]=0; entry->max_col=column;
  return entry->next;
}

Bool DocBasicSelectionDelete(CDoc *doc)
{
  CDocEntry *entry,*next,*first=NULL,*before;
  for(entry=doc->head.next;entry!=doc;entry=entry->next)
    if(entry->type&DOCET_SEL) { first=entry; break; }
  if(!first) return FALSE;
  before=first->last;
  entry=first;
  while(entry!=doc) {
    next=entry->next;
    if(entry->type&DOCET_SEL) DocEntryDel(doc,entry);
    entry=next;
  }
  //Recover the insertion point from the surviving predecessor.
  next=before->next;
  doc->cur_entry=next; doc->cur_col=next->min_col;
  return TRUE;
}

Bool DocBasicSelectToStart(CDoc *doc)
{
  CDocEntry *entry,*stop=doc->cur_entry;
  if(IsEditableText(stop) && doc->cur_col>stop->min_col &&
      doc->cur_col<stop->max_col) {
    stop=DocBasicTextSplit(doc,stop,doc->cur_col);
    if(!stop) return FALSE;
  } else if(IsEditableText(stop) && doc->cur_col>=stop->max_col)
    stop=stop->next;
  for(entry=doc->head.next;entry!=stop;entry=entry->next)
    entry->type|=DOCET_SEL;
  doc->cur_entry=doc->head.next; doc->cur_col=doc->cur_entry->min_col;
  return TRUE;
}

Bool DocBasicSelectToEnd(CDoc *doc)
{
  CDocEntry *entry=doc->cur_entry;
  if(IsEditableText(entry) && doc->cur_col>entry->min_col) {
    entry=DocBasicTextSplit(doc,entry,doc->cur_col);
    if(!entry) return FALSE;
  }
  while(entry!=doc) { entry->type|=DOCET_SEL; entry=entry->next; }
  doc->cur_entry=doc; doc->cur_col=0;
  return TRUE;
}

U0 DocBasicSetLineColumn(CDoc *doc,CDocEntry *start,I64 wanted)
{
  CDocEntry *entry=start,*last_text=NULL;
  I64 x=0,width;
  while(entry!=doc && entry->type_u8!=DOCT_NEW_LINE) {
    width=DocBasicEntryWidth(entry,x);
    if(IsEditableText(entry)) {
      last_text=entry;
      if(wanted<=x+width) {
        doc->cur_entry=entry;
        doc->cur_col=entry->min_col+wanted-x;
        return;
      }
    } else if(entry->type_u8==DOCT_TAB && wanted<x+width) {
      doc->cur_entry=entry;
      doc->cur_col=entry->min_col;
      return;
    }
    x+=width; entry=entry->next;
  }
  if(last_text) {
    doc->cur_entry=last_text; doc->cur_col=last_text->max_col;
  } else {
    doc->cur_entry=entry; doc->cur_col=entry->min_col;
  }
}

U0 DocBasicMoveLines(CDoc *doc,I64 direction,I64 count)
{
  CDocEntry *entry,*line,*scan,*before;
  I64 wanted=DocBasicLineColumn(doc,doc->cur_entry,doc->cur_col);
  while(count-->0) {
    entry=doc->cur_entry; before=entry;
    if(direction<0) {
      line=DocBasicLineStart(doc,entry);
      if(line->last==doc) break;
      scan=line->last->last;
      if(scan!=doc && scan->type_u8==DOCT_NEW_LINE) scan=line->last;
      else if(scan==doc) scan=doc->head.next;
      else scan=DocBasicLineStart(doc,scan);
      DocBasicSetLineColumn(doc,scan,wanted);
    } else {
      scan=entry;
      while(scan!=doc && scan->type_u8!=DOCT_NEW_LINE) scan=scan->next;
      if(scan==doc) break;
      DocBasicSetLineColumn(doc,scan->next,wanted);
    }
    if(doc->cur_entry==before) break;
  }
}

CDocEntry *DocBasicCursorBoundary(CDoc *doc)
{
  CDocEntry *entry=doc->cur_entry;
  if(IsEditableText(entry)) {
    if(doc->cur_col<=entry->min_col) return entry;
    if(doc->cur_col>=entry->max_col) return entry->next;
    return DocBasicTextSplit(doc,entry,doc->cur_col);
  }
  return entry;
}

Bool DocBasicSelectLines(CDoc *doc,I64 direction,I64 count)
{
  CDocEntry *fixed,*moving,*entry;
  fixed=DocBasicCursorBoundary(doc);
  if(!fixed) return FALSE;
  doc->cur_entry=fixed; doc->cur_col=fixed->min_col;
  DocBasicMoveLines(doc,direction,count);
  moving=DocBasicCursorBoundary(doc);
  if(!moving) return FALSE;
  if(direction<0) {
    for(entry=moving;entry!=fixed;entry=entry->next) entry->type^=DOCET_SEL;
    doc->cur_entry=moving; doc->cur_col=moving->min_col;
  } else {
    for(entry=fixed;entry!=moving;entry=entry->next) entry->type^=DOCET_SEL;
    doc->cur_entry=moving; doc->cur_col=moving->min_col;
  }
  return TRUE;
}

Bool DocBasicEditCore(CDoc *doc,I64 ch=0,I64 sc=0)
{
  CDocEntry *entry,*fresh=NULL,*scan,*part;
  U8 *old_text,*new_text=NULL,*src,*dst;
  I64 column,length;
  Bool unlock,selected_deleted=FALSE,shift=(sc.u32[0]&0x200)!=0;
  if(!doc || doc->doc_signature!=DOC_SIGNATURE_VAL) return FALSE;
  if(sc.u32[0]&0x800 ||
      sc.u32[0]&0x400 && !(ch==0 && (sc.u8[0]==SC_CURSOR_UP ||
      sc.u8[0]==SC_CURSOR_DOWN))) return FALSE;
  unlock=DocLock(doc);
  try {
  entry=doc->cur_entry;
  if(!shift && (ch || sc.u8[0])) {
    if(ch==CH_BACKSPACE || 0x20<=ch<0x100 ||
        ch==0 && sc.u8[0]==SC_DELETE)
      selected_deleted=DocBasicSelectionDelete(doc);
    else DocBasicSelectionClear(doc);
    entry=doc->cur_entry;
  }
  if(ch==0 && sc.u8[0]==SC_CURSOR_UP && sc.u32[0]&0x400) {
    if(shift) DocBasicSelectToStart(doc);
    else {
      doc->cur_entry=doc->head.next;
      doc->cur_col=doc->cur_entry->min_col;
    }
  } else if(ch==0 && sc.u8[0]==SC_CURSOR_DOWN && sc.u32[0]&0x400) {
    if(shift) DocBasicSelectToEnd(doc);
    else { doc->cur_entry=doc; doc->cur_col=0; }
  } else if(ch==0 && sc.u8[0]==SC_CURSOR_UP) {
    if(shift) DocBasicSelectLines(doc,-1,1);
    else DocBasicMoveLines(doc,-1,1);
  } else if(ch==0 && sc.u8[0]==SC_CURSOR_DOWN) {
    if(shift) DocBasicSelectLines(doc,1,1);
    else DocBasicMoveLines(doc,1,1);
  } else if(ch==0 && sc.u8[0]==SC_PAGE_UP) {
    if(shift) DocBasicSelectLines(doc,-1,55);
    else DocBasicMoveLines(doc,-1,55);
  } else if(ch==0 && sc.u8[0]==SC_PAGE_DOWN) {
    if(shift) DocBasicSelectLines(doc,1,55);
    else DocBasicMoveLines(doc,1,55);
  } else if(ch==0 && sc.u8[0]==SC_HOME) {
    doc->cur_entry=doc->head.next;
    doc->cur_col=doc->cur_entry->min_col;
  } else if(ch==0 && sc.u8[0]==SC_END) {
    doc->cur_entry=doc;
    doc->cur_col=0;
  } else if(ch==0 && sc.u8[0]==SC_CURSOR_LEFT) {
    if(shift) {
      if(entry!=doc && doc->cur_col>entry->min_col) {
        part=DocBasicTextSplit(doc,entry,doc->cur_col);
        if(part) {
          entry=part->last;
          part=DocBasicTextSplit(doc,entry,entry->max_col-1);
          if(part) { part->type^=DOCET_SEL; doc->cur_entry=part; doc->cur_col=part->min_col; }
        }
      } else if(entry->last!=doc) {
        entry=entry->last;
        if(IsEditableText(entry) && entry->max_col-entry->min_col>1) {
          part=DocBasicTextSplit(doc,entry,entry->max_col-1);
          if(part) entry=part;
        }
        entry->type^=DOCET_SEL; doc->cur_entry=entry; doc->cur_col=entry->min_col;
      }
    } else if(doc->cur_col>entry->min_col) doc->cur_col--;
    else if(entry->last!=doc) {
      entry=entry->last; doc->cur_entry=entry;
      if(entry->max_col>entry->min_col) doc->cur_col=entry->max_col-1;
      else doc->cur_col=entry->min_col;
    }
  } else if(ch==0 && sc.u8[0]==SC_CURSOR_RIGHT) {
    if(shift && entry!=doc) {
      if(IsEditableText(entry)) {
        part=DocBasicTextSplit(doc,entry,doc->cur_col);
        if(part && part!=doc) {
          entry=part; DocBasicTextSplit(doc,entry,entry->min_col+1);
        }
      }
      if(entry!=doc) {
        entry->type^=DOCET_SEL; doc->cur_entry=entry->next;
        doc->cur_col=doc->cur_entry->min_col;
      }
    } else if(entry!=doc) {
      if(IsEditableText(entry) && doc->cur_col<entry->max_col) {
        doc->cur_col++;
        if(doc->cur_col>=entry->max_col) {
          doc->cur_entry=entry->next;
          doc->cur_col=doc->cur_entry->min_col;
        }
      } else {
        doc->cur_entry=entry->next;
        if(doc->cur_entry!=doc && !IsEditableText(doc->cur_entry))
          doc->cur_entry=doc->cur_entry->next;
        doc->cur_col=doc->cur_entry->min_col;
      }
    }
  } else if(ch==0 && sc.u8[0]==SC_DELETE) {
    if(!selected_deleted && entry!=doc) {
      if(IsEditableText(entry) && doc->cur_col<entry->max_col) {
        StrCpy(entry->tag+doc->cur_col,entry->tag+doc->cur_col+1);
        entry->max_col--;
        if(doc->cur_col>=entry->max_col) {
          doc->cur_entry=entry->next;
          doc->cur_col=doc->cur_entry->min_col;
        }
      } else {
        doc->cur_entry=entry->next;
        doc->cur_col=doc->cur_entry->min_col;
        DocEntryDel(doc,entry);
      }
    }
  } else if(ch==CH_BACKSPACE) {
    if(selected_deleted) {
    } else if(doc->cur_col<=entry->min_col && entry->last!=doc) {
      entry=entry->last;
      while(entry!=doc && IsEditableText(entry) &&
            entry->max_col<=entry->min_col) {
        scan=entry->last; DocEntryDel(doc,entry); entry=scan;
      }
      doc->cur_entry=entry; doc->cur_col=entry->max_col;
      if(!IsEditableText(entry)) {
        if(entry->type_u8==DOCT_NEW_LINE) {
          DocEntryDel(doc,entry);
          doc->cur_col=doc->cur_entry->min_col;
        }
        if(unlock) DocUnlock(doc);
        return TRUE;
      }
    }
    if(IsEditableText(entry) && doc->cur_col>entry->min_col) {
      column=--doc->cur_col;
      StrCpy(entry->tag+column,entry->tag+column+1);
      entry->max_col--;
      if(doc->cur_col>=entry->max_col) {
        doc->cur_entry=entry->next;
        doc->cur_col=doc->cur_entry->min_col;
      }
    }
  } else if(0x20<=ch<0x100) {
    if(IsEditableText(entry)) {
      length=StrLen(entry->tag); column=doc->cur_col;
      if(column<entry->min_col) column=entry->min_col;
      if(column>length) column=length;
      old_text=entry->tag; new_text=MAlloc(length+2,doc->mem_task);
      src=old_text; dst=new_text;
      while(column-->0) *dst++=*src++;
      *dst++=ch;
      while(*dst++=*src++);
      entry->tag=new_text; entry->max_col=length+1;
      doc->cur_col++;
      new_text=NULL; Free(old_text);
    } else {
      fresh=DocEntryNewBase(doc,DOCT_TEXT|doc->settings_head.dft_text_attr<<8);
      fresh->tag=MAlloc(2,doc->mem_task); fresh->tag[0]=ch; fresh->tag[1]=0;
      fresh->max_col=1; QueIns(fresh,entry->last); fresh=NULL;
    }
  } else if(ch=='\n') {
    fresh=DocEntryNewBase(doc,DOCT_NEW_LINE|doc->settings_head.dft_text_attr<<8);
    DocInsEntry(doc,fresh); fresh=NULL;
  } else if(ch=='\t') {
    fresh=DocEntryNewBase(doc,DOCT_TAB|doc->settings_head.dft_text_attr<<8);
    DocInsEntry(doc,fresh); fresh=NULL;
  } else {
    if(unlock) DocUnlock(doc);
    return FALSE;
  }
  } catch {
    Free(new_text);
    if(fresh) { Free(fresh->tag); Free(fresh); }
    if(unlock) DocUnlock(doc);
  }
  if(unlock) DocUnlock(doc);
  return TRUE;
}
