public CMenu *MenuPush(U8 *st)
{//Save old pulldown menu and replace with new from str.
  CMenu *m=MenuNew(st);
  m->next=Fs->cur_menu;
  Fs->cur_menu=m;
  return m;
}

public CMenu *MenuFilePush(U8 *filename)
{//Save old pulldown menu and replace with new from file.
  CMenu *m=MenuFile(filename);
  m->next=Fs->cur_menu;
  Fs->cur_menu=m;
  return m;
}

public U0 MenuPop()
{//Restore old pulldown menu. Delete just-deactivated menu.
  CMenu *m=Fs->cur_menu;
  if (!m) return;
  Fs->cur_menu=m->next;
  MenuDel(m);
}

