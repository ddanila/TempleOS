"""Exercise Util2 on writable DolDoc files across two directory levels."""
from pathlib import Path
import runpy
import sys

main = runpy.run_path('tools/test-i386-demo-batch.py')['main']
fixture = main.__globals__['FIXTURE']
old = '  ExeFile(path);'
if fixture.count(old) != 1:
    raise ValueError('Unexpected demo runner fixture')
helper = r'''
U0 PrepareUtil2Files(U8 *directory)
{
  U8 *sub=MStrPrint("%s/Sub",directory),
     *alpha=MStrPrint("%s/Alpha.DD",directory),
     *beta=MStrPrint("%s/Beta.DD",sub);
  DirMk(directory);
  DirMk(sub);
  FileWrite(alpha,"one\n\x05",5);
  FileWrite(beta,"two\nthree\n\x05",11);
  Free(alpha);Free(beta);Free(sub);
}
U0 CheckUtil2File(U8 *path,U8 *expected,I64 length)
{
  I64 bytes;
  U8 *saved=FileRead(path,&bytes);
  if(!saved || length!=bytes || MemCmp(saved,expected,length))
    throw('Util2',TRUE);
  Free(saved);
}
'''
call = r'''
  if(Drv2Let=='T')
    directory="B:/Util2Check";
  else
    directory="C:/Util2Check";
  PrepareUtil2Files(directory);
  line=MStrPrint("Print(\"Total:%%d\\n\",MyUtil(\"%s/*.DD\"));",directory);
  ExeFile(path);
  ExePrint("%s",line);
  Free(line);
  line=MStrPrint("%s/Alpha.DD",directory);
  CheckUtil2File(line,"one\n\x05",5);
  Free(line);
  line=MStrPrint("%s/Sub/Beta.DD",directory);
  CheckUtil2File(line,"two\nthree\n\x05",11);
  Free(line);
'''
fixture = fixture.replace('U8 *data,*line;', 'U8 *data,*line,*directory;')
main.__globals__['FIXTURE'] = helper + fixture.replace(old,call)
sys.argv.extend(['--reference-at-prompt','--demo','Demo/Templates/Util2.HC'])
main()
