#include "/Adam/MenuParseServices.HH"
public CMenuEntry *MenuSubEntryFind(
	CMenuEntry *haystack_first,U8 *needle_entry_name)
{//You probably don't need this. Use dir / and $LK,"MenuEntryFind",A="MN:MenuEntryFind"$().
  while (haystack_first) {
    if (!StrCmp(haystack_first->name,needle_entry_name))
      return haystack_first;
    haystack_first=haystack_first->next;
  }
  return NULL;
}

public CMenuEntry *MenuEntryFind(CMenu *haystack_menu,U8 *needle_full_name)
{//Find pulldown entry. Fs->cur_menu is probably the menu you want.
//Just 2 levels -- across top and down are valid, currently.
  U8 *st,*st2;
  CMenuEntry *tmpse;
  if (!haystack_menu || !needle_full_name)
    return NULL;
  st=StrNew(needle_full_name);
  st2=StrNew(needle_full_name);
  tmpse=(&haystack_menu->sub)(U8 *)-offset(CMenuEntry.sub);
  while (*st && tmpse) {
    StrFirstRem(st,"/",st2);
    tmpse=MenuSubEntryFind(tmpse->sub,st2);
  }
  Free(st);
  Free(st2);
  return tmpse;
}

extern U0 MenuDelSub(CMenuEntry *entry);
extern U0 MenuDel(CMenu *menu);

CMenuEntry *MenuNewSub(CMenuParseServices *services,CCmpCtrl *cc,CTask *task)
{
  CMenuEntry *tmpme=NULL,*tmpse;
  try {
  if (cc->token==TK_IDENT) {
    tmpme=CAlloc(sizeof(CMenuEntry),task);
    if (StrLen(cc->cur_str)>31)
      cc->cur_str[31]=0;
    StrCpy(tmpme->name,cc->cur_str);
    if ((*services->lex)(services->context,cc)=='(') {
      tmpme->msg_code=MSG_KEY_DOWN_UP;
      if ((*services->lex)(services->context,cc)!=',' && cc->token!=')')
	tmpme->msg_code=(*services->integer_expression)(services->context,cc);
      if (cc->token==',')
	(*services->lex)(services->context,cc);
      if (cc->token!=',' && cc->token!=')')
	tmpme->arg1=(*services->integer_expression)(services->context,cc);
      if (cc->token==',')
	(*services->lex)(services->context,cc);
      if (cc->token!=',' && cc->token!=')')
	tmpme->arg2=(*services->integer_expression)(services->context,cc);
      if (cc->token!=')')
	(*services->except)(services->context,cc,"Missing ')' at ");
      if ((*services->lex)(services->context,cc)!=';')
	(*services->except)(services->context,cc,"Missing ';' at");
      (*services->lex)(services->context,cc); //Skip ;
    } else if (cc->token=='{') {
      (*services->lex)(services->context,cc); //Skip {
      tmpme->dir=TRUE;
      tmpse=&tmpme->sub;
      while (tmpse && cc->token!='}')
	tmpse=tmpse->next=MenuNewSub(services,cc,task);
      if (cc->token!='}')
	(*services->except)(services->context,cc,"Missing '}' at ");
      else
	(*services->lex)(services->context,cc); //Skip }
    } else
      (*services->except)(services->context,cc,"Expecting '{' at ");
  }
  } catch { MenuDelSub(tmpme); }
  return tmpme;
}

CMenu *MenuBuildCore(CMenuParseServices *services,CCmpCtrl *cc,I64 flags,CTask *task)
{//Parse a menu. You probably don't need this.
  CMenu *m=NULL;
  CMenuEntry *tmpse;
  try {
  if (!task) task=Fs;
  (*services->lex)(services->context,cc);
  m=CAlloc(sizeof(CMenu),task);
  m->task=task;
  m->flags=flags;
  m->attr =BLUE<<4+YELLOW;
  tmpse=&m->sub;
  while (tmpse)
    tmpse=tmpse->next=MenuNewSub(services,cc,task);
  } catch { MenuDel(m); }
  return m;
}

#ifndef I386_MENU_PARSE_BINDINGS
I64 MenuParseOriginalLex(U8 *,CCmpCtrl *cc) { return Lex(cc); }
I64 MenuParseOriginalInteger(U8 *,CCmpCtrl *cc) { return LexExpressionI64(cc); }
U0 MenuParseOriginalExcept(U8 *,CCmpCtrl *cc,U8 *message) { LexExcept(cc,message); }
public CMenu *MenuNew(U8 *st,I64 flags=0,CTask *task=NULL)
{
  CMenuParseServices services;
  CCmpCtrl *cc=CmpCtrlNew(st,CCF_DONT_FREE_BUF);
  CMenu *m;
  services.context=NULL;
  services.lex=&MenuParseOriginalLex;
  services.integer_expression=&MenuParseOriginalInteger;
  services.except=&MenuParseOriginalExcept;
  try { m=MenuBuildCore(&services,cc,flags,task); }
  catch { CmpCtrlDel(cc); }
  CmpCtrlDel(cc);
  return m;
}
#endif

public CMenu *MenuFile(U8 *filename,I64 flags=0,CTask *task=NULL)
{//Parse a pulldown menu file. You probably don't need this.
  CMenu *m;
  U8 *st=MStrPrint("#include \"%s\"",filename);
  m=MenuNew(st,flags,task);
  Free(st);
  return m;
}

U0 MenuDelSub(CMenuEntry *tmpme)
{
  CMenuEntry *tmpse,*tmpse1;
  if (tmpme) {
    tmpse=tmpme->sub;
    while (tmpse) {
      tmpse1=tmpse->next;
      MenuDelSub(tmpse);
      tmpse=tmpse1;
    }
    Free(tmpme);
  }
}

public U0 MenuDel(CMenu *m)
{//Delete a manu. You probably don't need this.
  CMenuEntry *tmpme,*tmpme1;
  if (!m) return;
  tmpme=m->sub;
  while (tmpme) {
    tmpme1=tmpme->next;
    MenuDelSub(tmpme);
    tmpme=tmpme1;
  }
  Free(m);
}

