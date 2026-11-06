U0 PLLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 PLCheck()
{
  I64 v[24],used=Fs->data_heap->used_u8s,size;
  U8 *buffer=StrNew("UniquePublicLexName 42 -7 3.5 \"ab\" \"cd\" +\n"),*joined,*s;
  CCmpCtrl *cc=CmpCtrlNew(buffer);
  v[0]=cc && !cc->flags && cc->next==cc && cc->last==cc;
  v[1]=cc->cur_buf_ptr==buffer && cc->lex_include_stk->buf==buffer &&
    cc->htc.glbl_hash_table==Fs->hash_table;
  v[2]=cc->lex_include_stk->line_num==1 && cc->lex_include_stk->full_name &&
    !StrCmp(cc->lex_include_stk->full_name,blkdev.tmp_filename);
  v[3]=Lex(cc)==TK_IDENT && !StrCmp(cc->cur_str,"UniquePublicLexName");
  v[4]=Lex(cc)==TK_I64 && cc->cur_i64==42;
  v[5]=Lex(cc)=='-' && Lex(cc)==TK_I64 && cc->cur_i64==7;
  v[6]=Lex(cc)==TK_F64 && cc->cur_f64==3.5;
  v[7]=Lex(cc)==TK_STR && cc->cur_str_len==3 && !StrCmp(cc->cur_str,"ab");
  joined=LexExtStr(cc,&size);
  v[8]=joined && size==5 && !StrCmp(joined,"abcd") && cc->token=='+';
  Free(joined);v[9]=Lex(cc)==TK_EOF;CmpCtrlDel(cc);
  v[10]=Fs->data_heap->used_u8s==used;
  buffer=StrNew("9");cc=CmpCtrlNew(buffer,CCF_DONT_FREE_BUF);
  v[11]=cc->flags==CCF_DONT_FREE_BUF && cc->cur_buf_ptr==buffer &&
    Bt(cc->char_bmp_alpha_numeric,'@');
  v[12]=Lex(cc)==TK_I64 && cc->cur_i64==9;
  CmpCtrlDel(cc);v[12]=v[12] && !StrCmp(buffer,"9") && MSize(buffer)>=2;Free(buffer);
  cc=CmpCtrlNew(,CCF_PMT);
  v[13]=cc->flags==CCF_PMT && cc->cur_buf_ptr && MSize(cc->cur_buf_ptr)>=8 &&
    !cc->cur_buf_ptr[0];CmpCtrlDel(cc);
  cc=CmpCtrlNew(,CCF_KEEP_AT_SIGN);
  v[14]=cc->flags==CCF_KEEP_AT_SIGN && !Bt(cc->char_bmp_alpha_numeric,'@');
  CmpCtrlDel(cc);v[15]=Fs->data_heap->used_u8s==used;
  cc=CmpCtrlNew(StrNew("#include \"::/PublicLexerSong.HC\""));
  v[16]=Lex(cc)==TK_IDENT && !StrCmp(cc->cur_str,"music") &&
    Lex(cc)=='.' && Lex(cc)==TK_IDENT && !StrCmp(cc->cur_str,"tempo") &&
    Lex(cc)=='=' && Lex(cc)==TK_F64 && cc->cur_f64==2.5 && Lex(cc)==';';
  v[17]=Lex(cc)==TK_IDENT && !StrCmp(cc->cur_str,"Play") &&
    Lex(cc)=='(' && Lex(cc)==TK_STR;
  joined=LexExtStr(cc,&size);
  v[18]=size==8 && !StrCmp(joined,"5qCqDqE") && cc->token==',';Free(joined);
  v[19]=Lex(cc)==TK_STR;
  joined=LexExtStr(cc,&size);
  v[19]=v[19] && size==9 && !MemCmp(joined,"one\0two\0",9) && cc->token==')';Free(joined);
  v[20]=Lex(cc)==';' && Lex(cc)==TK_EOF;CmpCtrlDel(cc);
  v[21]=Fs->data_heap->used_u8s==used;
  cc=CmpCtrlNew(StrNew("\"single\"+"));
  Lex(cc);buffer=cc->cur_str;joined=LexExtStr(cc,&size,FALSE);
  v[22]=joined==buffer && size==7 && !StrCmp(joined,"single") &&
    !cc->cur_str && cc->token==TK_STR && Lex(cc)=='+';
  Free(joined);CmpCtrlDel(cc);
  v[23]=Fs->data_heap->used_u8s==used;
  s=MStrPrint("EXPORT public-lexer.bin %X %X\n",v,sizeof(v));PLLog(s);Free(s);
  PLLog("PUBLIC LEXER DONE\n");Sleep(1000);
}
