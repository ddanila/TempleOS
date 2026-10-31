public I64 AdamFile(U8 *filename,Bool warn_ext=TRUE)
{//Make adam_task execute file.
  Bool okay=TRUE;
  U8 *name=FileNameAbs(filename),
	*name2=ExtDft(name,"HC.Z");
  I64 res=0;
  if (warn_ext &&
	!FilesFindMatch(name2,FILEMASK_JIT) &&
	!PopUpCancelOk(ST_WARN_ST "Not .HC File\n\n"))
    okay=FALSE;
  if (okay)
    res=Adam("#include \"%s\";",name2);
  Free(name2);
  Free(name);
  return res;
}
