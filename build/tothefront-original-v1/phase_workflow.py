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


def occupy_hex(guest):
    log = guest.wait('TTF aim occupation ', 20)
    aim = re.search(r'^TTF aim occupation ([0-9A-F]+)((?: -?\d+){10})$', log, re.M)
    if aim is None:
        raise ValueError('Missing occupation selection')
    attacker, defender, sx, sy, dx, dy, row, col, attacker_life, defender_life = map(
        int, aim[2].split())
    drag(guest, int(aim[1], 16), (sx, sy), (dx, dy))
    log = guest.wait('TTF occupation resolved ', 55)
    outcome = re.search(r'^TTF occupation resolved((?: -?\d+){7})$', log, re.M)
    if outcome is None:
        raise ValueError('Missing occupation outcome')
    a, d, a_life, d_life, a_row, a_col, movement = map(int, outcome[1].split())
    if (a, d) != (attacker, defender) or bool(a_life) == bool(d_life):
        raise ValueError('Invalid occupation life state')
    if a_life and ((a_row, a_col) != (row, col) or movement != 0):
        raise ValueError('Successful occupation must occupy the hex and consume movement')
    return dict(attacker=a, defender=d, target=[row, col], position=[a_row, a_col],
                before=[attacker_life, defender_life], after=[a_life, d_life],
                remaining_movement=movement)


def exercise(guest, move=False, fire=False, indirect=False, indirect_damage=False, occupation_kind=None):
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
        if indirect and index == len(EXPECTED) - 1:
            log = guest.wait('TTF queue drained\n', 35)
            blast = re.search(r'^TTF blast (-?\d+) (-?\d+)$', log, re.M)
            if blast is None:
                raise ValueError('Missing artillery impact')
            impact = tuple(map(int, blast.groups()))
            if indirect_damage:
                damage = re.search(r'^TTF blast damage (\d+) (\d+) (\d+)$', log, re.M)
                if damage is None:
                    raise ValueError('Missing artillery defender state')
                defender, before, after = map(int, damage.groups())
                if not 0 <= after < before or impact != order[1:]:
                    raise ValueError('Expected artillery damage at the selected hex')
                damage_state = dict(defender=defender, life_before=before, life_after=after)
                if not after:
                    state = state[:4] + (state[4] - 1,)
                    expected_states[index] = state
        expected = 'TTF phase ' + ' '.join(map(str, state)) + '\n'
        guest.wait(expected, 25)
        time.sleep(1)
        guest.screenshot(f'phase-{index}')
        if indirect and index == 0:
            order = queue_indirect(guest)
        if move and index == 2:
            movement = move_unit(guest)
            guest.screenshot('moved')
        if occupation_kind and index == 2:
            occupation = occupy_hex(guest)
            guest.screenshot(occupation_kind)
            lost_player = occupation['after'].index(0)
            expected_states[index + 1:] = [
                state[:3] + (state[3] - (lost_player == 0), state[4] - (lost_player == 1))
                for state in expected_states[index + 1:]]
        if fire and index == 4:
            attack = fire_unit(guest)
            guest.screenshot('fired')
            if not attack['life_after']:
                expected_states[index + 1:] = [
                    phase[:4] + (phase[4] - 1,) for phase in expected_states[index + 1:]]
        if index + 1 < len(EXPECTED):
            guest.press('spc')
    guest.press('esc')
    trace = guest.wait('TTF phase workflow returned\n', 25)
    actual = [tuple(map(int, row)) for row in re.findall(
        r'^TTF phase (\d+) (\d+) (\d+) (\d+) (\d+)$', trace, re.M)]
    if actual != expected_states:
        raise ValueError(f'Unexpected phase trace: {actual!r}')
    result = {'phases': actual}
    if move:
        result['movement'] = movement
    if occupation_kind:
        result[occupation_kind] = occupation
    if fire:
        result['direct_fire'] = attack
    if indirect:
        result['indirect_fire'] = {'order': order, 'impact': impact, 'queue_drained': True}
    if indirect_damage:
        result['indirect_fire']['damage'] = damage_state
    return result
