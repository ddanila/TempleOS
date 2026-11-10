U0 HomePathReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
Bool home_cd_default=Cd;
U8 *home_default_dir=DirCur;
U8 *home_file=FileNameAbs("~/HomeSys.HC");
Bool home_cd_root=Cd("::/");
Bool home_cd_tilde=Cd("~");
U8 *home_tilde_dir=DirCur;
U8 *home_record=MStrPrint("%d|%s|%s|%d|%d|%s\n",home_cd_default,
  home_default_dir,home_file,home_cd_root,home_cd_tilde,home_tilde_dir);
U8 *home_export=MStrPrint("EXPORT home-path.bin %X %X\n",home_record,StrLen(home_record));
HomePathReport(home_export);
HomePathReport("DONE original home path\n");
