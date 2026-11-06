public U8 *PopUpPickDir(U8 *dir=NULL)
{//File dir name chooser.  Uses $LK,"FileMgr",A="MN:FileMgr"$().
  U8 *res,*st,*st2;
  if (dir)
    st=MStrPrint("Cd(\"%Q\");FileMgr(FM_PICK_DIR,Fs->parent_task);",dir);
  else {
    st2=DirCur;
    st=MStrPrint("Cd(\"%Q\");FileMgr(FM_PICK_DIR,Fs->parent_task);",st2);
    Free(st2);
  }
  res=PopUp(st,Fs);
  Free(st);
  return res;
}

