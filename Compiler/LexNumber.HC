#include "/Compiler/LexNumber.HH"
I64 LexNumberBody(CCmpCtrl *cc,I64 ch,CLexCharSource *source)
{
  I64 i,j,k;
  Bool neg_e;
  if(ch=='.') goto lex_number_dot;
  if(!('0'<=ch<='9')) return -1;
  i=ch-'0';
  ch=source->read(source->context,cc);
  if(ch<0) return -1;
  ch=ToUpper(ch);
  if (ch=='X') {
    while (TRUE) {
      ch=source->read(source->context,cc);
      if(ch<0) return -1;
      ch=ToUpper(ch);
      if (Bt(char_bmp_hex_numeric,ch)) {
        if (ch<='9')
          i=i<<4+ch-'0';
        else
          i=i<<4+ch-'A'+10;
      } else {
        cc->cur_i64=i;
        cc->flags|=CCF_USE_LAST_U16;
        cc->token=TK_I64;
        return cc->token;
      }
    }
  } else if (ch=='B') {
    while (TRUE) {
      ch=source->read(source->context,cc);
      if(ch<0) return -1;
      if (ch=='0')
        i=i<<1;
      else if (ch=='1')
        i=i<<1+1;
      else {
        cc->cur_i64=i;
        cc->flags|=CCF_USE_LAST_U16;
        cc->token=TK_I64;
        return cc->token;
      }
    }
  }
  while (TRUE) {
    if (Bt(char_bmp_dec_numeric,ch))
      i=i*10+ch-'0';
    else {
      if (ch=='.' || ch=='e' || ch=='E') break;
lex_is_int:
      cc->cur_i64=i;
      cc->flags|=CCF_USE_LAST_U16;
      cc->token=TK_I64;
      return cc->token;
    }
    ch=source->read(source->context,cc);
    if(ch<0) return -1;
  }
  if (ch=='.') {
    ch=source->read(source->context,cc);
    if(ch<0) return -1;
    if (ch=='.') {
      cc->flags|=CCF_LAST_WAS_DOT;
      goto lex_is_int;
    }
  }
lex_float_start:
  k=0;
  while (TRUE) {
    if (Bt(char_bmp_dec_numeric,ch)) {
      i=i*10+ch-'0';
      k++;
    } else {
      if (ch=='e' || ch=='E')
        break;
      cc->cur_f64=i*Pow10I64(-k);
      cc->flags|=CCF_USE_LAST_U16;
      cc->token=TK_F64;
      return cc->token;
    }
    ch=source->read(source->context,cc);
    if(ch<0) return -1;
  }
  ch=source->read(source->context,cc);
  if(ch<0) return -1;
  neg_e=FALSE;
  if (ch=='-') {
    neg_e=TRUE;
    ch=source->read(source->context,cc);
    if(ch<0) return -1;
  }
  j=0;
  while (TRUE) {
    if (Bt(char_bmp_dec_numeric,ch))
      j=j*10+ch-'0';
    else {
      if (neg_e)
        cc->cur_f64=i*Pow10I64(-j-k);
      else
        cc->cur_f64=i*Pow10I64(j-k);
      cc->flags|=CCF_USE_LAST_U16;
      cc->token=TK_F64;
      return cc->token;
    }
    ch=source->read(source->context,cc);
    if(ch<0) return -1;
  }
lex_number_dot:
  if (cc->flags&CCF_KEEP_DOT) {
    cc->token=ch;
    return cc->token;
  }
  if (cc->flags&CCF_LAST_WAS_DOT) {
    cc->flags&=~CCF_LAST_WAS_DOT;
    goto lex_dot_dot;
  }
  ch=source->read(source->context,cc);
  if(ch<0) return -1;
  if ('0'<=ch<='9') {
    i=0;
    goto lex_float_start;
  } else if (ch=='.') {
lex_dot_dot:
    cc->token=TK_DOT_DOT;
    ch=source->read(source->context,cc);
    if(ch<0) return -1;
    if (ch=='.')
      cc->token=TK_ELLIPSIS;
    else
      cc->flags|=CCF_USE_LAST_U16;
    return cc->token;
  }
  cc->flags|=CCF_USE_LAST_U16;
  cc->token='.';
  return cc->token;
}
