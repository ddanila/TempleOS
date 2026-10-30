I64 ll_calls,ll_unlocked,ll_free,ll_mode;
U8 *LLLink(CDoc *doc,CDocEntry *e)
{ no_warn doc;no_warn e;if(!ll_mode)return NULL;return "link-target"; }
Bool LLUnlock(CDoc *doc) { no_warn doc;ll_unlocked++;return TRUE; }
Bool LLEd(U8 *s) { if(!StrCmp(s,"link-target") && ll_unlocked==1)ll_calls=1;return TRUE; }
I64 LLPopUpEd(U8 *s) { if(!StrCmp(s,"link-target") && ll_unlocked==1)ll_calls=2;return 7; }
U0 LLFree(U8 *s) { if(!StrCmp(s,"link-target"))ll_free++; }
extern I64 LLCallback(CDoc *doc,CDocEntry *e);
I64 LeftLinkContract()
{
  CDoc *doc=DocNew;CDocEntry e;I64 mask=0,result;
  MemSet(&e,0,sizeof(e));
  if(doc && doc->left_click_link)mask|=1;
  if(doc) {
    DocLock(doc);(*doc->left_click_link)(doc,&e);
    if(doc->owning_task==Fs)mask|=2;
    DocUnlock(doc);DocDel(doc);
  }
  ll_mode=1;ll_calls=ll_unlocked=ll_free=0;
  result=LLCallback(NULL,&e);
  if(result==TRUE && ll_calls==1 && ll_unlocked==1 && ll_free==1)mask|=4;
  e.de_flags=DOCEF_POPUP;ll_calls=ll_unlocked=ll_free=0;
  result=LLCallback(NULL,&e);
  if(result==7 && ll_calls==2 && ll_unlocked==1 && ll_free==1)mask|=8;
  ll_mode=0;ll_calls=ll_unlocked=ll_free=0;LLCallback(NULL,&e);
  if(!ll_calls && !ll_unlocked && !ll_free)mask|=16;
  return mask;
}

#define EdLeftClickLink LLCallback
#define DocEntryLink LLLink
#define DocUnlock LLUnlock
#define Ed LLEd
#define PopUpEd LLPopUpEd
#define Free LLFree
#include "C:/Probe/EdLeftCore.HC"
