"""Exercise the early public swap binding at eight MiB."""
import hashlib
import json
from pathlib import Path
import runpy

out = Path(__file__).resolve().parent
source = out/'candidate.img'
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
before = sha(source)
runner = runpy.run_path('tools/i386-kernel-input.py')['run_input']
behavior = runner(source, out/'swap8', snapshot=True, ram_mib=8, cpu='486,-fpu',
                  accel='kvm', qmp_stdio=True, welcome=True, managed_pointer=True,
                  keep_window_manager=True,
                  startup_check=dict(status='ok', answers=[], pause_window_manager=False,
                    commands=[
                        ('I64 sa=-0x123456789AB,sb=0x789ABCDEFFF;', []),
                        ('SwapI64(&sa,&sb);SwapI64(&sa,&sa);', []),
                        ('sa==0x789ABCDEFFF && sb==-0x123456789AB;', ['1']),
                        ('6*7;', ['42']),
                    ]))
assert behavior['result'] == 'pass' and sha(source) == before
(out/'swap8-receipt.json').write_text(json.dumps(dict(result='pass',
    image_sha256=before, behavior=behavior), indent=2)+'\n')
