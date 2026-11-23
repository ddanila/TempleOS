public U8 *FileNameForm(U8 *dft=NULL,I64 dof_flags=0,CTask *mem_task=NULL)
{//Text filename form in cur win, not PopUp.
  CEdFileName fn;
  if (dft)
    StrCpy(fn.name,dft);
  else
    *fn.name=0;
  if (DocForm(&fn,,dof_flags))
    return StrNew(fn.name,mem_task);
  else
    return NULL;
}

public U8 *PopUpFileName(U8 *dft=NULL,I64 dof_flags=0)
{//Filename chooser. Uses form, not $LK,"FileMgr",A="MN:FileMgr"$().
  U8 *st=MStrPrint("FileNameForm(\"%Q\",0x%X,Fs->parent_task);",
	dft,dof_flags|DOF_SIZE_MIN),*res=PopUp(st,Fs);
  Free(st);
  return res;
}
