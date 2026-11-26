"""Check the unmodified Primes workflow on the image with the public cache binding."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('batch', type=Path)
args = parser.parse_args()
reference_dir = Path('build/i386-demo-primes-v1')
observe = runpy.run_path(str(reference_dir / 'compare.py'))['observe']
reference = json.loads((reference_dir / 'original-receipt.json').read_text())
raw = (args.batch / 'result.json').read_bytes()
report = json.loads(raw)
if not report['inputs_unchanged'] or 'error' in report:
    raise ValueError('The unchanged demo did not complete')
entry = report['entries']['Demo/MultiCore/Primes.HC']
if entry['source_sha256'] != reference['source_sha256']:
    raise ValueError('Demo source differs from the pinned reference')
runs = {mode: observe((args.batch / mode / entry['output_file']).read_bytes())
        for mode in ('original', 'native')}
for mode, observed in runs.items():
    if observed['sha256'] != entry[mode + '_sha256']:
        raise ValueError(f'{mode} document differs from batch receipt')
print(json.dumps({'result': 'pass', 'image_sha256': report['input_sha256'],
                  'source_sha256': entry['source_sha256'],
                  'batch_receipt_sha256': hashlib.sha256(raw).hexdigest(),
                  'scope': 'All four unchanged Primes reports match the independent sieve; elapsed times vary.',
                  'runs': runs}, indent=2))
