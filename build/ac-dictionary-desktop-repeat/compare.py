"""Compare qualified configured desktop runs on the dictionary image pair."""
import argparse
import hashlib
import json
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('baseline', type=Path)
parser.add_argument('direct_copy', type=Path)
args = parser.parse_args()


def verified(path):
    raw = path.read_bytes()
    result = json.loads(raw)
    if (result['result'] != 'pass' or not result['inputs_unchanged']
            or result['once_selected'] != ['HOME']
            or not result['bootstrap_retired']
            or result['physical']['result'] != 'pass'):
        raise ValueError(f'Incomplete desktop qualification in {path}')
    return result, hashlib.sha256(raw).hexdigest()


baseline, baseline_sha = verified(args.baseline)
optimized, optimized_sha = verified(args.direct_copy)
for key in ('ram_mib', 'cpu', 'accel', 'geometry', 'scope'):
    if baseline[key] != optimized[key]:
        raise ValueError(f'Desktop runs differ in {key}')
shared_pins = baseline['input_sha256'].keys() & optimized['input_sha256'].keys()
if (len(shared_pins) != len(baseline['input_sha256']) - 1
        or len(shared_pins) != len(optimized['input_sha256']) - 1
        or any(baseline['input_sha256'][p] != optimized['input_sha256'][p]
               for p in shared_pins)):
    raise ValueError('Expected identical oracle inputs and distinct candidate images')
before = baseline['observed_startup_seconds']
after = optimized['observed_startup_seconds']
print(json.dumps(dict(baseline_receipt_sha256=baseline_sha,
                      direct_copy_receipt_sha256=optimized_sha,
                      baseline_seconds=before,
                      direct_copy_seconds=after,
                      observed_difference_seconds=before-after), indent=2))
