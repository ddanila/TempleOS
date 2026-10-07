#include "/Kernel/MenuTypes.HH"
#ifndef I386_PUBLIC_MENU_INCLUDED
#define I386_PUBLIC_MENU_INCLUDED
public _extern _MENU_NEW CMenu *MenuNew(U8 *source,I64 flags=0,CTask *task=NULL);
public _extern _MENU_FILE CMenu *MenuFile(U8 *filename,I64 flags=0,CTask *task=NULL);
public _extern _MENU_ENTRY_FIND CMenuEntry *MenuEntryFind(CMenu *menu,U8 *name);
public _extern _MENU_SUB_ENTRY_FIND CMenuEntry *MenuSubEntryFind(CMenuEntry *first,U8 *name);
public _extern _MENU_DEL U0 MenuDel(CMenu *menu);
#endif
