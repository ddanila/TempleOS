"""Run Primes with an unreported cache-line width in an isolated fixture."""
from pathlib import Path
import runpy
import sys

runner = Path('tools/test-i386-demo-batch.py')
main = runpy.run_path(str(runner))['main']
main.__globals__['FIXTURE'] += '\nI64 sys_cache_line_width=0;\n'
sys.argv.extend(['--demo', 'Demo/MultiCore/Primes.HC'])
main()
