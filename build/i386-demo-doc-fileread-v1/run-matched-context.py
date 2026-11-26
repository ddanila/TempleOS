import sys
from pathlib import Path

tool = Path('tools/test-i386-demo-batch.py').resolve()
source = tool.read_text()
anchor = '  ExeFile(path);'
assert source.count(anchor) == 1
source = source.replace(anchor, """  WinHorz(0,78);
  DefineLoad("DD_TEMPLEOS_LOC","80,849");
  Msg(MSG_KEY_DOWN,'a',0x1E);Msg(MSG_KEY_DOWN,'b',0x30);
  ExeFile(path);""")
sys.argv[0] = str(tool)
exec(compile(source, str(tool), 'exec'), {'__file__': str(tool), '__name__': '__main__'})
