U0 AdamErr(U8 *fmt,...)
{//Display red blinking Err text in adam_task.
  U8 *buf=StrPrintJoin(NULL,fmt,argc,argv),
	*st=MStrPrint(ST_ERR_ST "%s",buf);
  if (Fs==adam_task)
    "%s",st;
  else if (!IsSingleUser)
    Adam("\"%%s\",%d;",st);
  Free(st);
  Free(buf);
}

