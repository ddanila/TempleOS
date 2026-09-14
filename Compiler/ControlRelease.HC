#include "/Compiler/ControlRelease.HH"
U0 CmpCtrlRelease(CCmpCtrl *cc,CLexFileRelease *owner)
{
  CLexFile *snapshot;
  CLexHashTableContext *hash;
  while(cc->lex_include_stk) LexFileReleaseTop(cc,owner);
  while(snapshot=cc->lex_prs_stk) {
    cc->lex_prs_stk=snapshot->next;
    (*owner->allocation)(owner->context,snapshot);
  }
  while(hash=cc->htc.next) {
    cc->htc.next=hash->next;
    (*owner->allocation)(owner->context,hash);
  }
  (*owner->allocation)(owner->context,cc->ps);
  (*owner->allocation)(owner->context,cc->cur_str);
  (*owner->allocation)(owner->context,cc->cur_help_idx);
  (*owner->allocation)(owner->context,cc->dollar_buf);
  (*owner->allocation)(owner->context,cc);
}
