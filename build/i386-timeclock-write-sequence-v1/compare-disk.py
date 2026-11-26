"""Compare attributes and payloads of passing and failing TimeClock writes."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('report_disk', type=Path)
parser.add_argument('direct_disk', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
snapshot = runpy.run_path(str(root / 'tools/package-i386-native-image.py'))['snapshot']
path = '/Home/TimeClock/TimeFile.DATA.Z'
read_back = {}
for stage, disk in [('report', args.report_disk), ('direct', args.direct_disk)]:
    _, files, _ = snapshot(disk.read_bytes())
    read_back[stage] = files[path]
report_attr, _, report_data = read_back['report']
direct_attr, _, direct_data = read_back['direct']
if report_attr != direct_attr or report_data != direct_data:
    raise ValueError('Application and direct writes produced different archives')
print(json.dumps({
    'result': 'match',
    'path': path,
    'redsea_attributes': hex(report_attr),
    'archive_bytes': len(report_data),
    'archive_sha256': hashlib.sha256(report_data).hexdigest(),
}, indent=2))
