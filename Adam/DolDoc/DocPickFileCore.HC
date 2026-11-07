public U8 *PopUpPickFile(U8 *dir=NULL)
{//Filename chooser.  Uses $LK,"FileMgr",A="MN:FileMgr"$().
  U8 *res,*st,*st2;
  if (dir)
    st=MStrPrint("Cd(\"%Q\");FileMgr(FM_PICK_FILE,Fs->parent_task);",dir);
  else {
    st2=DirCur;
    st=MStrPrint("Cd(\"%Q\");FileMgr(FM_PICK_FILE,Fs->parent_task);",st2);
    Free(st2);
  }
  res=PopUp(st,Fs);
  Free(st);
  return res;
}

