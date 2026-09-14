//Expected results captured against original x64 path functions before extraction.
I64 PathCase(U8 *name,U8 *directory,U8 *file,I64 number)
{
  U8 *a=PathDir(name),*b=PathFile(name);
  Bool ok=a && b && NameEqual(a,directory) && NameEqual(b,file);
  NameFree(a); NameFree(b);
  if(!ok) return number;
  return 0;
}
I64 PathRulesTest()
{
  I64 result;
  U8 control[8];
  result=PathCase("","T:/Work/Here","T:/Work/Here/",100); if(result) return result;
  result=PathCase("a","T:/Work/Here/a","T:/Work/Here/a",101); if(result) return result;
  result=PathCase(".","T:/Work/Here","T:/Work/Here/.",102); if(result) return result;
  result=PathCase("..","T:/Work","T:/Work/Here/..",103); if(result) return result;
  result=PathCase("../","T:/Work","T:/Work/",104); if(result) return result;
  result=PathCase("../../..","T:/","T:/..",105); if(result) return result;
  result=PathCase("/","T:/","T:/",106); if(result) return result;
  result=PathCase("//","T:/","T:/",107); if(result) return result;
  result=PathCase("/a/..","T:/","T:/a/..",108); if(result) return result;
  result=PathCase("a//b","T:/b","T:/Work/Here/a/b",109); if(result) return result;
  result=PathCase("a///b","T:/b","T:/b",110); if(result) return result;
  result=PathCase("a//","T:/","T:/Work/Here/a/",111); if(result) return result;
  result=PathCase("a///","T:/","T:/",112); if(result) return result;
  result=PathCase("~","H:/Users/Test","T:/Work/Here/~",113); if(result) return result;
  result=PathCase("~/a","H:/Users/Test/a","H:/Users/Test/a",114); if(result) return result;
  result=PathCase("a/~/b","H:/Users/Test/b","H:/Users/Test/b",115); if(result) return result;
  result=PathCase("~/../a","H:/Users/a","H:/Users/a",116); if(result) return result;
  result=PathCase("~:a","H:/a","H:/a",117); if(result) return result;
  result=PathCase("~:","H:/","H:/",118); if(result) return result;
  result=PathCase("::a","B:/a","B:/a",119); if(result) return result;
  result=PathCase("::/a","B:/a","B:/a",120); if(result) return result;
  result=PathCase("c:a","c:/a","c:/a",121); if(result) return result;
  result=PathCase("c:","c:/","c:/",122); if(result) return result;
  result=PathCase("c:/a/../b","c:/b","c:/b",123); if(result) return result;
  result=PathCase("c:/~","H:/Users/Test","c:/~",124); if(result) return result;
  result=PathCase("c:/~/b","H:/Users/Test/b","H:/Users/Test/b",125); if(result) return result;
  result=PathCase(" a ","T:/Work/Here/a","T:/Work/Here/a",126); if(result) return result;
  result=PathCase("a /b","T:/Work/Here/a /b","T:/Work/Here/a/b",127); if(result) return result;
  result=PathCase("a/ b","T:/Work/Here/a/ b","T:/Work/Here/a/ b",128); if(result) return result;
  result=PathCase("a\\b","T:/Work/Here/a\\b","T:/Work/Here/a\\b",129); if(result) return result;
  result=PathCase("...","T:/Work/Here/...","T:/Work/Here/...",130); if(result) return result;
  result=PathCase(":","T:/Work/Here/:","T:/Work/Here/:",131); if(result) return result;
  result=PathCase("a:~","H:/Users/Test","a:/~",132); if(result) return result;
  result=PathCase("a/b/","T:/Work/Here/a/b","T:/Work/Here/a/b/",133); if(result) return result;
  control[0]=9; control[1]='a'; control[2]=1; control[3]='b'; control[4]=13; control[5]=0;
  result=PathCase(control,"T:/Work/Here/ab","T:/Work/Here/ab",134); if(result) return result;
  control[0]='a'; control[1]=9; control[2]='b'; control[3]=0;
  result=PathCase(control,"T:/Work/Here/a\tb","T:/Work/Here/a\tb",135); if(result) return result;
  control[0]=1; control[1]=' '; control[2]=0;
  result=PathCase(control,"T:/Work/Here/ ","T:/Work/Here/ ",136); if(result) return result;
  control[0]=31; control[1]='a'; control[2]=31; control[3]=0;
  result=PathCase(control,"T:/Work/Here/a","T:/Work/Here/a",137); if(result) return result;
  control[0]='a'; control[1]=127; control[2]=255; control[3]=0;
  //High bytes remain ordinary filename bytes.
  { U8 expected[32]; I64 j;
    for(j=0;j<13;j++) expected[j]="T:/Work/Here/"(U8 *)[j];
    expected[13]='a'; expected[14]=127; expected[15]=255; expected[16]=0;
    result=PathCase(control,expected,expected,138); if(result) return result;
  }
  return 0;
}
I64 PathContextTest()
{
  I64 result;
  U8 *a;
  PathContextSet("/","H:/");
  result=PathCase("~/a","H:/a","H:/a",139); if(result) return result;
  PathContextSet("/Work/Here/","H:/Users/Test/");
  result=PathCase("a","T:/Work/Here//a","T:/Work/Here/a",140); if(result) return result;
  result=PathCase("~/a","H:/Users/Test//a","H:/Users/Test/a",141); if(result) return result;
  PathContextSet(0,"H:/");
  a=PathDir("  a/../b  ");
  if(!a || !NameEqual(a,"  a/../b  ")) return 142;
  NameFree(a);
  PathContextSet("","H:/");
  a=PathDir("::/../a");
  if(!a || !NameEqual(a,"::/../a")) return 143;
  NameFree(a);
  PathContextSet("/Work/Here","H:/Users/Test");
  return 0;
}
//Newly defined literal-percent behavior; not part of the original-formatting oracle.
I64 PathLiteralTest()
{
  return PathCase("a%s/b%","T:/Work/Here/a%s/b%","T:/Work/Here/a%s/b%",159);
}
