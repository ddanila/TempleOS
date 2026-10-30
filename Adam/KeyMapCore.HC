//Original key-map collection, formatting and display.
U8 *KeyMapKeyMStrPrint(I64 sc,U0 (*fp_hndlr)(I64 sc),
	U8 *desc,CTask *task=NULL)
{
  I64 i=9,k,c;
  U8 *st,*st2,*res,*ptr;
  CHashTable *old_hash=Fs->hash_table;
  st=ScanCode2KeyName(sc);
  if (sc&SCF_CTRL)	i+=5;
  if (sc&SCF_ALT)	i+=4;
  if (sc&(SCF_SHIFT|SCF_NO_SHIFT)) i+=6;
  if (TaskValidate(task))
    Fs->hash_table=task->hash_table;
  st2=SrcEdLink(fp_hndlr,256);
  Fs->hash_table=old_hash;

  k=*desc(U32 *);
  if (k=='Edit')	c=BLUE;
  else if (k=='Dol ')	c=GREEN;
  else if (k=='Cmd ')	c=RED;
  else			c=BLACK;

  res=MStrPrint("%-*s $$FG,%d$$$$TX+UL+L+PU,\"%$$Q\",A=\"%s\"$$$$FG$$\n",
	i,st,c,desc,st2);
  Free(st);
  Free(st2);

  ptr=res;
  while (*ptr) {
    if (*ptr==CH_SPACE)
      *ptr=CH_SHIFT_SPACE;
    ptr++;
  }

  return res;
}

U0 KeyMapKeyPrint(I64 sc,U0 (*fp_hndlr)(I64 sc),U8 *desc,CTask *task=NULL)
{
  U8 *st=KeyMapKeyMStrPrint(sc,fp_hndlr,desc,task);
  "%s",st;
  Free(st);
}

U0 KeyMapCtrlAltFamily(Bool no_shift,Bool shift)
{
  I64 i,no_shift_f;
  if (no_shift && shift)
    no_shift_f=SCF_NO_SHIFT;
  else
    no_shift_f=0;
  if (no_shift) KeyMapKeyPrint(SC_DELETE+SCF_CTRL+SCF_ALT+no_shift_f,
	  &Reboot,"Cmd /Reboot");
  if (no_shift) KeyMapKeyPrint(SC_ESC+SCF_CTRL+SCF_ALT+no_shift_f,
	  &User,"Cmd /Terminal Window");
  if (no_shift) KeyMapKeyPrint(SC_TAB+SCF_CTRL+SCF_ALT+no_shift_f,
	  &WinToTop,"Cmd /Next Focus Task");

  for (i=0;i<26;i++)
    if (keydev.fp_ctrl_alt_cbs[i]) {
      if (no_shift && keydev.ctrl_alt_no_shift_descs[i])
	KeyMapKeyPrint(Char2ScanCode(i+'a')+SCF_CTRL+SCF_ALT+no_shift_f,
	      keydev.fp_ctrl_alt_cbs[i],keydev.ctrl_alt_no_shift_descs[i]);
      if (shift && keydev.ctrl_alt_shift_descs[i])
	KeyMapKeyPrint(Char2ScanCode(i+'a')+SCF_CTRL+SCF_ALT+SCF_SHIFT,
	      keydev.fp_ctrl_alt_cbs[i],keydev.ctrl_alt_shift_descs[i]);
    }
}

#include "/Adam/KeyMapSortCore.HC"

U0 KeyMapFamily2(I64 *entries,CTask *task,I64 scf)
{
  I64 i,arg1,arg2;
  for (i=0;i<256;i++) {
    arg2=scf|i|SCF_KEY_DESC;
    arg1=ScanCode2Char(arg2);
    *keydev.desc=0;
    keydev.hndlr=NULL;
    if (TaskValidate(task) && !Bt(&task->win_inhibit,WIf_SELF_KEY_DESC)) {
      if (task==Fs)
	PutKey(arg1,arg2);
      else
	PostMsg(task,MSG_KEY_DOWN,arg1,arg2);
      Refresh(0,TRUE);
      Sleep(1); //Open loop because might be no response.  TODO: Drops msgs.
    }
    if (*keydev.desc && StrNCmp(keydev.desc,"Char  /",7))
      entries[i]=KeyMapKeyMStrPrint(arg2,keydev.hndlr,keydev.desc,task)(I64);
  }
}

U0 KeyMapFamily(CTask *task,I64 scf,Bool no_shift,Bool shift)
{
  I64 i,cnt=0,*entries=CAlloc(2*256*sizeof(I64)),*ptr=entries;
  U8 *entry;
  if (no_shift) {
    if (shift)
      KeyMapFamily2(ptr,task,scf+SCF_NO_SHIFT);
    else
      KeyMapFamily2(ptr,task,scf);
    ptr+=256;
    cnt+=256;
  }
  if (shift) {
    KeyMapFamily2(ptr,task,scf+SCF_SHIFT);
    ptr+=256;
    cnt+=256;
  }
  QSortI64(entries,cnt,&KMCompare);
  for (i=0;i<cnt;i++)
    if (entries[i]) {
      entry=entries[i](U8 *);
      "%s",entry;
      Free(entry);
    }
  Free(entries);
}

public U0 KeyMap(CTask *task=NULL)
{//Report desc of all keys.
  Bool old_key_desc;
  if (!task) task=Fs;
  old_key_desc=LBtr(&task->win_inhibit,WIf_SELF_KEY_DESC);
  DocMax;
  KeyMapFamily(task,0,TRUE,TRUE);
  KeyMapFamily(task,SCF_CTRL,TRUE,TRUE);
  KeyMapFamily(task,SCF_ALT,TRUE,TRUE);
  KeyMapCtrlAltFamily(TRUE,TRUE);
  LBEqu(&task->win_inhibit,WIf_SELF_KEY_DESC,old_key_desc);
  "\nKeyMap Completed.\n";
}
