#ifndef KEYDEV_SCAN_CODE
#define KEYDEV_SCAN_CODE kbd.scan_code
#endif
U0 PutKey(I64 ch=0,I64 sc=0)
{//See $LK,"Keyboard Devices",A="HI:Keyboard Devices/System"$.
  CKeyDevEntry *tmpk;
  if (ch||sc) {
    tmpk=keydev.put_key_head.next;
    if (!Bt(&Fs->display_flags,DISPLAYf_SILENT)) {
      if (KEYDEV_SCAN_CODE & SCF_SCROLL && sys_focus_task==Fs)
	while (KEYDEV_SCAN_CODE & SCF_SCROLL)
	  Yield; //Wait on SCROLL LOCK Key
      while (tmpk!=&keydev.put_key_head) {
	if ((!(sc&SCF_KEY_DESC) || tmpk->flags & KDF_HAS_DESCS) &&
	      (*tmpk->put_key)(ch,sc))
	  break;
	tmpk=tmpk->next;
      }
    }
  }
}

U0 PutChars(U64 ch)
{//Output chars. Up to 8 chars in a single U64.
//Don't use this.  $LK,"See Print() shortcut.",A="FF:::/Doc/HolyC.DD,DemoHolyC"$
  while (ch) {
    PutKey(ch&255,0);
    ch>>=8;
  }
}

U0 PutS(U8 *st)
{//Use $LK,"Print",A="MN:Print"$(). See $LK,"Keyboard Devices",A="HI:Keyboard Devices/System"$.
//Don't use this.  $LK,"See Print() shortcut.",A="FF:::/Doc/HolyC.DD,DemoHolyC"$
  I64 ch;
  U8 *ptr;
  Bool cont=TRUE;
  if (!st) return;
  CKeyDevEntry *tmpk=keydev.put_key_head.next;
  if (!Bt(&Fs->display_flags,DISPLAYf_SILENT)) {
    if (KEYDEV_SCAN_CODE & SCF_SCROLL && sys_focus_task==Fs)
      while (KEYDEV_SCAN_CODE & SCF_SCROLL)
	Yield;
    while (cont && tmpk!=&keydev.put_key_head) {
      if (tmpk->put_s) {
	if ((*tmpk->put_s)(st))
	  break;
      } else {
	ptr=st;
	while (ch=*ptr++)
	  if ((*tmpk->put_key)(ch,0))
	    cont=FALSE;
      }
      tmpk=tmpk->next;
    }
  }
}

U0 KeyDevRem(CKeyDevEntry *tmpk)
{//Remove StdOut hook and free.
  QueRem(tmpk);
  Free(tmpk);
}

CKeyDevEntry *KeyDevAdd(Bool (*fp_put_key)(I64 ch,I64 sc),
	Bool (*fp_puts)(U8 *st),I64 priority,Bool key_descs=FALSE)
{//Places hook in StdOut chain. See $LK,"Keyboard Devices",A="HI:Keyboard Devices/System"$.
  CKeyDevEntry *tmpk=keydev.put_key_head.last,
	*tmpk1=ACAlloc(sizeof(CKeyDevEntry));
  tmpk1->put_key=fp_put_key;
  tmpk1->put_s=fp_puts;
  tmpk1->priority=priority;
  if (key_descs)
    tmpk1->flags|=KDF_HAS_DESCS;
  while (tmpk->priority>priority)
    tmpk=tmpk->last;
  QueIns(tmpk1,tmpk);
  if (tmpk->priority==priority)
    KeyDevRem(tmpk);
  return tmpk1;
}

