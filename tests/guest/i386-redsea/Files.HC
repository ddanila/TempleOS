#include "/Kernel/I386/Ports.HH"
I64 TestFiles(CI386RedSea *v)
{
  CI386Heap heap;
  CI386RedSeaEntry entry;
  U8 *p,*q;
  I64 i,size,saved_disk,saved_volume;
  if(!I386HeapInit(&heap,0x40000,65536)) return 30;
  if(I386RedSeaResolve(v,-1,"///Tools//./../DATA.BIN",&entry)!=1 || entry.size!=1300 ||
      I386RedSeaResolve(v,2052,"../Tools/Source.HC",&entry)!=1 || entry.block!=2056 ||
      I386RedSeaResolve(v,2052,"..",&entry)!=1 || entry.size!=1024 ||
      I386RedSeaResolve(v,2052,"/",&entry)!=1 || entry.block!=v->root ||
      I386RedSeaResolve(v,v->root,"Tools///",&entry)!=1 || entry.block!=2052) return 31;
  q=&entry;
  for(i=0;i<64;i++) q[i]=0xA5;
  if(I386RedSeaResolve(v,v->root,"absent/Source.HC",&entry)!=0 ||
      I386RedSeaResolve(v,v->root,"Tools/absent",&entry)!=0 ||
      I386RedSeaResolve(v,v->root,"DATA.BIN/..",&entry)!=-1 ||
      I386RedSeaResolve(v,v->root,"DATA.BIN/",&entry)!=-1 ||
      I386RedSeaResolve(v,v->root,"",&entry)!=-1 ||
      I386RedSeaResolve(v,v->root,"C:/Tools",&entry)!=-1 ||
      I386RedSeaResolve(v,v->root,"Tools\\Source.HC",&entry)!=-1 ||
      I386RedSeaResolve(v,v->root,"12345678901234567890123456789012345678",&entry)!=-1 ||
      I386RedSeaResolve(v,-1,"Tools",&entry)!=-1 ||
      I386RedSeaResolve(0,2050,"/",&entry)!=-1) return 32;
  for(i=0;i<64;i++) if(q[i]!=0xA5) return 33;
  size=-123;
  p=I386RedSeaFileRead(v,&heap,v->root,"/DATA.BIN",&size);
  if(!p || size!=1300 || I386HeapSize(&heap,p)!=1301 || p[size]) return 34;
  for(i=0;i<size;i++) if(p[i]!=(((i*19)^(i>>4))&255)) return 35;
  if(!I386HeapFree(&heap,p)) return 36;
  p=I386RedSeaFileRead(v,&heap,2052,"Source.HC",0);
  q="I64 Twice(I64 x) { return x*2; }\n";
  if(!p) return 37;
  for(i=0;q[i];i++) if(p[i]!=q[i]) return 38;
  if(p[i] || !I386HeapFree(&heap,p)) return 39;
  p=I386RedSeaFileRead(v,&heap,v->root,"Empty",&size);
  if(!p || size || *p || I386HeapSize(&heap,p)!=1 || !I386HeapFree(&heap,p)) return 40;
  size=-123;
  if(I386RedSeaFileRead(v,&heap,v->root,"absent",&size) ||
      I386RedSeaFileRead(v,&heap,v->root,"Tools",&size) ||
      I386RedSeaReadAll(v,&heap,0,&size) || size!=-123 || heap.used || heap.allocations) return 41;
  if(I386RedSeaResolve(v,v->root,"DATA.BIN",&entry)!=1) return 42;
  for(i=32;i<1320;i+=8) {
    if(!I386HeapInit(&heap,0x40000,i)) return 43;
    p=I386RedSeaReadAll(v,&heap,&entry,&size);
    if(p || size!=-123 || heap.used || heap.allocations || !I386HeapValid(&heap)) return 44;
  }
  if(!I386HeapInit(&heap,0x40000,65536)) return 45;
  entry.size=-1;
  if(I386RedSeaReadAll(v,&heap,&entry,&size)) return 46;
  entry.size=0x100000000;
  if(I386RedSeaReadAll(v,&heap,&entry,&size)) return 47;
  saved_disk=v->disk->sectors; saved_volume=v->sectors;
  v->disk->sectors=32769; v->sectors=32769-v->start;
  entry.block=32767; entry.size=1024;
  if(I386RedSeaReadAll(v,&heap,&entry,&size)) return 48;
  entry.block=32768; entry.size=512;
  if(I386RedSeaReadAll(v,&heap,&entry,&size)) return 49;
  v->disk->sectors=saved_disk; v->sectors=saved_volume;
  if(size!=-123 || heap.used || heap.allocations || !I386HeapValid(&heap)) return 50;
  OutU8(0x21,255); OutU8(0xA1,255);
  SetRFlags(GetRFlags|0x200);
  if(I386RedSeaFileRead(v,&heap,v->root,"Empty",&size) ||
      I386RedSeaReadAll(v,&heap,&entry,&size) || !(GetRFlags&0x200) ||
      size!=-123 || heap.used || heap.allocations) return 51;
  SetRFlags(GetRFlags&~0x200);
  return 0;
}
