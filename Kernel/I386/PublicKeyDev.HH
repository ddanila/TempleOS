#ifndef I386_PUBLIC_KEYDEV_INCLUDED
#define I386_PUBLIC_KEYDEV_INCLUDED
#include "/Kernel/NumericLimits.HH"
#include "/Kernel/TimeTypes.HH"
#include "/Kernel/KeyDevTypes.HH"
#include "/Kernel/ScanFlags.HH"
#include "/Kernel/GetStrFlags.HH"
public _extern _CHAR_2_SCAN_CODE I64 Char2ScanCode(I64 ch,I64 sc_flags=0);
public _extern _SCAN_CODE_2_CHAR U8 ScanCode2Char(I64 sc);
public _extern _SCAN_CODE_2_KEY_NAME U8 *ScanCode2KeyName(I64 sc);
public _extern _CTRL_ALT_CB_SET U0 CtrlAltCBSet(U8 ch,U0 (*callback)(I64 sc),U8 *plain=NULL,U8 *shifted=NULL,Bool in_irq=FALSE);
public _extern _KEY_MAP_FAMILY U0 KeyMapFamily(CTask *task,I64 scf,Bool no_shift,Bool shift);
public _extern _KEY_MAP_CTRL_ALT_FAMILY U0 KeyMapCtrlAltFamily(Bool no_shift,Bool shift);
public _extern _KEY_MAP U0 KeyMap(CTask *task=NULL);
public _extern _KEYDEV CKeyDevGlbls keydev;
public _extern _CHAR_2_KEY_NAME U8 *Char2KeyName(I64 ch,Bool include_ctrl=TRUE);
public _extern _KEY_DESC_SET U0 KeyDescSet(U8 *fmt,...);
public _extern _PUT_KEY U0 PutKey(I64 ch=0,I64 sc=0);
public _extern _KEY_DEV_ADD CKeyDevEntry *KeyDevAdd(Bool (*key)(I64 ch,I64 sc),
  Bool (*text)(U8 *s),I64 priority,Bool key_descs=FALSE);
public _extern _KEY_DEV_REM U0 KeyDevRem(CKeyDevEntry *entry);
public _extern _SCAN_KEY Bool ScanKey(I64 *ch=0,I64 *sc=0,Bool echo=FALSE);
public _extern _GET_KEY I64 GetKey(I64 *sc=0,Bool echo=FALSE,Bool raw_cursor=FALSE);
public _extern _GET_STR U8 *GetStr(U8 *msg=NULL,U8 *dft=NULL,I64 flags=0);
public _extern _GET_I64 I64 GetI64(U8 *msg=NULL,I64 dft=0,I64 lo=I64_MIN,I64 hi=I64_MAX);
public _extern _GET_F64 F64 GetF64(U8 *msg=NULL,F64 dft=0,F64 lo=F64_MIN,F64 hi=F64_MAX);
public _extern _GET_DATE CDate GetDate(U8 *msg=NULL,CDate dft=I64_MIN,CDate lo=I64_MIN,CDate hi=I64_MAX);
public _extern _DOC_GET_STR2 U8 *DocGetStr2(I64 flags=0);
public _extern _FP_GETSTR2 U8 *(*fp_getstr2)(I64 flags=0);
#endif
