"""Check MemDemo's valid architecture-specific bucket labels."""
from pathlib import Path
import sys

tool = Path('tools/test-i386-demo-batch.py').resolve()
source = tool.read_text()
source = source.replace('if original != native:',
    'if Path(path).read_bytes() != native:')
source = source.replace('                matches = original == native',
    '''                expected = re.sub(rb'(heap_hash\\[[0-9A-F]+)/8\\]', rb'\\1/4]', original)
                matches = expected == native''')
source = source.replace('import runpy\n','import runpy\nimport re\n')
sys.argv[0] = str(tool)
exec(compile(source,str(tool),'exec'),{'__file__':str(tool),'__name__':'__main__'})
