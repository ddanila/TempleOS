import runpy
import sys
from pathlib import Path

root = Path(__file__).resolve().parent
rebuild = Path('tools/test-rebuild.py').resolve()
argv = [str(rebuild), '--qmp-stdio', '--guest-timeout', '240']
sys.argv = argv
main = runpy.run_path(str(rebuild))['main']
stage = root/'bootstrap'
main.__globals__['OUT'] = stage
if not (stage/'result.json').is_file():
    main()

kernel = Path('tools/build-i386-kernel.py').resolve()
text = kernel.read_text().replace('build/rebuild-test', str(stage.relative_to(Path.cwd())))
sys.argv = [str(kernel), '--out', str(root/'native-v2'), '--disk-mib', '64',
            '--content-profile', 'full', '--compiler-qmp-stdio', '--compiler-timeout', '240']
exec(compile(text, str(kernel), 'exec'), {'__file__':str(kernel), '__name__':'__main__'})
