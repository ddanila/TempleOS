"""Shared physical keyboard sequence for a fixed-seed Human match."""
import time


def play(guest):
    guest.screenshot('entry')
    guest.type('12345678')
    guest.press('ret')
    time.sleep(8)
    guest.screenshot('player-one')
    for screenshot in ('player-two', 'instructions', 'map'):
        guest.press('esc')
        time.sleep(5)
        guest.screenshot(screenshot)
    guest.press('spc')
    time.sleep(3)
    guest.screenshot('after-phase')
    guest.press('esc')
