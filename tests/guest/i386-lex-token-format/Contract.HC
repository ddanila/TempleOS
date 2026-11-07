U0 LFLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 LFCheck(){CDoc *out=DocNew,*put=Fs->put_doc;CCmpCtrl *cc=CmpCtrlNew(StrNew("line\n"),0,"C:/Probe/Tokens.HC");U8 *bytes,*s;I64 size;Bool raw=Raw(OFF);
Fs->put_doc=out;
cc->cur_str=StrNew("hello");cc->token=TK_IDENT;LexPutToken(cc);cc->token=TK_STR;LexPutToken(cc);
cc->token=TK_I64;cc->cur_i64=0x123456789ABCDEF;LexPutToken(cc);
cc->token=TK_CHAR_CONST;cc->cur_i64='AB';LexPutToken(cc);
cc->token=TK_F64;cc->cur_f64=1.25;LexPutToken(cc);
cc->token='\n';LexPutToken(cc);cc->token='+';LexPutToken(cc);cc->token=0x126;LexPutToken(cc);
bytes=DocSave(out,&size);s=MStrPrint("EXPORT lex-token-format.DD %X %X\n",bytes,size);LFLog(s);Free(s);
Fs->put_doc=put;DocDel(out);CmpCtrlDel(cc);Raw(raw);LFLog("LEX TOKEN FORMAT DONE\n");Sleep(1000);}
LFCheck;
