"""Drive the shared X-Caliber input and state checks."""

import re
import runpy
import time


def exercise(guest, report, *, fire=True):
    guest.wait('XC ready\n', 90)
    time.sleep(3)
    guest.screenshot('intro')
    log = guest.wait('XC pointer ', 10)
    pointer = re.search(r'^XC pointer ([0-9A-F]+)$', log, re.M)
    if pointer is None:
        raise ValueError('Missing popup pointer address')
    drag = runpy.run_path('build/tothefront-original-v1/phase_workflow.py')['drag']
    okay = (160, 156)
    drag(guest, int(pointer[1], 16), okay, okay)
    log = guest.wait('XC level ', 30)
    level = re.search(r'^XC level (\d+) enemies (\d+) score (\d+)$', log, re.M)
    if level is None:
        raise ValueError('Missing level state')
    report['level'], report['enemies'], report['score'] = map(int, level.groups())
    if (report['level'], report['enemies'], report['score']) != (1, 4, 0):
        raise ValueError('Expected the original level-one state')
    guest.screenshot('level')
    guest.press('ret')
    guest.wait('XC running\n', 20)
    if fire:
        guest.press('spc')
        guest.wait('XC gun fired\n', 20)
        report['gun_fired'] = True
    guest.screenshot('play')
    guest.press('esc')
    guest.wait('XC returned\n', 30)
    report.update(result='pass', returned=True)
