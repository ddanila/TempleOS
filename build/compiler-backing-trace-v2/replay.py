"""Replay backing ownership events up to the native startup marker."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parent
raw = (root / 'user8/qemu/debug.log').read_bytes()
active = {}
choice = None
for line_number, line in enumerate(raw.decode().splitlines(), 1):
    if line == 'DONE native kernel startup':
        assert choice is None
        break
    if not line.startswith('BACKING '):
        continue
    _, event, *fields = line.split()
    values = [int(field, 16) for field in fields]
    if event == 'CHOICE':
        assert choice is None
        arena, size, request, retained = values
        choice = dict(line=line_number, arena=arena, size=size,
                      request=request, retained=retained, fits=[])
    elif event == 'FIT':
        choice['fits'].append(values)
    elif event == 'LIMIT':
        largest, count = values
        assert count == len(choice['fits'])
        assert largest == max(span for _, span in choice['fits'])
    elif event == 'PICK':
        address, = values
        assert address not in active
        assert any(start <= address < start+span for start, span in choice['fits'])
        active[address] = choice
        choice = None
    elif event == 'RELEASE':
        address, = values
        del active[address]
else:
    raise ValueError('Missing native startup marker')

receipt = (root / 'user8/result.json').read_bytes()
result = json.loads(receipt)
assert result['result'] == 'fail' and result['ram_mib'] == 8 and result['inputs_unchanged']
assert b'HEAP EXHAUSTED 0000000000041507' in raw
print(json.dumps(dict(log_sha256=hashlib.sha256(raw).hexdigest(),
                      receipt_sha256=hashlib.sha256(receipt).hexdigest(),
                      live_at_startup={hex(a): record for a, record in active.items()}),
                 indent=2))
