"""Exercise the Util1 template on the bundled DolDoc source files."""
from pathlib import Path
import runpy
import sys

tool = Path('tools/test-i386-demo-batch.py')
main = runpy.run_path(str(tool))['main']
fixture = main.__globals__['FIXTURE']
old = '  ExeFile(path);'
if fixture.count(old) != 1:
    raise ValueError('Unexpected demo runner fixture')
main.__globals__['FIXTURE'] = fixture.replace(old, old + r'''
  ExePrint("MyUtil(\"::/Demo/DolDoc/*.HC\");");
''')
sys.argv.extend(['--reference-at-prompt', '--demo', 'Demo/Templates/Util1.HC'])
main()
