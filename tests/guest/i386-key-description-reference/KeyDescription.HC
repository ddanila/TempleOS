Bool KNCheck(I64 ch,U8*want,Bool ctrl=TRUE)
{U8*s=Char2KeyName(ch,ctrl);Bool r=s&&!StrCmp(s,want);Free(s);return r;}
I64 KNContract()
{
  I64 before=Fs->data_heap->used_u8s,m=0;
  U8 dollar[2];dollar[0]=36;dollar[1]=0;
  if(KNCheck('\n',"ENTER")&&KNCheck(CH_BACKSPACE,"BACKSPACE")&&KNCheck('\t',"TAB"))m|=1;
  if(KNCheck(CH_SPACE,"SPACE",FALSE)&&KNCheck(CH_SHIFT_SPACE,"SHIFT_SPACE",FALSE)&&
     KNCheck(CH_ESC,"ESC")&&KNCheck(CH_SHIFT_ESC,"SHIFT_ESC"))m|=2;
  if(KNCheck('X',"X",FALSE)&&KNCheck('0',"0")&&KNCheck(36,dollar,FALSE))m|=4;
  if(KNCheck(0,"")&&KNCheck(29,"")&&KNCheck(30,"")&&KNCheck(256,"")&&KNCheck(127,""))m|=8;
  if(KNCheck(1,"CTRL a")&&KNCheck(3,"CTRL c")&&KNCheck(26,"CTRL z")&&
     KNCheck(1,"a",FALSE)&&KNCheck(3,"c",FALSE)&&KNCheck(26,"z",FALSE))m|=16;
  if(Fs->data_heap->used_u8s==before)m|=32;
  return m;
}
U8 *KDDescribe(I64 n){KeyDescSet("Edit/%d %s",n,"demo");return keydev.hndlr;}
U8 *KDDescribeOther(){KeyDescSet("%s","Other");return keydev.hndlr;}
I64 KDContract()
{
  I64 before=Fs->data_heap->used_u8s,m=0;
  U8 old[STR_LEN],*old_handler=keydev.hndlr,*h1,*h2;
  StrCpy(old,keydev.desc);
  h1=KDDescribe(42);if(!StrCmp(keydev.desc,"Edit/42 demo"))m|=1;
  h2=KDDescribe(-0x123456789);if(h1&&h1==h2&&!StrCmp(keydev.desc,"Edit/-4886718345 demo"))m|=2;
  h2=KDDescribeOther;if(h2&&h2!=h1&&!StrCmp(keydev.desc,"Other"))m|=4;
  KeyDescSet("");if(!*keydev.desc&&keydev.hndlr)m|=8;
  if(Fs->data_heap->used_u8s==before)m|=16;
  StrCpy(keydev.desc,old);keydev.hndlr=old_handler;
  if(!StrCmp(keydev.desc,old)&&keydev.hndlr==old_handler)m|=32;
  return m;
}
I64 KNRun(){I64 m=KNContract;if(m!=63)throw('KeyName',TRUE);return m;}
I64 KDRun(){I64 m=KDContract;if(m!=63)throw('KeyDesc',TRUE);return m;}
