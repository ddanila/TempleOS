"""Compare the bundled spelling demo with a queued word and an empty reply."""
from pathlib import Path
import sys

tool = Path('tools/test-i386-demo-batch.py').resolve()
source = tool.read_text()
launch = '  ExeFile(path);'
assert source.count(launch) == 1
source = source.replace(launch, r"""  Msg(MSG_KEY_DOWN,'x',0x2D);
  Msg(MSG_KEY_DOWN,'y',0x15);
  Msg(MSG_KEY_DOWN,'l',0x26);
  Msg(MSG_KEY_DOWN,'o',0x18);
  Msg(MSG_KEY_DOWN,'p',0x19);
  Msg(MSG_KEY_DOWN,'h',0x23);
  Msg(MSG_KEY_DOWN,'o',0x18);
  Msg(MSG_KEY_DOWN,'n',0x31);
  Msg(MSG_KEY_DOWN,'e',0x12);
  Msg(MSG_KEY_DOWN,'\n',0x1C);
  Msg(MSG_KEY_DOWN,'\n',0x1C);
  ExeFile(path);""")
original_once = "        (overlay/'Once.HC').write_bytes(body)"
assert source.count(original_once) == 1
source = source.replace(original_once, """        archive = ROOT/'build/i386-autocomplete-archive-original/guest/ACWords.DATA.Z'
        (overlay/'Adam/AutoComplete/ACWords.DATA.Z').write_bytes(archive.read_bytes())
        (overlay/'Once.HC').write_bytes(
            b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\nAdam("ACInit;");\n'+body)""".replace(
                'Yield;\nAdam("ACInit;");\n', 'Yield;\\nAdam("ACInit;");\\n'))
sys.argv[0] = str(tool)
exec(compile(source, str(tool), 'exec'), {'__file__': str(tool), '__name__': '__main__'})
