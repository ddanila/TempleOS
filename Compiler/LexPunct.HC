#include "/Compiler/LexPunct.HH"
I64 LexPunctBody(CCmpCtrl *cc,I64 ch,CLexCharSource *source,CLexPunctTables *tables,Bool *finish)
{
  I64 i,j;
  *finish=TRUE;
  if (!(i=tables->first[ch])) {
    if (ch=='$$') {
      ch=source->read(source->context,cc);
      if(ch<0) return -1;
      if (ch=='$$') {
        cc->token='$$';
        return cc->token;
      } else if (ch) {
        do { ch=source->read(source->context,cc); if(ch<0) return -1; }
        while (ch && ch!='$$');
        if (!ch) {
          cc->token=TK_EOF;
          return cc->token;
        } else
          return -2;
      } else {
        cc->flags|=CCF_USE_LAST_U16;
        cc->token='$$';
        return cc->token;
      }
    } else {
      cc->token=ch;
      return cc->token;
    }
  } else {
    j=source->read(source->context,cc);
    if(j<0) return -1;
    if (i.u16[0]==j) {
      i>>=16;
      if (!i) {// "/*"
        j=1;
        do {
          ch=source->read(source->context,cc);
          if(ch<0) return -1;
          if (!ch)
            goto punct_eof;
lex_check_comment:
          if (ch=='*') {
            ch=source->read(source->context,cc);
            if(ch<0) return -1;
            if (!ch)
              goto punct_eof;
            if (ch=='/')
              j--;
            else
              goto lex_check_comment;
          } else if (ch=='/') {
            ch=source->read(source->context,cc);
            if(ch<0) return -1;
            if (!ch)
              goto punct_eof;
            if (ch=='*')
              j++;
            else
              goto lex_check_comment;
          }
        } while (j);
        return -2;
      } else {
        cc->token=i;
        return cc->token;
      }
    }
    if (i=tables->second[ch]) {
      if (i.u16[0]==j) {
        i>>=16;
        if (!i) {// "//"
          do { ch=source->read(source->context,cc); if(ch<0) return -1; }
          while(Bt(char_bmp_non_eol,ch));
          if (cc->flags&CCF_KEEP_NEW_LINES) {
            cc->token='\n';
            return cc->token;
          } else
            return -2;
        } else {
          if (i==TK_SHL || i==TK_SHR) {
            j=source->read(source->context,cc);
            if(j<0) return -1;
            if (j=='=') {
              if (i==TK_SHL)
                i=TK_SHL_EQU;
              else
                i=TK_SHR_EQU;
            } else
              cc->flags|=CCF_USE_LAST_U16;
          }
          cc->token=i;
          return cc->token;
        }
      }
      if (i=tables->third[ch]) {
        if (i.u16[0]==j) {
          cc->token=i.u16[1];
          return cc->token;
        }
      }
    }
    cc->flags|=CCF_USE_LAST_U16;
    cc->token=ch;
    return cc->token;
  }
punct_eof:
  *finish=FALSE;
  return cc->token=TK_EOF;
}
