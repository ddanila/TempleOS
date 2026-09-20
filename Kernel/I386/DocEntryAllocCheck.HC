I64 DocEntryAllocCheck()
{
  CDoc doc;
  CDocEntry *base,*tag,*copy,*rich,*rich_copy;
  CDocBin *bin,*bin_copy;
  I64 before=Fs->data_heap->used_u8s,result=8;
  MemSet(&doc,0,sizeof(doc)); doc.mem_task=Fs; doc.cur_bin_num=7;
  QueInit(&doc.bin_head);
  base=DocEntryNewBase(&doc,DOCT_TEXT,0,12,34,56);
  base->settings.indent=9; base->settings.cur_text_attr=0xA7;
  if(base->de_flags!=DOCEF_TAG || base->x!=12 || base->y!=34 ||
      base->page_line_num!=56 || MHeapCtrl(base)!=Fs->data_heap) result=-1;
  tag=DocEntryNewTag(&doc,base,"Hello");
  if(StrCmp(tag->tag,"Hello") || tag->max_col!=5 || tag->x!=12 ||
      tag->settings.indent!=9 || tag->settings.cur_text_attr!=0xA7 ||
      !IsEditableText(tag) || MHeapCtrl(tag->tag)!=Fs->data_heap) result=-2;
  copy=DocEntryCopy(&doc,tag);
  tag->tag[0]='J';
  if(copy==tag || copy->tag==tag->tag || copy->tag[0]!='H' ||
      copy->next!=copy || copy->last!=copy || copy->settings.indent!=9) result=-3;
  if(DocEntrySize(&doc,copy)!=MSize2(copy)+MSize2(copy->tag) || DocEntrySize(&doc,0)) result=-4;
  rich=CAlloc(sizeof(CDocEntry));
  rich->type=DOCT_TEXT;
  rich->de_flags=DOCEF_TAG|DOCEF_AUX_STR|DOCEF_HAS_BIN|DOCEF_REMALLOC_DATA;
  rich->tag=StrNew("asset"); rich->aux_str=StrNew("format"); rich->data=StrNew("data");
  bin=CAlloc(sizeof(CDocBin)); bin->data=StrNew("binary");
  bin->tag=StrNew("old-tag"); bin->use_cnt=1; bin->num=2; bin->size=7;
  rich->bin_data=bin; rich->bin_num=2;
  rich_copy=DocEntryCopy(&doc,rich); bin_copy=rich_copy->bin_data;
  if(bin_copy==bin || bin_copy->data==bin->data || bin_copy->tag==bin->tag ||
      StrCmp(bin_copy->data,"binary") || StrCmp(bin_copy->tag,"asset") ||
      rich_copy->bin_num!=7 || bin_copy->num!=7 || doc.cur_bin_num!=8 ||
      doc.bin_head.next!=bin_copy || doc.bin_head.last!=bin_copy) result=-5;
  rich->aux_str[0]='X'; rich->data[0]='X'; bin->data[0]='X';
  if(rich_copy->aux_str[0]!='f' || rich_copy->data[0]!='d' ||
      bin_copy->data[0]!='b' || MHeapCtrl(bin_copy)!=Fs->data_heap ||
      MHeapCtrl(bin_copy->data)!=Fs->data_heap) result=-6;
  if(DocEntrySize(&doc,rich_copy)!=MSize2(rich_copy)+MSize2(rich_copy->tag)+
      MSize2(rich_copy->aux_str)+MSize2(rich_copy->data)) result=-7;
  QueRem(bin_copy);
  Free(bin_copy->tag); Free(bin_copy->data); Free(bin_copy);
  Free(bin->tag); Free(bin->data); Free(bin);
  Free(rich_copy->tag); Free(rich_copy->aux_str); Free(rich_copy->data); Free(rich_copy);
  Free(rich->tag); Free(rich->aux_str); Free(rich->data); Free(rich);
  Free(copy->tag); Free(copy); Free(tag->tag); Free(tag); Free(base);
  if(Fs->data_heap->used_u8s!=before || doc.bin_head.next!=&doc.bin_head) result=-8;
  return result;
}
