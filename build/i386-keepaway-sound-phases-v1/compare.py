"""Compare the timed finish and restart tones from two completed fixture runs."""

import argparse
from decimal import Decimal
import hashlib
import json
from pathlib import Path
import re


def observe(directory):
    receipt = directory / 'result.json'
    result = json.loads(receipt.read_text())
    if result['result'] != 'pass' or not result['inputs_unchanged']:
        raise ValueError(f'Fixture did not pass with unchanged inputs: {directory}')

    trace = directory / 'guest/debug.log'
    log = trace.read_bytes()
    phases = {
        name.decode(): Decimal(time.decode())
        for name, time in re.findall(rb'^KEEP sound phase (\w+) at ([0-9.]+)$', log, re.M)
    }
    if not phases['handoff'] < phases['pass'] < phases['finish'] < phases['restart']:
        raise ValueError(f'Unexpected phase order: {directory}')

    events = [
        (int(note), Decimal(time.decode()))
        for note, time in re.findall(rb'^KEEP tone (\d+) at ([0-9.]+)$', log, re.M)
    ]
    finish = [(note, time) for note, time in events if phases['finish'] <= time < phases['restart']]
    restart = [(note, time) for note, time in events if time >= phases['restart']]
    if [note for note, _ in finish] != [62, 0, 86, 0, 86, 0]:
        raise ValueError(f'Unexpected finish tone sequence: {directory}: {finish}')
    if [note for note, _ in restart] != [62, 0]:
        raise ValueError(f'Unexpected restart tone sequence: {directory}: {restart}')
    return {
        'receipt_sha256': hashlib.sha256(receipt.read_bytes()).hexdigest(),
        'trace_sha256': hashlib.sha256(log).hexdigest(),
        'finish_tone_seconds': [float(finish[i+1][1] - finish[i][1]) for i in range(0, 6, 2)],
        'restart_tone_seconds': float(restart[1][1] - restart[0][1]),
        'best_score': result['best_score'],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original', type=Path)
    parser.add_argument('native', type=Path)
    args = parser.parse_args()
    print(json.dumps({'original': observe(args.original), 'native': observe(args.native)}, indent=2))


if __name__ == '__main__':
    main()
