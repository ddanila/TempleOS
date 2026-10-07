#ifndef MENU_TYPES_INCLUDED
#define MENU_TYPES_INCLUDED
public class CMenuEntry
{
  CMenuEntry *next;
  CMenuEntry *sub;
  U8	name[32];
  I64	msg_code,arg1,arg2;
  Bool	checked,dir,pad[6];
};

public class CMenu
{
  CMenu *next;
  CMenuEntry *sub;
  CTask *task;
  I64	flags;
  U8	attr,pad[7];
};

#endif
