"""Compare record entry, block readback and export in the bundled DataBase demo."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import time


SOURCE = Path('Demo/Dsk/DataBase.HC')
EXPORT = ('U0 DBExport(){I64 n;U8*p=FileRead("~/DataBaseDemo.BIN",&n),'
          '*s=MStrPrint("EXPORT database.bin %X %X\\n",p,n),*q=s;'
          'while(*q)OutU8(0xE9,*q++);Sleep(2000);Free(p);Free(s);}DBExport;')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def submit(guest, line):
    guest.type(line)
    guest.press('ret')


def wait_frame(guest, name, phrase, vision, font, start):
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline:
        log = guest.collect()[start:]
        if 'INPUT REJECT ' in log:
            raise ValueError(log[-2000:])
        guest.screenshot(name)
        if vision['matches'](guest.out / f'{name}.png', phrase, font, first_row=0):
            return
        time.sleep(.5)
    raise TimeoutError(f'Expected {phrase!r} in {name}')


def capture(Guest, image, out, native):
    guest = Guest(image, out, native, reference_cpus=1)
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font = vision['glyphs'](Path('Kernel/FontStd.HC'))
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        if not native:
            submit(guest, 'Cd("B:/");DirMk("B:/Home");HomeSet("B:/Home");')
            time.sleep(2)
        start = len(guest.collect())
        drive = 'C' if native else 'T'
        submit(guest, f'ExeFile("{drive}:/{SOURCE}");')
        wait_frame(guest, 'initial-menu', 'ead acct, ', vision, font, start)
        guest.press('w')
        wait_frame(guest, 'write-prompt', 'Acct #', vision, font, start)
        submit(guest, '7')
        wait_frame(guest, 'write-form', 'Addr:', vision, font, start)
        guest.type('Ada')
        guest.press('tab')
        guest.type('Pine')
        guest.screenshot('edited-form')
        guest.press('esc')
        wait_frame(guest, 'after-write', 'ead acct, ', vision, font, start)
        guest.press('r')
        wait_frame(guest, 'read-prompt', 'Acct #', vision, font, start)
        submit(guest, '7')
        wait_frame(guest, 'read-report', 'Class:"Acct"', vision, font, start)
        guest.press('esc')
        if native:
            guest.wait('COMMAND OK\n', start=start)
        else:
            time.sleep(2)
        submit(guest, EXPORT)
        deadline = time.monotonic() + 60
        database = out / 'database.bin'
        while not database.is_file() and time.monotonic() < deadline:
            log = guest.collect()[start:]
            if 'INPUT REJECT ' in log:
                raise ValueError(log[-2000:])
            time.sleep(.1)
        if not database.is_file():
            raise TimeoutError('Guest did not export the database')
        result = {'result': 'captured', 'database_sha256': sha(database)}
        if native:
            guest.command('6*7;')
            result['fresh_result'] = guest.result_pixels()
        return result
    finally:
        guest.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original', type=Path)
    parser.add_argument('native', type=Path)
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir()
    original, native = args.original.resolve(), args.native.resolve()
    pins = {str(path): sha(path) for path in (original, native, SOURCE.resolve())}
    working = out/'working.img'
    shutil.copyfile(native, working)
    Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    runs = {}
    with ThreadPoolExecutor(max_workers=2) as pool:
        futures = {side: pool.submit(capture, Guest, image, out/side, side == 'native')
                   for side, image in (('original', original), ('native', working))}
        for side, future in futures.items():
            try:
                runs[side] = future.result()
            except (TimeoutError, RuntimeError, ValueError) as error:
                runs[side] = dict(result='fail', error=str(error))
    unchanged = all(sha(Path(path)) == pin for path, pin in pins.items())
    (out/'result.json').write_text(json.dumps(dict(inputs_unchanged=unchanged,
                                                  input_sha256=pins, written_disk_sha256=sha(working), runs=runs), indent=2)+'\n')


if __name__ == '__main__':
    main()
