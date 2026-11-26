import sys
from pathlib import Path

tool = Path('tools/test-i386-doc-bible-link.py').resolve()
source = tool.read_text()
call = 'command_timeout=1200)'
assert source.count(call) == 1
code = compile(source.replace(call, "command_timeout=1200, accel='kvm')"), str(tool), 'exec')
sys.argv[0] = str(tool)
exec(code, {'__file__': str(tool), '__name__': '__main__'})
