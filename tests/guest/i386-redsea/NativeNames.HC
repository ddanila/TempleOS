CI386Heap name_heap;
I64 name_errors;
U8 *NameDefault(U8 *name,U8 *extension) { return I386ExtDft(&name_heap,name,extension); }
U8 *NameToggle(U8 *name) { return I386ToggleZorNotZ(&name_heap,name); }
U0 NameFree(U8 *name) { if(!I386HeapFree(&name_heap,name)) name_errors++; }
#include "T:/Names.HC"
CFilePathContext path_context;
U8 *PathDir(U8 *name) { return I386DirNameAbs(&name_heap,&path_context,name); }
U8 *PathFile(U8 *name) { return I386FileNameAbs(&name_heap,&path_context,name); }
U0 PathContextSet(U8 *directory,U8 *home) { path_context.cur_dir=directory; path_context.home_dir=home; }
#include "T:/Paths.HC"
I64 TestNames()
{
  U8 *a,*b,source[258];
  I64 result,i,size,dir_fail=0,file_fail=0,dir_pass=0,file_pass=0;
  U32 flags=I386IrqSave;
  if(!I386HeapInit(&name_heap,0x40000,65536)) return 64;
  result=NameRulesTest; if(result) return result;
  PathContextSet("/Work/Here","H:/Users/Test");
  path_context.cur_drv='T'; path_context.boot_drv='B'; path_context.white_space=char_bmp_white_space;
  result=PathRulesTest; if(result) return result;
  result=PathContextTest; if(result) return result;
  result=PathLiteralTest; if(result) return result;
  if(name_errors || name_heap.used || name_heap.allocations || !I386HeapValid(&name_heap)) return 65;
  if(I386ExtDft(&name_heap,0,"HC.Z") || I386ExtDft(&name_heap,"a",0) ||
      I386ExtDft(0,"a","HC.Z") || I386ToggleZorNotZ(&name_heap,0) ||
      I386ToggleZorNotZ(0,"a")) return 66;
  for(i=0;i<257;i++) source[i]='a';
  source[257]=0;
  for(size=24;size<280;size+=8) {
    if(!I386HeapInit(&name_heap,0x40000,size) ||
        NameDefault(source,"HC.Z") || NameToggle(source) || name_heap.used ||
        name_heap.allocations || !I386HeapValid(&name_heap) || GetRFlags&0x200) return 67;
    for(i=0;i<257;i++) if(source[i]!='a') return 68;
    if(source[257]) return 69;
  }
  if(I386DirNameAbs(0,&path_context,"a") || I386DirNameAbs(&name_heap,0,"a") ||
      I386FileNameAbs(&name_heap,&path_context,0)) return 144;
  path_context.home_dir=0;
  if(PathDir("a") || PathFile("a")) return 145;
  path_context.home_dir="H:";
  if(PathDir("a") || PathFile("a")) return 146;
  path_context.home_dir="H:/Users/Test"; path_context.white_space=0;
  if(PathDir("a") || PathFile("a")) return 147;
  path_context.white_space=char_bmp_white_space;
  for(size=24;size<864;size+=8) {
    if(!I386HeapInit(&name_heap,0x40000,size)) return 148;
    a=PathDir(source);
    if(a) {
      dir_pass++;
      if(FileNameLength(a)!=270 || !NameEqual(a+13,source)) return 149;
      for(i=0;i<13;i++) if(a[i]!="T:/Work/Here/"(U8 *)[i]) return 150;
      NameFree(a);
    } else dir_fail++;
    b=PathFile(source);
    if(b) {
      file_pass++;
      if(FileNameLength(b)!=270 || !NameEqual(b+13,source)) return 151;
      for(i=0;i<13;i++) if(b[i]!="T:/Work/Here/"(U8 *)[i]) return 152;
      NameFree(b);
    } else file_fail++;
    if(name_errors || name_heap.used || name_heap.allocations ||
        !I386HeapValid(&name_heap) || GetRFlags&0x200) return 153;
    for(i=0;i<257;i++) if(source[i]!='a') return 154;
    if(source[257]) return 155;
  }
  if(!dir_fail || !file_fail || !dir_pass || !file_pass) return 156;
  if(!I386HeapInit(&name_heap,0x40000,65536)) return 70;
  OutU8(0x21,255); OutU8(0xA1,255); SetRFlags(GetRFlags|0x200);
  a=NameDefault("child","HC.Z"); b=NameToggle("child.HC.Z");
  if(!a || !b || I386HeapSize(&name_heap,a)!=11 || I386HeapSize(&name_heap,b)!=9 ||
      !NameEqual(a,"child.HC.Z") || !NameEqual(b,"child.HC") || !(GetRFlags&0x200)) return 71;
  NameFree(a); NameFree(b);
  if(name_errors || name_heap.used || name_heap.allocations || !(GetRFlags&0x200)) return 72;
  a=PathDir("a//b"); b=PathFile("a//b");
  if(!a || !b || !NameEqual(a,"T:/b") || !NameEqual(b,"T:/Work/Here/a/b") ||
      !(GetRFlags&0x200) || name_heap.allocations!=2) return 157;
  NameFree(a); NameFree(b);
  if(name_errors || name_heap.used || name_heap.allocations ||
      !I386HeapValid(&name_heap) || !(GetRFlags&0x200)) return 158;
  I386IrqRestore(flags); return 0;
}
