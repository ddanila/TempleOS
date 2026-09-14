Bool NameEqual(U8 *a,U8 *b)
{
  while(*a && *a==*b) { a++; b++; }
  return *a==*b;
}
I64 NameCase(U8 *name,U8 *extension,U8 *expected,U8 *alternate,I64 dot,Bool compressed)
{
  U8 *a=NameDefault(name,extension),*b=NameToggle(name),*p=FileExtDot(name);
  Bool ok;
  if(!a || !b) return 60;
  ok=NameEqual(a,expected) && NameEqual(b,alternate) && IsDotZ(name)==compressed;
  if(dot<0) { if(p) ok=FALSE; }
  else if(p!=name+dot) ok=FALSE;
  NameFree(a); NameFree(b);
  if(!ok) return 61;
  return 0;
}
I64 NameRulesTest()
{
  if(NameCase("","HC.Z",".HC.Z",".Z",-1,FALSE) ||
      NameCase("Test","HC.Z","Test.HC.Z","Test.Z",-1,FALSE) ||
      NameCase("Test.HC","HC.Z","Test.HC","Test.HC.Z",4,FALSE) ||
      NameCase("Test.HC.Z","HC.Z","Test.HC.Z","Test.HC",4,TRUE) ||
      NameCase("Test.Z","HC.Z","Test.Z","Test.Z.Z",4,FALSE) ||
      NameCase("Test.HC.z","HC.Z","Test.HC.z","Test.HC.z.Z",4,FALSE) ||
      NameCase(".Z","HC.Z",".Z",".Z.Z",0,FALSE) ||
      NameCase(".","HC.Z",".","..Z",0,FALSE) ||
      NameCase("..","HC.Z","..","...Z",1,FALSE) ||
      NameCase("./Test","HC.Z","./Test.HC.Z","./Test.Z",-1,FALSE) ||
      NameCase("../Test","HC.Z","../Test.HC.Z","../Test.Z",-1,FALSE) ||
      NameCase("dir.name/Test","HC.Z","dir.name/Test","dir.name/Test.Z",3,FALSE) ||
      NameCase("dir.name/Test.Z","HC.Z","dir.name/Test.Z","dir.name/Test",3,TRUE) ||
      NameCase("Test.","HC.Z","Test.","Test..Z",4,FALSE) ||
      NameCase("Test..Z","HC.Z","Test..Z","Test.",5,TRUE) ||
      NameCase("Test/","HC.Z","Test/.HC.Z","Test/.Z",-1,FALSE) ||
      NameCase("Test","","Test.","Test.Z",-1,FALSE) ||
      NameCase("Test",".HC","Test..HC","Test.Z",-1,FALSE) ||
      NameCase("C:/Test","HC.Z","C:/Test.HC.Z","C:/Test.Z",-1,FALSE) ||
      NameCase(" Test ","HC.Z"," Test .HC.Z"," Test .Z",-1,FALSE) ||
      NameCase("A.HC.Z.Z","HC.Z","A.HC.Z.Z","A.HC.Z",1,TRUE)) return 62;
  if(!IsDotC("A.B.C") || IsDotC("A.C") || IsDotC("A.B.c") ||
      !IsDotC("dir.x/A.C") || IsDotC("")) return 63;
  if(FileAttr("File.HC.Z",0x20)!=0x420 || FileAttr("File.HC",0xC20)!=0x820 ||
      FileAttr("File.HC.C",0)!=0x800 || FileAttr("File.Z",0x420)!=0x20 ||
      FileAttr("A.B.C",0x400)!=0x800) return 64;
  return 0;
}
