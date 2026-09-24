//Load the first structured DolDoc subset understood by
//NativeDocRecordSaveCore.  Dollar is numeric so this source remains plain text.
Bool NativeDocRecordLoadCore(CDoc *doc,U8 *source,I64 size)
{
  CDocEntry *entry,*cursor_entry=0;
  CDocBin *bin;
  U8 *tag;
  Bool found_cursor=FALSE;
  I64 attr,cursor_col=0,index,type,text_size=size,bin_index=size,tag_start,tag_size,bin_num;
  if(!doc || doc->doc_signature!=DOC_SIGNATURE_VAL || !source || size<0) return FALSE;
  DocRst(doc,TRUE);
  for(index=0;index<size;index++) if(!source[index]) {
    text_size=index; bin_index=index+1; break;
  }
  index=0;
  while(index<text_size) {
    if(source[index]==36 && index+1<text_size && source[index+1]==36) {
      DocPutKey(doc,36,0); index+=2;
    } else if(source[index]==36 && index+3<text_size &&
        ((source[index+1]=='F' || source[index+1]=='B') && source[index+2]=='G' ||
         source[index+1]=='B' && source[index+2]=='K' ||
         source[index+1]=='I' && source[index+2]=='V' ||
         source[index+1]=='U' && source[index+2]=='L')) {
      if(source[index+1]=='F') type=DOCT_FOREGROUND;
      else if(source[index+1]=='B' && source[index+2]=='G') type=DOCT_BACKGROUND;
      else if(source[index+1]=='B') type=DOCT_BLINK;
      else if(source[index+1]=='I') type=DOCT_INVERT;
      else type=DOCT_UNDERLINE;
      attr=DOC_DFT;
      if(source[index+3]==36) index+=4;
      else if(source[index+3]==',' && index+5<text_size) {
        index+=4;
        if('0'<=source[index]<='9') {
          attr=source[index++]-'0';
          if(index<text_size && '0'<=source[index]<='9')
            attr=attr*10+source[index++]-'0';
        } else return FALSE;
        if(attr>15 || (type==DOCT_BLINK || type==DOCT_INVERT ||
            type==DOCT_UNDERLINE) && attr>1 ||
            index>=text_size || source[index]!=36) return FALSE;
        index++;
      } else return FALSE;
      entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
      entry->type=type;
      entry->de_flags=doldoc.dft_de_flags[type];
      entry->attr=attr; DocInsEntry(doc,entry);
    } else if(source[index]==36 && index+10<text_size &&
        source[index+1]=='S' && source[index+2]=='P' && source[index+3]==',' &&
        source[index+4]=='"') {
      tag_start=index+5; index=tag_start;
      while(index<text_size && source[index]!='"') index++;
      if(index>=text_size || index+6>=text_size || source[index+1]!=',' ||
          source[index+2]!='B' || source[index+3]!='I' || source[index+4]!='=')
        return FALSE;
      tag_size=index-tag_start; index+=5; bin_num=0;
      if(index>=text_size || source[index]<'1' || '9'<source[index]) return FALSE;
      while(index<text_size && '0'<=source[index]<='9') {
        if(bin_num>0x7FFFFFFF/10) return FALSE;
        bin_num=bin_num*10+source[index++]-'0';
      }
      if(index>=text_size || source[index++]!=36) return FALSE;
      entry=NULL; tag=NULL;
      try {
        entry=CAlloc(sizeof(CDocEntry),doc->mem_task);
        tag=CAlloc(tag_size+1,doc->mem_task);
        if(tag_size) MemCpy(tag,source+tag_start,tag_size);
        entry->type=DOCT_SPRITE;
        //Claim binary ownership only after every appended record is bounded.
        entry->de_flags=doldoc.dft_de_flags[DOCT_SPRITE];
        entry->tag=tag; entry->bin_num=bin_num; DocInsEntry(doc,entry);
        entry=NULL; tag=NULL;
      } catch { Free(tag); Free(entry); }
    } else {
      if(source[index]==CH_CURSOR) {
        found_cursor=TRUE; cursor_entry=doc->head.last;
        if(cursor_entry==doc) cursor_col=0;
        else cursor_col=cursor_entry->max_col;
      } else if(source[index]=='\n' || source[index]=='\t' ||
          0x20<=source[index]<0x100)
        DocPutKey(doc,source[index],0);
      else return FALSE;
      index++;
    }
  }
  while(bin_index<size) {
    if(size-bin_index<16) return FALSE;
    bin=NULL;
    try {
      bin=CAlloc(sizeof(CDocBin),doc->mem_task);
      MemCpy(&bin->start,source+bin_index,16); bin_index+=16;
      if(bin->size>size-bin_index) { Free(bin); return FALSE; }
      bin->data=MAlloc(bin->size,doc->mem_task);
      if(bin->size) MemCpy(bin->data,source+bin_index,bin->size);
      bin_index+=bin->size; QueIns(bin,doc->bin_head.last);
      if(bin->num>=doc->cur_bin_num) doc->cur_bin_num=bin->num+1;
      bin=NULL;
    } catch { if(bin) { Free(bin->data); Free(bin); } }
  }
  for(entry=doc->head.next;entry!=doc;entry=entry->next)
    if(entry->type_u8==DOCT_SPRITE) entry->de_flags|=DOCEF_HAS_BIN;
  DocBinsValidate(doc);
  if(found_cursor) {
    if(cursor_entry!=doc && !IsEditableText(cursor_entry)) {
      cursor_entry=cursor_entry->next; cursor_col=cursor_entry->min_col;
    }
    doc->cur_entry=cursor_entry; doc->cur_col=cursor_col;
  } else {
    doc->cur_entry=doc->head.next; doc->cur_col=doc->cur_entry->min_col;
  }
  return TRUE;
}
