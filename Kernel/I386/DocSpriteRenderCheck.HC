CDoc *sprite_render_doc;
I64 DocSpriteRenderStart()
{
  CDoc *doc;
  CDocBin *bin,*loaded_bin;
  CDocEntry *entry,*loaded_entry;
  U8 *data;
  doc=DocNew("C:/SpriteRender.DD",Fs);
  bin=CAlloc(sizeof(CDocBin)); entry=CAlloc(sizeof(CDocEntry)); data=CAlloc(20);
  doc->flags|=DOCF_NO_CURSOR;
  data[0]=1; data[1]=4; //Packed SPT_COLOR, red.
  data[2]=12; //Packed SPT_RECT, inclusive endpoints.
  (data+3)(I32 *)[0]=0; (data+7)(I32 *)[0]=0;
  (data+11)(I32 *)[0]=15; (data+15)(I32 *)[0]=7;
  data[19]=0; //SPT_END
  bin->num=1; bin->size=20; bin->use_cnt=1; bin->data=data;
  QueIns(bin,doc->bin_head.last);
  entry->type=DOCT_SPRITE; entry->de_flags=DOCEF_TAG|DOCEF_HAS_BIN;
  entry->tag=StrNew(""); entry->bin_num=1; entry->bin_data=bin;
  DocInsEntry(doc,entry);
  if(!DocWrite(doc)) { DocDel(doc); return -1; }
  DocDel(doc); sprite_render_doc=DocRead("C:/SpriteRender.DD");
  if(!sprite_render_doc) return -2;
  loaded_entry=sprite_render_doc->head.next;
  if(loaded_entry==sprite_render_doc) return -2;
  loaded_bin=loaded_entry->bin_data;
  if(loaded_entry->type_u8!=DOCT_SPRITE || !loaded_bin || loaded_bin->size!=20) {
    DocDel(sprite_render_doc); sprite_render_doc=NULL; return -2;
  }
  return 20;
}
