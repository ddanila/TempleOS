#include "/Kernel/I386/TaskFileRead.HH"
#include "/Kernel/I386/Cpu.HH"
Bool I386TaskFileWrite(U8 *filename,U8 *buffer,I64 size,I64 attr=0)
{
  U32 flags=I386IrqSave;
  CI386Task *task=I386TaskSelf;
  CI386TaskFiles *state;
  CFilePathContext paths;
  CI386FileVolumes *volumes;
  CI386RedSea *volume;
  CI386RedSeaEntry parent,existing;
  U8 *absolute=0,*path,*leaf,*cursor;
  I64 drive,status;
  Bool result=FALSE;
  state=I386TaskFilesBorrow(task,&paths,&volumes);
  if(state && task->owner && size>=0 && (!size || buffer)) {
    absolute=I386FileNameAbs(state->heap,&paths,filename);
    if(absolute) {
      drive=absolute[0]; if('a'<=drive<='z') drive-=32;
      if('A'<=drive<='Z' && absolute[1]==':' && absolute[2]=='/') {
        volume=volumes->letter[drive-'A']; path=absolute+2;
        leaf=path; cursor=path;
        while(*cursor) { if(*cursor=='/') leaf=cursor+1; cursor++; }
        if(volume && volume->io && *leaf) {
          if(leaf==path+1) parent.block=volume->root;
          else {
            leaf[-1]=0;
            status=I386RedSeaResolve(volume,volume->root,path,&parent);
            leaf[-1]='/';
            if(status!=1 || !(parent.attr&0x10)) parent.block=0;
          }
          if(parent.block && I386RedSeaBegin(volume)) {
            status=I386RedSeaFind(volume,parent.block,leaf,&existing);
            if(status==1)
              status=I386RedSeaReplace(volume,parent.block,leaf,buffer,size,0);
            else if(!status)
              status=I386RedSeaCreate(volume,parent.block,leaf,buffer,size,0);
            result=status==1;
            if(!I386RedSeaEnd(volume)) result=FALSE;
          }
        }
      }
      I386HeapFree(state->heap,absolute);
    }
  }
  if(state && !I386TaskFilesRelease(state)) result=FALSE;
  I386IrqRestore(flags); return result;
}
