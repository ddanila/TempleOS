#define REGISTRY_FILENAME "~/Registry.HC.Z"
#ifndef REGISTRY_GLOBALS_DEFINED
#include "/Adam/RegistryGlobals.HC"
#endif

Bool RegCache()
{
  Bool old_silent;
  if (!sys_registry_doc) {
    old_silent=Silent;
    sys_registry_doc=DocRead(REGISTRY_FILENAME);
    Silent(old_silent);
    return FALSE;
  } else
    return TRUE;
}

public Bool RegDft(U8 *path,U8 *val,Bool is_adam_entry=FALSE)
{//Add code doc tree branch to registry.
  Bool res,unlock_doc;
  RegCache;
  unlock_doc=DocLock(sys_registry_doc);
  if (!DocTreeFind(sys_registry_doc,path)) {
    DocTreeMake(sys_registry_doc,path);
    DocPrint(sys_registry_doc,"%s",val);
    if (is_adam_entry) {
      if (Fs==adam_task)
	ExePrint("%s",val);
      else
	Adam("%s",val);
    }
    if (DrvIsWritable(*sys_registry_doc->filename.name))
      DocWrite(sys_registry_doc);
    res=FALSE;
  } else
    res=TRUE;
  if (unlock_doc)
    DocUnlock(sys_registry_doc);
  return res;
}

public I64 RegExe(U8 *path)
{//Execute doc tree branch in registry.
  RegCache;
  return DocTreeExe(sys_registry_doc,path);
}

public Bool RegWrite(U8 *path,U8 *fmt,...)
{//Rewrite doc tree branch in registry.
  Bool res;
  RegCache;
  res=DocTreeWriteJoin(sys_registry_doc,path,TRUE,fmt,argc,argv);
  return res;
}

public I64 RegCnt(U8 *path)
{//Tree branch cnt in registry.
  I64 res=0;
  CDocEntry *tree_branch,*start_indent,*end_indent;
  Bool unlock_doc=DocLock(sys_registry_doc);
  if (DocTreeFind(sys_registry_doc,path,
	&tree_branch,&start_indent,&end_indent)) {
    end_indent=end_indent->next;
    while (start_indent!=end_indent) {
      res++;
      start_indent=start_indent->next;
    }
  }
  if (unlock_doc)
    DocUnlock(sys_registry_doc);
  return res;
}

public Bool RegAppend(U8 *path,U8 *fmt,...)
{//Append to doc tree branch in registry.
  Bool res;
  RegCache;
  res=DocTreeAppendJoin(sys_registry_doc,path,TRUE,fmt,argc,argv);
  return res;
}
