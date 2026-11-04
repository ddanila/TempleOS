I64 TerminalConstructorContract()
{
  CDoc *old_put=Fs->put_doc,*old_display=Fs->display_doc,*old_border=Fs->border_doc;
  CDoc *doc=NULL,*border=NULL;
  CMenu *old_menu=Fs->cur_menu,*menu=NULL;
  CMenuEntry *file_menu;
  CCtrl *old_h=CtrlFindUnique(Fs,CTRLT_WIN_HSCROLL);
  CCtrl *old_v=CtrlFindUnique(Fs,CTRLT_WIN_VSCROLL),*h,*v;
  CWinScroll old_hscroll,old_vscroll;
  I64 old_border_src=Fs->border_src,mask=0,callbacks=0,titles=0;
  CDocEntry *entry;
  Bool was_raw=IsRaw;
  MemCpy(&old_hscroll,&Fs->horz_scroll,sizeof(CWinScroll));
  MemCpy(&old_vscroll,&Fs->vert_scroll,sizeof(CWinScroll));
  Raw(ON);
  try {
    DocTermNew;
    doc=Fs->put_doc;border=Fs->border_doc;menu=Fs->cur_menu;
    if(doc && doc!=old_put && doc==Fs->display_doc)mask|=1;
    if(doc && doc->mem_task==Fs && doc->max_entries==4096 && doc->desc=='Term')mask|=2;
    if(doc && doc->right_click_link)mask|=4;
    if(Fs->border_src==BDS_CUR_DRV && border && border!=old_border &&
        border->flags&DOCF_BORDER_DOC)mask|=8;
    if(border)for(entry=border->head.next;entry!=border;entry=entry->next) {
      if(entry->tag_cb && entry->user_data==doc)callbacks++;
      if(entry->type_u8==DOCT_DATA && entry->data==&Fs->task_title)titles++;
    }
    if(callbacks==5 && titles==1)mask|=16;
    if(menu && menu!=old_menu && menu->task==Fs &&
        (file_menu=MenuEntryFind(menu,"File")) &&
        MenuSubEntryFind(file_menu->sub,"Save") &&
        MenuSubEntryFind(file_menu->sub,"Exit"))mask|=32;
    h=CtrlFindUnique(Fs,CTRLT_WIN_HSCROLL);v=CtrlFindUnique(Fs,CTRLT_WIN_VSCROLL);
    if(h && h->state==&Fs->horz_scroll && h->win_task==Fs &&
        h->draw_it && h->left_click && h->update_derived_vals)mask|=64;
    if(v && v->state==&Fs->vert_scroll && v->win_task==Fs &&
        v->draw_it && v->left_click && v->wheel_chg && v->update_derived_vals)mask|=128;
    if(!IsRaw)mask|=256;
    if((!old_h || h==old_h) && (!old_v || v==old_v))mask|=512;
  } catch { Fs->catch_except=TRUE; }
  //Detach before freeing so the live window manager cannot draw released objects.
  Fs->put_doc=old_put;Fs->display_doc=old_display;Fs->border_doc=old_border;
  Fs->cur_menu=old_menu;Fs->border_src=old_border_src;Raw(was_raw);
  h=CtrlFindUnique(Fs,CTRLT_WIN_HSCROLL);v=CtrlFindUnique(Fs,CTRLT_WIN_VSCROLL);
  if(h && !old_h){QueRem(h);Free(h);}
  if(v && !old_v){QueRem(v);Free(v);}
  MemCpy(&Fs->horz_scroll,&old_hscroll,sizeof(CWinScroll));
  MemCpy(&Fs->vert_scroll,&old_vscroll,sizeof(CWinScroll));
  if(menu && menu!=old_menu)MenuDel(menu);
  if(border && border!=old_border)DocDel(border);
  if(doc && doc!=old_put)DocDel(doc);
  return mask;
}
