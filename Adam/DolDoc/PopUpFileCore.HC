public I64 PopUpFile(U8 *filename,Bool warn_ext=TRUE,
	CTask *parent=NULL,CTask **_pu_task=NULL)
{//$LK,"ExeFile2",A="MN:ExeFile2"$() in $LK,"PopUp",A="MN:PopUp"$ task. Cont as User.
  Bool okay=TRUE;
  U8 *st,*name=FileNameAbs(filename),
	*name2=ExtDft(name,"HC.Z");
  I64 res=0;
  if (warn_ext &&
	!FilesFindMatch(name2,FILEMASK_JIT) &&
	!PopUpCancelOk(ST_WARN_ST "Not .HC File\n\n"))
    okay=FALSE;
  if (okay) {
    st=MStrPrint(
	  "\"$$$$WW+H,1$$$$\";In(\"ExeFile2(\\\"%s\\\",CCF_CMD_LINE);\\n\");"
	  "UserTaskCont;",
	  name2);
    res=PopUp(st,parent,_pu_task);
    Free(st);
  }
  Free(name2);
  Free(name);
  return res;
}
