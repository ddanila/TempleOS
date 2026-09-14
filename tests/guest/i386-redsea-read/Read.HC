Bool ReadReject(CI386RedSea *v,CI386Heap *heap,U8 *path,Bool parents=FALSE)
{
  I64 size=-1,attr=-2,used=heap->used,count=heap->allocations;
  U8 *p=I386RedSeaFileLoad(v,heap,v->root,path,&size,&attr,parents);
  if(p) { I386HeapFree(heap,p); return FALSE; }
  return size==-1 && attr==-2 && heap->used==used && heap->allocations==count && I386HeapValid(heap);
}
Bool ReadMatch(CI386RedSea *v,CI386Heap *heap,I64 directory,U8 *path,I64 kind,I64 wanted_attr,Bool parents=FALSE)
{
  U8 *p,*pattern="// Native disk include fixture.\n",*function="I64 Twice(I64 x) { return x*2; }\n";
  I64 size=-1,attr=-2,i,expected,pattern_size=FileNameLength(pattern),function_size=FileNameLength(function);
  p=I386RedSeaFileLoad(v,heap,directory,path,&size,&attr,parents);
  if(!p || attr!=wanted_attr || p[size] || I386HeapSize(heap,p)!=size+1 || heap->allocations!=1) return FALSE;
  expected=function_size;
  if(kind==1) expected=64*pattern_size+function_size;
  if(kind==2) expected=4096;
  if(kind==3) expected=0;
  if(kind==4) expected=1300;
  if(size!=expected) return FALSE;
  for(i=0;i<size;i++) {
    if(kind==0) expected=function[i];
    if(kind==1) {
      if(i<64*pattern_size) expected=pattern[i%pattern_size];
      else expected=function[i-64*pattern_size];
    }
    if(kind==2) expected=i&255;
    if(kind==4) expected=((i*19)^(i>>4))&255;
    if(p[i]!=expected) return FALSE;
  }
  return I386HeapFree(heap,p) && !heap->used && !heap->allocations && I386HeapValid(heap);
}
I64 FileLoadTest()
{
  CI386Heap heap,small;
  CI386Ata disk;
  CI386RedSea v;
  U8 *p;
  I64 i,size,attr,old_disk,old_volume;
  if(!I386HeapInit(&heap,0x50000,131072) || !I386AtaIdentify(&disk,0,0) ||
      !I386RedSeaMount(&v,&disk,2048)) return 1;
  if(!ReadMatch(&v,&heap,v.root,"/Read/Source.HC.Z",1,0xC00) ||
      !ReadMatch(&v,&heap,v.root,"/Read/Source.HC",1,0xC00) ||
      !ReadMatch(&v,&heap,2058,"Source.HC",1,0xC00)) return 2;
  if(!ReadMatch(&v,&heap,v.root,"/Read/Binary.DATA.Z",2,0xC00) ||
      !ReadMatch(&v,&heap,v.root,"/Read/Binary.DATA",2,0xC00)) return 3;
  if(!ReadMatch(&v,&heap,v.root,"/Read/Plain.HC",0,0x800) ||
      !ReadMatch(&v,&heap,v.root,"/Read/Plain.HC.Z",0,0x800) ||
      !ReadMatch(&v,&heap,v.root,"/Read/Both.HC",0,0x800) ||
      !ReadMatch(&v,&heap,v.root,"/Read/Both.HC.Z",1,0xC00)) return 4;
  if(!ReadMatch(&v,&heap,v.root,"/Read/Single.Z",0,0x800) ||
      !ReadMatch(&v,&heap,v.root,"/Read.X/Single.Z",0,0x800) ||
      !ReadMatch(&v,&heap,v.root,"/Read.X/Only.Z",0,0x800) ||
      !ReadReject(&v,&heap,"/Read/Only.Z")) return 5;
  if(!ReadMatch(&v,&heap,v.root,"/Read/Empty.HC.Z",3,0xC00) ||
      !ReadReject(&v,&heap,"/Read/Bad.HC.Z") || !ReadReject(&v,&heap,"/Read/Missing.HC") ||
      !ReadReject(&v,&heap,"/Read") || !ReadReject(&v,&heap,"") ||
      !ReadReject(&v,&heap,"C:/Read/Source.HC")) return 6;
  p=I386RedSeaFileLoad(&v,&heap,v.root,"/Read/Source.HC");
  if(!p || !I386HeapFree(&heap,p)) return 7;
  //A small arena can resolve the name but cannot retain raw, output, control and stack.
  for(i=24;i<73728;i+=4096) {
    if(!I386HeapInit(&small,0x71000,i) || !ReadReject(&v,&small,"/Read/Source.HC")) return 8;
  }
  if(!I386HeapInit(&small,0x71000,24) || !ReadReject(&v,&small,"/Read/Plain.HC")) return 9;
  old_disk=disk.sectors; old_volume=v.sectors;
  disk.sectors=32769; v.sectors=32769-v.start;
  if(!ReadReject(&v,&heap,"/IO/Outside.HC.Z")) return 12;
  disk.sectors=old_disk; v.sectors=old_volume;
  if(!ReadReject(&v,&heap,"/Read/Nested/Source.HC") ||
      !ReadMatch(&v,&heap,v.root,"/Read/Nested/Source.HC",1,0xC00,TRUE) ||
      !ReadMatch(&v,&heap,2113,"Source.HC",1,0xC00,TRUE) ||
      !ReadMatch(&v,&heap,-1,"/Read/Nested/Deep/Source.HC",1,0xC00,TRUE)) return 13;
  if(!ReadReject(&v,&heap,"/Read/Nested/Deep/Source.HC") ||
      !ReadMatch(&v,&heap,v.root,"/Read/Nested/Deep/Grand/Source.HC",1,0xC00,TRUE)) return 18;
  //The local alternate beats any ancestor, but a distant exact ancestor beats a nearer alternate.
  if(!ReadMatch(&v,&heap,v.root,"/Read/Nested/DATA.BIN",2,0xC00,TRUE) ||
      !ReadMatch(&v,&heap,v.root,"/Read/Nested/Deep/DATA.BIN",4,0x800,TRUE) ||
      !ReadMatch(&v,&heap,v.root,"/Read/Nested/Deep/Both.HC",1,0xC00,TRUE) ||
      !ReadMatch(&v,&heap,v.root,"/Read/Nested/Deep/Empty",0,0x800,TRUE)) return 14;
  if(!ReadMatch(&v,&heap,v.root,"/Read.X/Nested/Only.Z",0,0x800,TRUE) ||
      !ReadReject(&v,&heap,"/Read/Nested/Only.Z",TRUE) ||
      !ReadReject(&v,&heap,"/Read/Nested/Deep/Bad.HC.Z",TRUE) ||
      !ReadReject(&v,&heap,"/Read/Absent/Source.HC",TRUE) ||
      !ReadReject(&v,&heap,"/Read/Plain.HC/Source.HC",TRUE) ||
      !ReadReject(&v,&heap,"/Absent.HC",TRUE)) return 15;
  if(!ReadReject(&v,&heap,"/Cycle/Missing.HC",TRUE) ||
      !ReadReject(&v,&heap,"/Read/Nested/Self/Missing.HC",TRUE) ||
      !ReadReject(&v,&heap,"/Read/Nested/Orphan/Missing.HC",TRUE)) return 16;
  for(i=24;i<200;i+=8) {
    if(!I386HeapInit(&small,0x71000,i) || !ReadReject(&v,&small,"/Read/Nested/Deep/DATA.BIN",TRUE)) return 17;
  }
  i=FileContextTest(&v,&heap); if(i) return i;
  //Reject enabled interrupts before touching the ATA channel or caller output metadata.
  OutU8(0x21,255); OutU8(0xA1,255); SetRFlags(GetRFlags|0x200);
  if(!ReadReject(&v,&heap,"/Read/Source.HC.Z") || !(GetRFlags&0x200)) return 10;
  SetRFlags(GetRFlags&~0x200);
  size=-1; attr=-2;
  if(I386RedSeaFileLoad(&v,0,v.root,"/Read/Source.HC",&size,&attr) ||
      I386RedSeaFileLoad(0,&heap,v.root,"/Read/Source.HC",&size,&attr) ||
      I386RedSeaFileLoad(&v,&heap,v.root,0,&size,&attr) || size!=-1 || attr!=-2 ||
      heap.used || heap.allocations || !I386HeapValid(&heap)) return 11;
  return 0;
}
