#include "/Kernel/BlkDev/FileNames.HC"
#include "/Kernel/BlkDev/FilePaths.HC"

U8 *FileExtRem(U8 *src,U8 *dst=NULL)
{//Remove filename extension from str.
  U8 *ptr;
  if (ptr=FileExtDot(src)) {
    if (dst)
      StrCpy(dst,ptr+1);
    *ptr=0;
  } else if (dst)
    *dst=0;
  return dst;
}

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

U0 FilePathTaskContext(CFilePathContext *context)
{
  context->cur_dir=Fs->cur_dir;
  context->home_dir=blkdev.home_dir;
  context->white_space=char_bmp_white_space;
  context->cur_drv=0;
  if(context->cur_dir && *context->cur_dir) context->cur_drv=Drv2Let;
  context->boot_drv=blkdev.boot_drv_let;
}

U8 *DirNameAbs(U8 *_dirname)
{//MAlloc absolute dir string with drv letter.
  CFilePathContext context;
  U8 *work,*res;
  if(!_dirname) _dirname="";
  FilePathTaskContext(&context);
  work=MAlloc(StrLen(_dirname)+2);
  res=MAlloc(FilePathCapacity(_dirname,&context));
  FilePathCopy(work,_dirname);
  FilePathDirWrite(res,work,&context);
  Free(work);
  return res;
}

U8 *FileNameAbs(U8 *_filename,I64 fuf_flags=0)
{//Absolute filename. Accepts $LK,"FUF_Z_OR_NOT_Z",A="MN:FUF_Z_OR_NOT_Z"$, $LK,"FUF_SCAN_PARENTS",A="MN:FUF_SCAN_PARENTS"$.
  CFilePathContext context;
  CDirEntry de;
  U8 *work,*res;
  I64 length;
  if(!_filename) _filename="";
  FilePathTaskContext(&context);
  length=StrLen(_filename);
  work=MAlloc((length+2)*2);
  res=MAlloc(FilePathCapacity(_filename,&context));
  FilePathCopy(work,_filename);
  FilePathFileWrite(res,work,work+length+2,&context);
  Free(work);
  if (fuf_flags && FileFind(res,&de,fuf_flags|FUF_JUST_FILES)) {
    Free(res);
    res=de.full_name;
  }
  return res;
}

U8 *ExtChg(U8 *filename,U8 *extension)
{//Change filename extension.
  U8 *res=MAlloc(StrLen(filename)+1+StrLen(extension)+1);
  StrCpy(res,filename);
  if (FileExtDot(filename))
    FileExtRem(res);
  return CatPrint(res,".%s",extension);
}

U8 *ExtDft(U8 *filename,U8 *extension)
{//Give extension if has none.
  U8 *res=MAlloc(StrLen(filename)+1+StrLen(extension)+1);
  return FileNameWriteDefault(res,filename,extension);
}

CDirEntry *Cd2DirEntry(CDirEntry *tmpde,U8 *abs_name)
{
  I64 i;
  while (tmpde) {
    i=StrLen(tmpde->full_name);
    if (StrNCmp(tmpde->full_name,abs_name,i)||
	  i && tmpde->full_name[i-1]!='/' && abs_name[i] && abs_name[i]!='/')
      tmpde=tmpde->next;
    else
      if (StrLen(abs_name)==i)
	return tmpde;
      else
	return Cd2DirEntry(tmpde->sub,abs_name);
  }
  return NULL;
}

Bool FileNameChk(U8 *filename)
{//Return check for valid filename, not checking existence.
  U8 *ptr=filename;
  if (!filename) return FALSE;
  if (!*ptr) return FALSE;
  if (*ptr=='.') {
    if (!ptr[1]) return TRUE;
    if (ptr[1]=='.' && !ptr[2]) return TRUE;
  }
  if (StrLen(filename)>=CDIR_FILENAME_LEN) return FALSE;
  while (*ptr)
    if (!Bt(char_bmp_filename,*ptr++))
      return FALSE;
  return TRUE;
}

U8 *ToggleZorNotZ(U8 *name)
{//MAlloc name with Z if not Z or vice versa.
  I64 size=StrLen(name)+3;
  if(IsDotZ(name)) size-=2;
  return FileNameWriteToggle(MAlloc(size),name);
}

U8 *FileNameTmpTxt()
{//Make pretty-safe tmp filename in home dir.
  return MStrPrint("~/SysTmp%X.DD.Z",GetTSC>>8&0xFFFFFFFF);
}

U8 *DirCur(CTask *task=NULL,CTask *mem_task=NULL)
{//MAlloc copy of cur dir with drv letter.
  U8 *st;
  if (!task) task=Fs;
  if (!task->cur_dir)
    return NULL;
  st=MAlloc(StrLen(task->cur_dir)+3,mem_task);
  *st=Drv2Let(task->cur_dv);
  st[1]=':';
  StrCpy(st+2,task->cur_dir);
  return st;
}

U8 *DirFile(U8 *dirname,U8 *name=NULL,U8 *_extension=NULL)
{/*Strips file from dirname, scans for file upward until found or
returns default.

("/Kernel/KHashA.HC.Z",NULL,NULL)	returns "D:/Kernel"
("/Kernel",NULL,"PRJ.Z")		returns "D:/Kernel/Kernel.PRJ.Z"
("/Kernel/BlkDev",NULL,"PRJ.Z")		returns "D:/Kernel/Kernel.PRJ.Z"
("/Apps/Psalmody","Load","HC.Z")	returns "D:/Apps/Psalmody/Load.HC.Z"
*/
  U8 *st=DirNameAbs(dirname),*st2,*st3,*res,*dft=NULL,*ext;
  if (_extension && *_extension) {
    if (*_extension=='.')
      ext=StrNew(_extension);
    else
      ext=MStrPrint(".%s",_extension);
  } else
    ext=StrNew("");
  while (StrOcc(st,'/')&&!IsDir(st))
    StrLastRem(st,"/");
  while (StrOcc(st,'/')) {
    st2=StrNew(st);
    st3=StrNew(st);
    StrLastRem(st2,"/",st3);

    if (name)
      res=MStrPrint("%s/%s%s",st,name,ext);
    else {
      if (*ext)
	res=MStrPrint("%s/%s%s",st,st3,ext);
      else
	res=StrNew(st);
    }
    if (!dft)
      dft=StrNew(res);
    if (!*ext && (!name||!*name) || FileFind(res)) {
      Free(st3);
      Free(st2);
      Free(st);
      Free(dft);
      Free(ext);
      return res;
    }
    Free(st);
    st=st2;
    Free(st3);
  }
  Free(st);
  Free(ext);
  return dft;
}
