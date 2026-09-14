Bool ContextIncludeCall(CI386Heap *heap,CCmpCtrl *cc,CFilePathContext *paths,
  CI386FileVolumes *volumes,U8 *filename)
{
  CI386LexFileContext files; CI386LexIncludeService service;
  files.paths=paths; files.volumes=volumes;
  service.context=&files; service.push=&I386LexFileInclude;
  return (*service.push)(service.context,heap,cc,filename);
}
Bool ContextEqual(U8 *a,U8 *b)
{
  while(*a && *a==*b) { a++; b++; }
  return *a==*b;
}
Bool ContextMatch(CI386Heap *heap,CFilePathContext *paths,CI386FileVolumes *volumes,
  U8 *filename,U8 *absolute,I64 kind,I64 expected_attr)
{
  U8 *name=0,*data,*expected="I64 Twice(I64 x) { return x*2; }\n",*pattern="// Native disk include fixture.\n";
  I64 size=-1,attr=-2,i,wanted,length;
  if(kind==2) expected="I64 OtherDrive() { return 32; }\n";
  length=FileNameLength(expected);
  if(kind==1) length+=64*FileNameLength(pattern);
  if(kind==3) length=0;
  data=I386FileReadAt(heap,paths,volumes,filename,&size,&attr,&name);
  if(!data || !name || !ContextEqual(name,absolute) || size!=length || attr!=expected_attr ||
      data[size] || I386HeapSize(heap,data)!=size+1 || heap->allocations!=2) return FALSE;
  for(i=0;i<size;i++) {
    wanted=0;
    if(kind==1) {
      if(i<64*FileNameLength(pattern)) wanted=pattern[i%FileNameLength(pattern)];
      else wanted=expected[i-64*FileNameLength(pattern)];
    }
    else wanted=expected[i];
    if(data[i]!=wanted) return FALSE;
  }
  return I386HeapFree(heap,name) && I386HeapFree(heap,data) &&
    !heap->used && !heap->allocations && I386HeapValid(heap);
}
Bool ContextReject(CI386Heap *heap,CFilePathContext *paths,CI386FileVolumes *volumes,U8 *filename)
{
  I64 size=-1,attr=-2,used=heap->used,count=heap->allocations;
  U8 *name=0x1234,*data=I386FileReadAt(heap,paths,volumes,filename,&size,&attr,&name);
  if(data) { I386HeapFree(heap,data); return FALSE; }
  return size==-1 && attr==-2 && name==0x1234 && heap->used==used &&
    heap->allocations==count && I386HeapValid(heap);
}
Bool ContextRoot(CI386Heap *heap,CCmpCtrl *cc)
{
  U8 *bytes=cc;
  I64 i;
  CLexFile *root;
  for(i=0;i<sizeof(CCmpCtrl);i++) bytes[i]=0;
  CmpCtrlSeed(cc,CCF_DONT_FREE_BUF,0,char_bmp_alpha_numeric);
  root=I386LexFilePush(heap,cc);
  if(!root) return FALSE;
  LexFileSeed(root,"R"); cc->cur_buf_ptr=root->buf;
  return TRUE;
}
I64 ContextIncludeTest(CI386Heap *heap,CFilePathContext *paths,CI386FileVolumes *volumes)
{
  CCmpCtrl cc;
  CLexFile *root,*outer;
  U8 snapshot[sizeof(CCmpCtrl)],*bytes=&cc,*outer_text="I64 OtherDrive() { return 32; }\n";
  U8 *pattern="// Native disk include fixture.\n",*function="I64 Twice(I64 x) { return x*2; }\n",*old_dir;
  I64 i,lines=0,used,count,expected,length;
  if(!ContextRoot(heap,&cc)) return 40;
  root=cc.lex_include_stk; used=heap->used; count=heap->allocations;
  if(I386LexRawChar(heap,&cc,&lines)!='R') return 41;
  cc.flags|=CCF_USE_LAST_U16;
  if(!ContextIncludeCall(heap,&cc,paths,volumes,"D:/Source") ||
      !ContextEqual(cc.lex_include_stk->full_name,"D:/Source.HC.Z") ||
      cc.lex_include_stk->next!=root || cc.lex_include_stk->flags&LFSF_DEFINE) return 42;
  outer=cc.lex_include_stk;
  if(I386LexRawChar(heap,&cc,&lines)!='I') return 43;
  cc.flags|=CCF_USE_LAST_U16;
  if(!ContextIncludeCall(heap,&cc,paths,volumes,"Source") ||
      !ContextEqual(cc.lex_include_stk->full_name,"C:/Read/Source.HC.Z") ||
      cc.lex_include_stk->next!=outer || heap->allocations!=count+6) return 44;
  length=64*FileNameLength(pattern)+FileNameLength(function);
  for(i=0;i<length;i++) {
    if(i<64*FileNameLength(pattern)) expected=pattern[i%FileNameLength(pattern)];
    else expected=function[i-64*FileNameLength(pattern)];
    if(I386LexRawChar(heap,&cc,&lines)!=expected) return 45;
  }
  for(i=0;outer_text[i];i++) if(I386LexRawChar(heap,&cc,&lines)!=outer_text[i]) return 46;
  if(I386LexRawChar(heap,&cc,&lines)!='R' || cc.lex_include_stk!=root ||
      heap->used!=used || heap->allocations!=count || lines!=66) return 47;
  if(I386LexRawChar(heap,&cc,&lines)!=TK_EOF) return 48;
  for(i=0;i<sizeof(CCmpCtrl);i++) snapshot[i]=bytes[i];
  if(ContextIncludeCall(heap,&cc,paths,volumes,"Missing") ||
      ContextIncludeCall(heap,&cc,paths,volumes,"Bad.HC.Z") ||
      ContextIncludeCall(heap,&cc,paths,volumes,"E:/Source") ||
      ContextIncludeCall(heap,&cc,paths,volumes,"C:/IO/Outside.HC.Z") ||
      ContextIncludeCall(heap,&cc,paths,volumes,0)) return 49;
  for(i=0;i<sizeof(CCmpCtrl);i++) if(snapshot[i]!=bytes[i]) return 50;
  if(heap->used!=used || heap->allocations!=count || !I386HeapValid(heap)) return 51;
  if(!ContextIncludeCall(heap,&cc,paths,volumes,"Empty") ||
      I386LexRawChar(heap,&cc,&lines)!=TK_EOF || cc.lex_include_stk!=root || heap->used!=used) return 52;
  //Compiler names are normalized once before FileRead performs its own normalization.
  old_dir=paths->cur_dir; paths->cur_dir="/Missing/";
  if(!ContextReject(heap,paths,volumes,"Tools/Source.HC") ||
      !ContextIncludeCall(heap,&cc,paths,volumes,"Tools/Source") ||
      !ContextEqual(cc.lex_include_stk->full_name,"C:/Missing//Tools/Source.HC.Z")) return 60;
  paths->cur_dir=old_dir;
  for(i=0;function[i];i++) if(I386LexRawChar(heap,&cc,&lines)!=function[i]) return 61;
  if(I386LexRawChar(heap,&cc,&lines)!=TK_EOF || cc.lex_include_stk!=root ||
      heap->used!=used || heap->allocations!=count) return 62;
  if(!I386LexFilePop(heap,&cc) || heap->used || heap->allocations || !I386HeapValid(heap)) return 53;
  return 0;
}
I64 ContextIncludeFailure(CFilePathContext *paths,CI386FileVolumes *volumes)
{
  CI386Heap heap;
  CCmpCtrl cc;
  U8 snapshot[sizeof(CCmpCtrl)],*bytes=&cc;
  I64 size,i,used,count,failures=0,successes=0;
  Bool attached;
  for(size=112;size<800;size+=8) {
    if(!I386HeapInit(&heap,0x71000,size) || !ContextRoot(&heap,&cc)) return 54;
    used=heap.used; count=heap.allocations;
    for(i=0;i<sizeof(CCmpCtrl);i++) snapshot[i]=bytes[i];
    attached=ContextIncludeCall(&heap,&cc,paths,volumes,"D:/Source");
    if(attached) {
      successes++;
      if(!ContextEqual(cc.lex_include_stk->full_name,"D:/Source.HC.Z") ||
          !ContextEqual(cc.lex_include_stk->buf,"I64 OtherDrive() { return 32; }\n") ||
          !I386LexFilePop(&heap,&cc)) return 55;
      cc.cur_buf_ptr=cc.lex_include_stk->buf_ptr;
    } else {
      failures++;
      for(i=0;i<sizeof(CCmpCtrl);i++) if(snapshot[i]!=bytes[i]) return 56;
    }
    if(heap.used!=used || heap.allocations!=count || !I386HeapValid(&heap) || GetRFlags&0x200) return 57;
    if(!I386LexFilePop(&heap,&cc) || heap.used || heap.allocations || !I386HeapValid(&heap)) return 58;
  }
  if(!failures || !successes) return 59;
  return 0;
}
I64 FileContextTest(CI386RedSea *first,CI386Heap *heap)
{
  CI386RedSea second;
  CI386FileVolumes volumes;
  CFilePathContext paths,other;
  CCmpCtrl cc;
  U8 *data,*name=0x1234,snapshot[sizeof(CCmpCtrl)],*bytes=&cc;
  I64 i,result,size=-1,attr=-2,used,count,old_disk,old_volume;
  if(!I386RedSeaMount(&second,first->disk,3078)) return 20;
  for(i=0;i<26;i++) volumes.letter[i]=0;
  volumes.letter['C'-'A']=first; volumes.letter['D'-'A']=&second;
  paths.cur_dir="/Read"; paths.home_dir="D:/";
  paths.cur_drv='C'; paths.boot_drv='C'; paths.white_space=char_bmp_white_space;
  other.cur_dir="/"; other.home_dir="C:/Tools";
  other.cur_drv='D'; other.boot_drv='D'; other.white_space=char_bmp_white_space;
  if(!ContextMatch(heap,&paths,&volumes,"Source.HC","C:/Read/Source.HC",1,0xC00) ||
      !ContextMatch(heap,&other,&volumes,"Source.HC.Z","D:/Source.HC.Z",2,0x800) ||
      !ContextMatch(heap,&paths,&volumes,"~/Source.HC","D:/Source.HC",2,0x800) ||
      !ContextMatch(heap,&other,&volumes,"~/Source.HC","C:/Tools/Source.HC",0,0x800)) return 21;
  if(!ContextMatch(heap,&paths,&volumes,"::/Tools/Source.HC","C:/Tools/Source.HC",0,0x800) ||
      !ContextMatch(heap,&other,&volumes,"::/Source.HC","D:/Source.HC",2,0x800) ||
      !ContextMatch(heap,&paths,&volumes,"c:/Read/../Tools/Source.HC","c:/Tools/Source.HC",0,0x800) ||
      !ContextMatch(heap,&paths,&volumes,"d:Source.HC","d:/Source.HC",2,0x800)) return 22;
  if(!ContextMatch(heap,&paths,&volumes,"Nested/Deep/Source.HC","C:/Read/Nested/Deep/Source.HC",1,0xC00) ||
      !ContextMatch(heap,&paths,&volumes,"Empty.HC","C:/Read/Empty.HC",3,0xC00)) return 23;
  if(!ContextReject(heap,&paths,&volumes,"Source") ||
      !ContextReject(heap,&paths,&volumes,"E:/Source.HC") ||
      !ContextReject(heap,&paths,&volumes,"5:/Read/Source.HC") ||
      !ContextReject(heap,&paths,&volumes,"D:/Read/Source.HC") ||
      !ContextReject(heap,&paths,&volumes,"Bad.HC.Z") ||
      !ContextReject(heap,0,&volumes,"Source.HC") ||
      !ContextReject(heap,&paths,0,"Source.HC") ||
      !ContextReject(heap,&paths,&volumes,0)) return 24;
  if(I386FileReadAt(0,&paths,&volumes,"Source.HC",&size,&attr,&name) ||
      size!=-1 || attr!=-2 || name!=0x1234) return 25;
  data=I386FileReadAt(heap,&other,&volumes,"Source.HC");
  if(!data || heap->allocations!=1 || !ContextEqual(data,"I64 OtherDrive() { return 32; }\n") ||
      !I386HeapFree(heap,data)) return 26;
  //Force a real partial ATA read through both the routed reader and include bridge.
  old_disk=first->disk->sectors; old_volume=first->sectors;
  first->disk->sectors=32769; first->sectors=32769-first->start;
  if(!ContextReject(heap,&paths,&volumes,"C:/IO/Outside.HC.Z")) return 32;
  result=ContextIncludeTest(heap,&paths,&volumes);
  first->disk->sectors=old_disk; first->sectors=old_volume;
  if(result) return result;
  result=ContextIncludeFailure(&paths,&volumes); if(result) return result;
  if(!ContextEqual(paths.cur_dir,"/Read") || !ContextEqual(other.cur_dir,"/") ||
      paths.cur_drv!='C' || other.cur_drv!='D' || heap->used || heap->allocations) return 27;
  if(!ContextRoot(heap,&cc)) return 28;
  used=heap->used; count=heap->allocations;
  for(i=0;i<sizeof(CCmpCtrl);i++) snapshot[i]=bytes[i];
  OutU8(0x21,255); OutU8(0xA1,255); SetRFlags(GetRFlags|0x200);
  if(!ContextReject(heap,&paths,&volumes,"Source.HC") ||
      ContextIncludeCall(heap,&cc,&paths,&volumes,"Source") || !(GetRFlags&0x200)) return 29;
  SetRFlags(GetRFlags&~0x200);
  for(i=0;i<sizeof(CCmpCtrl);i++) if(snapshot[i]!=bytes[i]) return 30;
  if(heap->used!=used || heap->allocations!=count || !I386LexFilePop(heap,&cc) ||
      heap->used || heap->allocations || !I386HeapValid(heap)) return 31;
  return 0;
}
