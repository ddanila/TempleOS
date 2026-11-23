import hashlib
from pathlib import Path
import re
import struct
import time


def exercise(guest):
    guest.wait('BALL form start\n', 100)
    time.sleep(2)
    guest.screenshot('form')
    guest.press('esc')
    log = guest.wait('BALL lighting ', 40)
    address = int(re.search(r'BALL lighting ([0-9A-F]+)\n', log)[1], 16)
    pointer = guest.out / 'pointer.bin'
    time.sleep(2)
    guest.screenshot('lighting')
    # Both chooser views place the red full-range swatch on this row.
    target = (64, 211)
    for _ in range(50):
        guest.call('pmemsave', val=address, size=16, filename=str(pointer))
        x, y = struct.unpack('<2q', pointer.read_bytes())
        if (x, y) == target:
            break
        guest.call('input-send-event', events=[
            {'type': 'rel', 'data': {'axis': 'x', 'value': target[0] - x}},
            {'type': 'rel', 'data': {'axis': 'y', 'value': target[1] - y}},
        ])
        time.sleep(.2)
    else:
        raise ValueError(f'Mouse could not reach {target}')
    for down in (True, False):
        guest.call('input-send-event', events=[
            {'type': 'btn', 'data': {'down': down, 'button': 'left'}},
        ])
        time.sleep(.2)
    guest.wait('BALL lighting selected\n', 30)
    time.sleep(5)
    guest.screenshot('confirmation')
    guest.press('n')
    guest.wait('BALL mesh returned\n', 40)
    mesh = (guest.out / 'BallInteractive.bin').read_bytes()
    vertices, triangles = struct.unpack_from('<ii', mesh, 1)
    colors = {struct.unpack_from('<i', mesh, offset)[0]
              for offset in range(9 + 12 * vertices, len(mesh) - 1, 16)}
    if mesh[0] != 24 or mesh[-1] or len(mesh) != 10 + 12 * vertices + 16 * triangles:
        raise ValueError('Invalid mesh record')
    if min(vertices, triangles) <= 0 or colors != {4}:
        raise ValueError(f'Unexpected mesh counts or color: {vertices}, {triangles}, {colors}')
    return dict(vertices=vertices, triangles=triangles, colors=sorted(colors),
                mesh_sha256=hashlib.sha256(mesh).hexdigest())
