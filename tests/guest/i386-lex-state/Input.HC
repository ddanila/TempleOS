I64 LexRawInputTest()
{
  CCmpCtrl *cc=StateAlloc(sizeof(CCmpCtrl));
  CLexFile *root,*child;
  U8 *buffer=StateAlloc(512),*saved;
  I64 byte,expected,lines,old_lines;
  if(!cc || !buffer) return 50;
  CmpCtrlSeed(cc,CCF_DONT_FREE_BUF,0,0);
  root=InputPush(cc); if(!root) return 51;
  for(byte=1;byte<256;byte++) {
    buffer[0]=byte; buffer[1]=0;
    LexFileSeed(root,buffer); cc->cur_buf_ptr=buffer; cc->flags=CCF_DONT_FREE_BUF; lines=0;
    expected=byte; if(byte==CH_CURSOR) expected=0;
    if(byte==CH_SHIFT_SPACE) expected=CH_SPACE;
    if(InputRead(cc,&lines)!=expected || cc->cur_buf_ptr!=buffer+1) return 52;
    old_lines=0; if(byte=='\n') old_lines=1;
    if(lines!=old_lines || root->line_num!=1+old_lines) return 53;
    saved=cc->cur_buf_ptr; cc->flags|=CCF_USE_LAST_U16;
    if(InputRead(cc,&lines)!=expected || cc->cur_buf_ptr!=saved || lines!=old_lines || cc->flags&CCF_USE_LAST_U16) return 54;
    if(InputRead(cc,&lines) || InputRead(cc,&lines) || cc->cur_buf_ptr!=buffer+1 || lines!=old_lines) return 55;
  }
  buffer[0]=CH_CURSOR; buffer[1]=CH_CURSOR; buffer[2]='A'; buffer[3]=CH_SHIFT_SPACE; buffer[4]='\n'; buffer[5]=0;
  LexFileSeed(root,buffer); cc->cur_buf_ptr=buffer; lines=0x100000002; root->line_num=0x100000001;
  if(InputRead(cc,&lines)!='A' || InputRead(cc,&lines)!=CH_SPACE || InputRead(cc,&lines)!='\n' ||
      root->line_num!=0x100000002 || lines!=0x100000003 || root->line_start!=buffer+5 ||
      InputRead(cc,&lines) || cc->cur_buf_ptr!=buffer+5) return 56;
  LexFileSeed(root,0); cc->cur_buf_ptr=0;
  if(InputRead(cc,&lines) || cc->cur_buf_ptr || lines!=0x100000003) return 57;
  buffer[0]='P'; buffer[1]='\n'; buffer[2]=0;
  LexFileSeed(root,buffer); cc->cur_buf_ptr=buffer; lines=0;
  if(InputRead(cc,&lines)!='P') return 58;
  root->buf_ptr=cc->cur_buf_ptr; root->last_U16='R';
  child=InputPush(cc); if(!child) return 59;
  child->buf=StateAlloc(8); child->full_name=StateAlloc(8);
  child->buf[0]='c'; child->buf[1]='\n'; LexFileSeed(child,child->buf); cc->cur_buf_ptr=child->buf;
  if(InputRead(cc,&lines)!='c' || InputRead(cc,&lines)!='\n' || InputRead(cc,&lines)!='R' ||
      cc->lex_include_stk!=root || cc->cur_buf_ptr!=buffer+1 || lines!=1 || root->line_num!=1) return 60;
  if(InputRead(cc,&lines)!='\n' || InputRead(cc,&lines) || lines!=2 || root->line_num!=2) return 61;
  buffer[0]='z'; buffer[1]=0; LexFileSeed(root,buffer); root->last_U16=0;
  child=InputPush(cc); if(!child) return 62;
  LexFileSeed(child,StateAlloc(8));
  child=InputPush(cc); if(!child) return 63;
  LexFileSeed(child,StateAlloc(8)); cc->cur_buf_ptr=child->buf;
  if(InputRead(cc,&lines)!='z' || cc->lex_include_stk!=root || InputRead(cc,&lines)) return 64;
  if(!InputPop(cc) || cc->lex_include_stk) return 65;
  StateFree(buffer); StateFree(cc); return 0;
}
