//Original WinMgr document button state/actions. Caller owns the document lock.
U0 DocMousePressCore(CDoc *doc,Bool right)
{
  CDocEntry *e=doc->cur_entry;
  if(!right && e!=doc && e->de_flags&DOCEF_HAS_BORDER)
    e->de_flags|=DOCEF_SOLID_BORDER;
}
I64 DocMouseReleaseCore(CDoc *doc,Bool right,Bool double_click)
{
  CDocEntry *e=doc->cur_entry;
  if(double_click) {
    if(right)return CH_SHIFT_ESC;
    return CH_ESC;
  }
  if(e==doc)return 0;
  if(right) {
    if(e->de_flags&(DOCEF_LINK|DOCEF_RIGHT_CB|DOCEF_RIGHT_MACRO|DOCEF_RIGHT_EXP))return '\n';
  } else {
    if(e->de_flags&DOCEF_HAS_BORDER)e->de_flags&=~DOCEF_SOLID_BORDER;
    if(e->de_flags&(DOCEF_TREE|DOCEF_LST|DOCEF_LINK|DOCEF_CHECK_COLLAPSABLE|
        DOCEF_LEFT_CB|DOCEF_LEFT_MACRO|DOCEF_LEFT_EXP))return CH_SPACE;
  }
  return 0;
}
