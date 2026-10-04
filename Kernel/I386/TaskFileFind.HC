#include "/Kernel/I386/TaskFileRead.HH"
#include "/Kernel/DirEntryTypes.HH"
Bool I386FindAccept(CI386RedSeaEntry *entry,I64 flags)
{
  if(flags&0x400 && !(entry->attr&0x10)) return FALSE;
  if(flags&0x800 && entry->attr&0x10) return FALSE;
  return TRUE;
}
Bool I386FindParentPath(U8 *path)
{//The absolute normalized path strictly shortens; no directory cycles are followed.
  I64 i=0,last=-1,previous=-1,j;
  while(path[i]) {if(path[i]=='/') {previous=last;last=i;}i++;}
  if(previous<2 || last<3) return FALSE;
  j=last+1; i=previous+1;
  do path[i++]=path[j]; while(path[j++]);
  return TRUE;
}
I64 I386TaskFileFind(CI386Heap *heap,U8 *filename,CDirEntry *entry,I64 options)
{
  U32 saved=I386IrqSave;
  CI386TaskFiles *state;
  CFilePathContext paths;
  CI386FileVolumes *volumes;
  CI386RedSea *volume=0;
  CI386RedSeaEntry found,directory;
  U8 *absolute=0,*candidate=0,*name;
  I64 drive,phase,variant,limit=1,status,i,last,hops;
  I64 result=0;
  Bool opened=FALSE;
  if(entry) for(i=0;i<sizeof(CDirEntry);i++) entry(U8 *)[i]=0;
  state=I386TaskFilesBorrow(I386TaskSelf,&paths,&volumes);
  if(!state) goto find_done;
  absolute=I386FileNameAbs(heap,&paths,filename);
  if(!absolute) goto find_release;
  drive=absolute[0];if('a'<=drive<='z')drive-=32;
  if(!('A'<=drive<='Z') || absolute[1]!=':' || absolute[2]!='/') {result=-1;goto find_release;}
  volume=volumes->letter[drive-'A'];
  if(!volume) {result=-1;goto find_release;}
  if(!I386RedSeaBegin(volume)) goto find_release;
  opened=TRUE;
  if(options&0x40000) limit=2;
  for(phase=0;phase<2;phase++) {
    if(phase && !(options&0x100000)) break;
    for(variant=0;variant<limit;variant++) {
      if(variant) candidate=I386ToggleZorNotZ(heap,absolute);
      else candidate=I386FileNameAbs(heap,&paths,absolute);
      if(!candidate) goto find_release;
      if(phase) {
        //Original parent search requires an existing starting directory.
        last=-1;for(i=2;candidate[i];i++)if(candidate[i]=='/')last=i;
        if(last<=2) goto find_next;
        candidate[last]=0;
        status=I386RedSeaResolve(volume,volume->root,candidate+2,&directory);
        candidate[last]='/';
        if(status!=1 || !(directory.attr&0x10)) goto find_next;
        if(!I386FindParentPath(candidate)) goto find_next;
      }
      hops=0;
      do {
        status=I386RedSeaResolve(volume,volume->root,candidate+2,&found);
        if(status==1 && I386FindAccept(&found,options)) {
          result=TRUE;
          if(entry) {
            entry->attr=found.attr;entry->clus=found.block;
            entry->size=found.size;entry->datetime=found.datetime;
            for(i=0;i<38;i++)entry->name[i]=found.name[i];
            entry->full_name=candidate;candidate=0;
          }
          goto find_release;
        }
        if(!phase || ++hops>=volume->sectors) break;
      } while(I386FindParentPath(candidate));
find_next:
      if(!I386HeapFree(heap,candidate)) {candidate=0;goto find_release;}
      candidate=0;
    }
  }
find_release:
  if(candidate && !I386HeapFree(heap,candidate)) result=FALSE;
  if(opened && !I386RedSeaEnd(volume)) result=FALSE;
  if(absolute && !I386HeapFree(heap,absolute)) result=FALSE;
  if(!I386TaskFilesRelease(state)) result=FALSE;
  if(!result && entry) {
    if(entry->full_name) I386HeapFree(heap,entry->full_name);
    for(i=0;i<sizeof(CDirEntry);i++)entry(U8 *)[i]=0;
  }
find_done:
  I386IrqRestore(saved);return result;
}
