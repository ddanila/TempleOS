"""Check that serialization preserves DefineStr widgets and their expanded values."""
from datetime import datetime
import hashlib
import json
from pathlib import Path
import re

BATCH = Path(__file__).resolve().parent / 'comparison'


def observe(data):
    match = re.fullmatch(
        rb'Company: \$TX,"Acme Inc",D="COMPANY"\$\n'
        rb'Age : \$TX,"(\d+\.\d)",D="COMPANY_AGE"\$ years\n'
        rb'Time: \$TX,"(\d\d:\d\d:\d\d)",D="COMPANY_TIME"\$\n\x05', data)
    if not match:
        raise ValueError(f'Unexpected saved widget fields: {data!r}')
    age, time = [value.decode('ascii') for value in match.groups()]
    datetime.strptime(time, '%H:%M:%S')
    return {'company': 'Acme Inc', 'age_years': age, 'time': time,
            'sha256': hashlib.sha256(data).hexdigest()}


def main():
    raw = (BATCH/'result.json').read_bytes()
    batch = json.loads(raw)
    if not batch['inputs_unchanged'] or 'error' in batch:
        raise ValueError('The native workflow did not complete')
    entry = batch['entries']['Demo/DolDoc/DefineStr.HC']
    runs = {n: observe((BATCH/n/entry['output_file']).read_bytes()) for n in ('original', 'native')}
    if runs['original']['age_years'] != runs['native']['age_years']:
        raise ValueError('Age substitution differs')
    if any(r['sha256'] != entry[n+'_sha256'] for n, r in runs.items()):
        raise ValueError('A saved document differs from the batch receipt')
    print(json.dumps({'result': 'pass', 'image_sha256': batch['input_sha256'],
                      'source_sha256': entry['source_sha256'],
                      'batch_receipt_sha256': hashlib.sha256(raw).hexdigest(), 'runs': runs,
                      'scope': 'Original and native documents contain each resolved define and preserve its widget binding. Wall-clock time may vary.'},
                     indent=2))


if __name__ == '__main__':
    main()
