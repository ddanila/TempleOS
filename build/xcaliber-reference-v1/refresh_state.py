"""Read the stalled guest timer and refresh state without guest execution."""

import re
import time


def collect(guest):
    log = guest.collect()
    matches = re.findall(
        r'^XC refresh pointers ([0-9A-F]+) ([0-9A-F]+) ([0-9A-F]+)$', log, re.M)
    if not matches:
        return []
    addresses = dict(zip(('jiffies', 'updates', 'refresh_semaphore'),
                         (int(value, 16) for value in matches[-1]), strict=True))
    samples = []
    for index in range(3):
        sample = {}
        for name, address in addresses.items():
            path = guest.out / f'refresh-{index}-{name}.bin'
            guest.call('pmemsave', val=address, size=8, filename=str(path))
            sample[name] = int.from_bytes(path.read_bytes(), 'little')
        registers = guest.call('human-monitor-command', **{'command-line': 'info registers'})
        sample['registers'] = registers
        samples.append(sample)
        if index < 2:
            time.sleep(0.5)
    return samples
