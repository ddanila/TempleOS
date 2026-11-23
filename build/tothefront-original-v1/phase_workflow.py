"""Run the physical setup and Space keys against the actual game loop."""
import re
import struct
import time

EXPECTED = [(1, phase, phase % 2, 32, 32) for phase in range(6)] + [(2, 0, 1, 32, 32)]


def drag(guest, address, start, end):
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
        raise ValueError(f'Pointer did not reach drag target {target}')

    aim(start)
    guest.call('input-send-event', events=[
        {'type': 'btn', 'data': {'button': 'left', 'down': True}}])
    time.sleep(.25)
    aim(end)
    guest.call('input-send-event', events=[
        {'type': 'btn', 'data': {'button': 'left', 'down': False}}])


def move_unit(guest):
    log = guest.wait('TTF move ', 20)
    match = re.search(r'^TTF move ([0-9A-F]+)((?: -?\d+){8})$', log, re.M)
    if match is None:
        raise ValueError('Missing move selection')
    address = int(match[1], 16)
    index, sx, sy, dx, dy, row, col, points = map(int, match[2].split())
    drag(guest, address, (sx, sy), (dx, dy))
    state = (index, row, col, points)
    guest.wait('TTF moved ' + ' '.join(map(str, state)) + '\n', 30)
    return state


def fire_unit(guest):
    log = guest.wait('TTF fire ', 20)
    match = re.search(r'^TTF fire ([0-9A-F]+)((?: -?\d+){7})$', log, re.M)
    if match is None:
        raise ValueError('Missing attack selection')
    address = int(match[1], 16)
    attacker, defender, sx, sy, ex, ey, before = map(int, match[2].split())
    drag(guest, address, (sx, sy), (ex, ey))
    log = guest.wait('TTF fired ', 45)
    result = re.search(r'^TTF fired (\d+) (\d+) (\d+) (\d+)$', log, re.M)
    if result is None:
        raise ValueError('Missing attack result')
    a, d, hit, after = map(int, result.groups())
    if (a, d) != (attacker, defender) or hit not in (0, 1) or after > before:
        raise ValueError('Invalid direct-fire state')
    return dict(attacker=attacker, defender=defender, hit=bool(hit),
                life_before=before, life_after=after)


def queue_indirect(guest):
    log = guest.wait('TTF aim indirect ', 20)
    match = re.search(r'^TTF aim indirect ([0-9A-F]+)((?: -?\d+){7})$', log, re.M)
    if match is None:
        raise ValueError('Missing indirect target selection')
    address = int(match[1], 16)
    unit, sx, sy, ex, ey, row, col = map(int, match[2].split())
    drag(guest, address, (sx, sy), (ex, ey))
    guest.wait(f'TTF order queued {unit} {row} {col}\n', 25)
    return unit, row, col


def exercise(guest, move=False, fire=False, indirect=False):
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
    expected_states = list(EXPECTED)
    for index, state in enumerate(expected_states):
        expected = 'TTF phase ' + ' '.join(map(str, state)) + '\n'
        guest.wait(expected, 25)
        time.sleep(1)
        guest.screenshot(f'phase-{index}')
        if indirect and index == 0:
            order = queue_indirect(guest)
        if move and index == 2:
            movement = move_unit(guest)
            guest.screenshot('moved')
        if fire and index == 4:
            attack = fire_unit(guest)
            guest.screenshot('fired')
            if not attack['life_after']:
                expected_states[index + 1:] = [
                    phase[:4] + (phase[4] - 1,) for phase in expected_states[index + 1:]]
        if index + 1 < len(EXPECTED):
            guest.press('spc')
    if indirect:
        log = guest.wait('TTF queue drained\n', 25)
        blast = re.search(r'^TTF blast (-?\d+) (-?\d+)$', log, re.M)
        if blast is None:
            raise ValueError('Missing artillery impact')
        impact = tuple(map(int, blast.groups()))
    guest.press('esc')
    trace = guest.wait('TTF phase workflow returned\n', 25)
    actual = [tuple(map(int, row)) for row in re.findall(
        r'^TTF phase (\d+) (\d+) (\d+) (\d+) (\d+)$', trace, re.M)]
    if actual != expected_states:
        raise ValueError(f'Unexpected phase trace: {actual!r}')
    result = {'phases': actual}
    if move:
        result['movement'] = movement
    if fire:
        result['direct_fire'] = attack
    if indirect:
        result['indirect_fire'] = {'order': order, 'impact': impact, 'queue_drained': True}
    return result
