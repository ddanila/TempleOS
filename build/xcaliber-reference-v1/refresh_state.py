"""Read the stalled guest timer and refresh state without guest execution."""

import re
import struct
import time


def read(guest, address, size, name):
    path = guest.out / name
    guest.call('pmemsave', val=address, size=size, filename=str(path))
    data = path.read_bytes()
    if len(data) != size:
        raise ValueError(f'Incomplete memory sample at {address:#x}')
    return data


def frames(guest, registers, index):
    match = re.search(r'\bEBP=([0-9a-f]+)', registers, re.I)
    pc = re.search(r'\bEIP=([0-9a-f]+)', registers, re.I)
    if not match or not pc:
        return []
    frame, instruction = int(match[1], 16), int(pc[1], 16)
    result = []
    for level in range(8):
        if frame < 0x200 or frame >= (64 << 20) - 72:
            break
        data = read(guest, frame - 0x180, 0x180 + 72,
                    f'refresh-{index}-frame-{level}.bin')
        parent, continuation = struct.unpack_from('<II', data, 0x180)
        args = struct.unpack_from('<8Q', data, 0x188)
        result.append({
            'pc': instruction, 'frame': frame, 'return_address': continuation,
            'argument_words': list(args),
            'local_words': list(struct.unpack_from('<48Q', data)),
        })
        if not frame < parent <= frame + (1 << 20):
            break
        frame, instruction = parent, continuation
    return result


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
        guest.call('stop')
        try:
            for name, address in addresses.items():
                data = read(guest, address, 8, f'refresh-{index}-{name}.bin')
                sample[name] = int.from_bytes(data, 'little')
            registers = guest.call('human-monitor-command', **{'command-line': 'info registers'})
            sample['registers'] = registers
            sample['frames'] = frames(guest, registers, index)
        finally:
            guest.call('cont')
        samples.append(sample)
        if index < 2:
            time.sleep(0.5)
    return samples
