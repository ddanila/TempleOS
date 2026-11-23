from pathlib import Path
import sys

root = Path(__file__).resolve().parent
kernel = Path('tools/build-i386-kernel.py').resolve()
bootstrap = 'build/i386-graphics-registry-integration/bootstrap'
source = kernel.read_text().replace('build/rebuild-test', bootstrap)
sys.argv = [str(kernel), '--out', str(root/'full'), '--disk-mib', '64',
            '--content-profile', 'full', '--compiler-qmp-stdio', '--compiler-timeout', '240']
exec(compile(source, str(kernel), 'exec'), {'__file__': str(kernel), '__name__': '__main__'})
