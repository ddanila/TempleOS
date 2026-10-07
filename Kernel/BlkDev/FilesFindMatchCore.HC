Bool FilesFindMatch(U8 *_test_name,U8 *files_find_mask,I64 fuf_flags=0)
{//Does filename meet $LK,"Files Find",A="FI:::/Doc/FileUtils.DD"$ mask?
  I64 tn_len=StrLen(_test_name),mask_len=StrLen(files_find_mask);
  U8 *mask1=MAlloc(mask_len+1),*mask2=MAlloc(mask_len+1),
	*ptr,*test_name1,*test_name2;
  Bool res=FALSE;
  StrCpy(mask1,files_find_mask);
  if (StrOcc(_test_name,'/')) {
    test_name1=MAlloc(tn_len+1);
    test_name2=MAlloc(tn_len+1);
    StrCpy(test_name1,_test_name);
    StrLastRem(test_name1,"/",test_name2);
  } else {
    test_name1=NULL;
    test_name2=NULL;
  }
  while (TRUE) {
    StrFirstRem(mask1,";",mask2);
    if (!test_name2 || StrOcc(mask2,'/'))
      ptr=_test_name;
    else
      ptr=test_name2;
    if (*mask2) {
      if (*mask2=='!') {
	if (WildMatch(ptr,mask2+1)) {
	  res=FALSE;
	  break;
	}
      } else {
	if (WildMatch(ptr,mask2)) {
	  if (Bt(&fuf_flags,FUf_JUST_TXT) &&
		!FilesFindMatch(_test_name,FILEMASK_TXT)) {
	    res=FALSE;
	    break;
	  } else if (Bt(&fuf_flags,FUf_JUST_DD) &&
		!FilesFindMatch(_test_name,FILEMASK_DD)) {
	    res=FALSE;
	    break;
	  } else if (Bt(&fuf_flags,FUf_JUST_SRC) &&
		!FilesFindMatch(_test_name,FILEMASK_SRC)) {
	    res=FALSE;
	    break;
	  } else if (Bt(&fuf_flags,FUf_JUST_AOT) &&
		!FilesFindMatch(_test_name,FILEMASK_AOT)) {
	    res=FALSE;
	    break;
	  } else if (Bt(&fuf_flags,FUf_JUST_JIT) &&
		!FilesFindMatch(_test_name,FILEMASK_JIT)) {
	    res=FALSE;
	    break;
	  } else if (Bt(&fuf_flags,FUf_JUST_GR) &&
		!FilesFindMatch(_test_name,FILEMASK_GR)) {
	    res=FALSE;
	    break;
	  } else
	    res=TRUE;
	}
      }
    } else
      break;
  }
  Free(test_name1);
  Free(test_name2);
  Free(mask1);
  Free(mask2);
  return res;
}

