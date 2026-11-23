"""Run the physical setup and Space keys against the actual game loop."""
import re
import struct
import time

EXPECTED = [(1, phase, phase % 2, 32, 32) for phase in range(6)] + [(2, 0, 1, 32, 32)]


def move_unit(guest):
    log = guest.wait('TTF move ', 20)
    match = re.search(r'^TTF move ([0-9A-F]+)((?: -?\d+){8})$', log, re.M)
    if match is None:
        raise ValueError('Missing move selection')
    address = int(match[1], 16)
    index, sx, sy, dx, dy, row, col, points = map(int, match[2].split())
    path = guest.out / 'pointer.bin'

    def aim(target):
        for _ in range(50):
            guest.call('pmemsave', val=address, size=16, filename=str(path))
            x, y = struct.unpack('<2q', path.read_bytes())
            if (x, y) == target:
                return
            guest.call('input-send-event', events=[
                {'type': 'rel', 'data': {'axis': 'x', 'value': target[0] - x}},
                {'type': 'rel', 'data': {'axis': 'y', 'value': target[1] - y}},
            ])
            time.sleep(.2)
        raise ValueError(f'Pointer did not reach move target {target}')

    aim((sx, sy))
    guest.call('input-send-event', events=[
        {'type': 'btn', 'data': {'button': 'left', 'down': True}}])
    time.sleep(.25)
    aim((dx, dy))
    guest.call('input-send-event', events=[
        {'type': 'btn', 'data': {'button': 'left', 'down': False}}])
    state = (index, row, col, points)
    guest.wait('TTF moved ' + ' '.join(map(str, state)) + '\n', 30)
    return state


def exercise(guest, move=False):
    guest.screenshot('entry')
    guest.type('12345678')
    guest.press('ret')
    time.sleep(8)
    guest.screenshot('player-one')
    for name in ('player-two', 'instructions'):
        guest.press('esc')
        time.sleep(5)
        guest.screenshot(name)
    guest.press('esc')
    for index, state in enumerate(EXPECTED):
        expected = 'TTF phase ' + ' '.join(map(str, state)) + '\n'
        guest.wait(expected, 25)
        time.sleep(1)
        guest.screenshot(f'phase-{index}')
        if move and index == 2:
            movement = move_unit(guest)
            guest.screenshot('moved')
        if index + 1 < len(EXPECTED):
            guest.press('spc')
    guest.press('esc')
    trace = guest.wait('TTF phase workflow returned\n', 25)
    actual = [tuple(map(int, row)) for row in re.findall(
        r'^TTF phase (\d+) (\d+) (\d+) (\d+) (\d+)$', trace, re.M)]
    if actual != EXPECTED:
        raise ValueError(f'Unexpected phase trace: {actual!r}')
    result = {'phases': actual}
    if move:
        result['movement'] = movement
    return result
