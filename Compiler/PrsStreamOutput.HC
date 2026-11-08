U0 StreamPrint(U8 *fmt,...)
{//Injects text into the compile stream. Used in #exe{} blocks.
  U8 *buf=StrPrintJoin(NULL,fmt,argc,argv),*st;
  CCmpCtrl *cc=Fs->last_cc;
  CStreamBlk *tmpe=cc->last_stream_blk;
  if (tmpe!=&cc->next_stream_blk) {
    st=MStrPrint("%s%s",tmpe->body,buf);
    Free(tmpe->body);
    tmpe->body=st;
  } else
    PrintErr("No exe{} blk\n");
  Free(buf);
}

U0 StreamDir()
{
  U8 *dirname;
  if (dirname=DirFile(Fs->last_cc->lex_include_stk->full_name)) {
    StreamPrint("\"%s\"",dirname);
    Free(dirname);
  }
}

