#include "/Kernel/I386/FileContext.HH"
#include "/Kernel/I386/Cpu.HH"
U8 *I386FileReadAt(CI386Heap *heap,CFilePathContext *paths,
  CI386FileVolumes *volumes,U8 *filename,I64 *size=0,I64 *attr=0,U8 **name=0)
{
  U8 *absolute,*result=0;
  CI386RedSea *volume;
  I64 drive,bytes,attributes;
  if(GetRFlags&0x200 || !heap || !paths || !volumes || !filename) return 0;
  absolute=I386FileNameAbs(heap,paths,filename);
  if(!absolute) return 0;
  drive=*absolute;
  if('a'<=drive<='z') drive-=32;
  if('A'<=drive<='Z' && absolute[1]==':' && absolute[2]=='/') {
    volume=volumes->letter[drive-'A'];
    if(volume) result=I386RedSeaFileLoad(volume,heap,volume->root,absolute+2,&bytes,&attributes,TRUE);
  }
  if(!result) { I386HeapFree(heap,absolute); return 0; }
  if(name) *name=absolute;
  else I386HeapFree(heap,absolute);
  if(size) *size=bytes;
  if(attr) *attr=attributes;
  return result;
}
