#ifndef I386_PUBLIC_KEYDEV_INCLUDED
#define I386_PUBLIC_KEYDEV_INCLUDED
#include "/Kernel/KeyDevTypes.HH"
#include "/Kernel/ScanFlags.HH"
public _extern _KEYDEV CKeyDevGlbls keydev;
public _extern _CHAR_2_KEY_NAME U8 *Char2KeyName(I64 ch,Bool include_ctrl=TRUE);
public _extern _KEY_DESC_SET U0 KeyDescSet(U8 *fmt,...);
public _extern _PUT_KEY U0 PutKey(I64 ch=0,I64 sc=0);
public _extern _KEY_DEV_ADD CKeyDevEntry *KeyDevAdd(Bool (*key)(I64 ch,I64 sc),
  Bool (*text)(U8 *s),I64 priority,Bool key_descs=FALSE);
public _extern _KEY_DEV_REM U0 KeyDevRem(CKeyDevEntry *entry);
public _extern _SCAN_KEY Bool ScanKey(I64 *ch=0,I64 *sc=0,Bool echo=FALSE);
public _extern _GET_KEY I64 GetKey(I64 *sc=0,Bool echo=FALSE,Bool raw_cursor=FALSE);
#endif
