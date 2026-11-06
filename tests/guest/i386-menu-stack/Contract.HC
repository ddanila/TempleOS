I64 menu_stack_observation[6];
I64 MenuStackContract(U8 *path)
{
  CMenu *old=Fs->cur_menu,*first,*second,*file_menu;
  CMenuEntry *entry;
  I64 mask=0,base=Fs->data_heap->used_u8s,first_used;
  U8 *source="View { Close(MSG_KEY_UP,27,0x1122334455667788); }";
  Bool caught=FALSE,saved_raw;
  first=MenuPush("File { Open(,'o',0x123456789ABCDEF); }");
  if(first && Fs->cur_menu==first && first->next==old)mask|=1;
  entry=MenuEntryFind(first,"File/Open");
  if(entry && entry->msg_code==MSG_KEY_DOWN_UP && entry->arg1=='o' &&
      entry->arg2==0x123456789ABCDEF && !first->flags &&
      MHeapCtrl(first)->mem_task==Fs)mask|=2;
  first_used=Fs->data_heap->used_u8s;
  second=MenuPush("Edit { Copy(,'c'); }");
  if(second && Fs->cur_menu==second && second->next==first &&
      MenuEntryFind(second,"Edit/Copy"))mask|=4;
  MenuPop;
  if(Fs->cur_menu==first && Fs->data_heap->used_u8s==first_used)mask|=8;
  FileWrite(path,source,StrLen(source));
  file_menu=MenuFilePush(path);
  entry=MenuEntryFind(file_menu,"View/Close");
  if(file_menu && Fs->cur_menu==file_menu && file_menu->next==first &&
      entry && entry->msg_code==MSG_KEY_UP && entry->arg1==27 &&
      entry->arg2==0x1122334455667788)mask|=16;
  MenuPop;
  if(Fs->cur_menu==first && Fs->data_heap->used_u8s==first_used)mask|=32;
  MenuPop;
  if(Fs->cur_menu==old && Fs->data_heap->used_u8s==base)mask|=64;
  Fs->cur_menu=NULL;
  MenuPop;
  if(!Fs->cur_menu && Fs->data_heap->used_u8s==base)mask|=128;
  Fs->cur_menu=old;
  menu_stack_observation[0]=Fs->data_heap->used_u8s;
  saved_raw=Raw(ON);
  menu_stack_observation[1]=Fs->data_heap->used_u8s;
  try { MenuPush("Broken {"); }
  catch { caught=TRUE;Fs->catch_except=TRUE; }
  menu_stack_observation[2]=Fs->data_heap->used_u8s;
  menu_stack_observation[4]=caught;
  menu_stack_observation[5]=Fs->cur_menu==old;
  Raw(saved_raw);
  menu_stack_observation[3]=Fs->data_heap->used_u8s;
  if(caught && Fs->cur_menu==old)mask|=256;
  if(Fs->data_heap->used_u8s==base)mask|=512;
  return mask;
}
