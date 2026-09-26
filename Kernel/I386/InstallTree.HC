//Installer transport over normal task file services. Source and target must be
//different absolute drives. Return the number of copied files or -1 on error.
Bool I386InstallTreeNode(U8 *source,U8 *target,I64 depth,I64 *copied,I64 limit)
{
  U8 *listing=0,*data=0,*at,*start,source_path[256],target_path[256];
  I64 needed,size,attr,length,i,j;
  Bool directory,ok=TRUE;
  if(depth>16 || !console_config || !console_config->files) return FALSE;
  needed=(*console_config->files->dir_list)(source,NULL,0,NULL);
  if(needed<1 || !(listing=I386HeapAlloc(console_config->heap,needed))) return FALSE;
  if((*console_config->files->dir_list)(source,listing,needed,NULL)!=needed) ok=FALSE;
  at=listing;
  while(ok && *at && (!limit || *copied<limit)) {
    start=at;
    while(*at && *at!='\n') at++;
    if(*at!='\n') { ok=FALSE; break; }
    length=at-start; at++;
    directory=length && start[length-1]=='/';
    if(directory) length--;
    if(!((length==1 && start[0]=='.') ||
        (length==2 && start[0]=='.' && start[1]=='.'))) {
    if(length<1 || length>37) { ok=FALSE; break; }
    i=0;
    while(source[i] && i<254) { source_path[i]=source[i]; i++; }
    if(source[i] || i<3 || i+length+2>256) { ok=FALSE; break; }
    if(source_path[i-1]!='/') source_path[i++]='/';
    for(j=0;j<length;j++) source_path[i++]=start[j];
    source_path[i]=0;
    i=0;
    while(target[i] && i<254) { target_path[i]=target[i]; i++; }
    if(target[i] || i<3 || i+length+2>256) { ok=FALSE; break; }
    if(target_path[i-1]!='/') target_path[i++]='/';
    for(j=0;j<length;j++) target_path[i++]=start[j];
    target_path[i]=0;
    if(directory) {
      if(!(*console_config->files->dir_mk)(target_path,0) &&
          !(*console_config->files->dir_list)(target_path,NULL,0,NULL)) {
        ok=FALSE; break;
      }
      if(!I386InstallTreeNode(source_path,target_path,depth+1,copied,limit)) {
        ok=FALSE; break;
      }
    } else {
      data=(*console_config->files->read_raw)(console_config->heap,source_path,&size,&attr,NULL);
      if(!data) { ok=FALSE; break; }
      if(!(*console_config->files->write)(target_path,data,size,attr)) ok=FALSE;
      if(!I386HeapFree(console_config->heap,data)) ok=FALSE;
      data=0;
      if(!ok) break;
      (*copied)++;
    }
    }
  }
  if(data && !I386HeapFree(console_config->heap,data)) ok=FALSE;
  if(!I386HeapFree(console_config->heap,listing)) ok=FALSE;
  return ok;
}
//A positive limit permits a bounded pass that a later call can resume.
public I64 I386InstallTree(U8 *source,U8 *target,I64 limit=0)
{
  I64 copied=0;
  if(!source || !target || source[1]!=':' || target[1]!=':' ||
      source[2]!='/' || target[2]!='/' || source[0]==target[0] || limit<0) return -1;
  if(!I386InstallTreeNode(source,target,0,&copied,limit)) return -1;
  return copied;
}
