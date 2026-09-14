#include "/Compiler/LexIdent.HH"
I64 LexIdentRead(CCmpCtrl *cc,I64 ch,U8 *buf,I64 capacity,CLexCharSource *source)
{
  I64 i=0;
  buf[i++]=ch;
  while(TRUE) {
    if(i>=capacity) return -2;
    ch=source->read(source->context,cc);
    if(ch<0) return -1;
    if(!ch) break;
    if(Bt(cc->char_bmp_alpha_numeric,ch)) buf[i++]=ch;
    else if(ch==TK_SUPERSCRIPT) buf[i++]='>';
    else if(ch==TK_SUBSCRIPT) buf[i++]='<';
    else if(ch==TK_NORMALSCRIPT) buf[i++]='=';
    else { cc->flags|=CCF_USE_LAST_U16; break; }
  }
  buf[i++]=0;
  return i;
}
CHash *LexIdentFind(CCmpCtrl *cc,U8 *name)
{
  if(cc->htc.local_var_lst) cc->local_var_entry=MemberFind(name,cc->htc.local_var_lst);
  else cc->local_var_entry=0;
  if(!cc->local_var_entry && cc->htc.hash_table_lst)
    return HashFind(name,cc->htc.hash_table_lst,cc->htc.hash_mask);
  return 0;
}
