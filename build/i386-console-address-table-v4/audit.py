"""Check the compact console export table against the original binding order."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--build-dir', type=Path, default=Path(__file__).resolve().parent)
parser.add_argument('--null-slots', action='store_true')
args = parser.parse_args()
root = args.build_dir
path = 'Kernel/I386/ConsoleRuntime.HC'
original = subprocess.check_output(['git', 'show', f'cce1d9bb:{path}']).decode()
bindings = re.findall(r'ConsoleDocExportSet\(([^)]+)\);',
                      original.split('console_doc_export_cursor=console_doc_exports;', 1)[1])
source = Path(path).read_text()
overrides = {int(i): expression for i, expression in re.findall(
    r'case (\d+): return ([^;]+);', source.split('U8 *ConsoleDocDynamicAddress(', 1)[1].split('Bool ConsoleInit(', 1)[0])}
candidate = (root/'full/exports/ConsoleRuntime.t32m').read_bytes()
count, start = struct.unpack_from('<II', candidate, 20)
records = [struct.unpack_from('<4I', candidate, start+16*i) for i in range(count)]
names = {candidate[name:name+length].decode(): offset
         for kind, offset, name, length in records if kind in (1, 3)}
table = names['console_doc_addresses']
slots = struct.unpack_from(f'<{len(bindings)}I', candidate, 32+table)
assert len(slots) == 705
aliases = {}
for file in ('Kernel/I386/MediaPathRuntime.HC', 'Kernel/I386/RawOutputRuntime.HC'):
    aliases.update(re.findall(r'^#define (\w+) (\w+)$', Path(file).read_text(), re.M))
for index, (expression, slot) in enumerate(zip(bindings, slots, strict=True)):
    if index in overrides:
        assert overrides[index] == expression and slot == (0 if args.null_slots else 0xFFFFFFFF), index
    else:
        name = expression.removeprefix('&')
        assert slot == names[aliases.get(name, name)], (index, expression)
        if args.null_slots:
            assert slot != 0, (index, expression)

baseline = Path('build/xcaliber-native-loader-v1/full/exports/ConsoleRuntime.t32m').read_bytes()
loaded = lambda data: struct.unpack_from('<I', data, 16)[0]+8
report = {'result': 'pass', 'slots': len(slots),
          'local_slots': len(slots)-len(overrides), 'dynamic_slots': len(overrides),
          'console_sha256': hashlib.sha256(candidate).hexdigest(),
          'baseline_loaded_payload_bytes': loaded(baseline),
          'candidate_loaded_payload_bytes': loaded(candidate)}
(root/'table-audit.json').write_text(json.dumps(report, indent=2)+'\n')
print(json.dumps(report))
