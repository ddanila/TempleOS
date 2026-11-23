"""Run the physical setup and Space keys against the actual game loop."""
import re
import time

EXPECTED = [(1, phase, phase % 2, 32, 32) for phase in range(6)] + [(2, 0, 1, 32, 32)]


def exercise(guest):
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
        if index + 1 < len(EXPECTED):
            guest.press('spc')
    guest.press('esc')
    trace = guest.wait('TTF phase workflow returned\n', 25)
    actual = [tuple(map(int, row)) for row in re.findall(
        r'^TTF phase (\d+) (\d+) (\d+) (\d+) (\d+)$', trace, re.M)]
    if actual != EXPECTED:
        raise ValueError(f'Unexpected phase trace: {actual!r}')
    return actual
