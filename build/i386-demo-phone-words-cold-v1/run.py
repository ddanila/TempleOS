"""Compare the phone-word demo with a queued number and an empty reply."""
from pathlib import Path
import sys

tool = Path('tools/test-i386-demo-batch.py').resolve()
source = tool.read_text()
source = source.replace('if original != native:', 'if Path(path).read_bytes() != native:')
anchor = '  ExeFile(path);'
assert source.count(anchor) == 1
source = source.replace(anchor, """  Msg(MSG_KEY_DOWN,'4',0x05);
  Msg(MSG_KEY_DOWN,'3',0x04);
  Msg(MSG_KEY_DOWN,'5',0x06);
  Msg(MSG_KEY_DOWN,'-',0x0C);
  Msg(MSG_KEY_DOWN,'5',0x06);
  Msg(MSG_KEY_DOWN,'6',0x07);
  Msg(MSG_KEY_DOWN,'\\n',0x1C);
  Msg(MSG_KEY_DOWN,'\\n',0x1C);
  ExeFile(path);""")
anchor = "        (overlay/'Once.HC').write_bytes(body)"
assert source.count(anchor) == 1
source = source.replace(anchor, """        archive = ROOT/'build/i386-autocomplete-archive-original/guest/ACWords.DATA.Z'
        (overlay/'Adam/AutoComplete/ACWords.DATA.Z').write_bytes(archive.read_bytes())
        (overlay/'Once.HC').write_bytes(
            b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\\nAdam("ACInit;");\\n'+body)""")
sys.argv[0] = str(tool)
exec(compile(source,str(tool),'exec'),{'__file__':str(tool),'__name__':'__main__'})
