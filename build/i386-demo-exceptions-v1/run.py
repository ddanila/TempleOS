"""Compare the nested caught and rethrown exception paths in the bundled demo."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import time


SOURCE = Path('Demo/Exceptions.HC')
CASES = {
    'catch': (('1', 'y'), ('3', 'y')),
    'point2': (('1', 'n'), ('2', 'y')),
    'rethrow': (('1', 'n'), ('2', 'n'), ('4', 'y')),
}
EXPECTED = {
    'catch': ('D2 hndlr', 'Demo hndlr', 'Caught in D2', 'Ch:Point1:', 'Ch:Point3:'),
    'point2': ('D2 hndlr', 'Demo hndlr', 'Ch:Point2:'),
    'rethrow': ('D2 hndlr', 'Demo hndlr', 'Ch:Point4:'),
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def capture(guest_type, vision, font, image, out, native, case):
    guest = guest_type(image, out, native, reference_cpus=1)
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        drive = 'C' if native else 'T'
        start = len(guest.collect())
        guest.type(f'ExeFile("{drive}:/{SOURCE}");')
        guest.press('ret')
        for number, answer in CASES[case]:
            prompt = f'{number} (y or n)?'
            deadline = time.monotonic() + 20
            while time.monotonic() < deadline:
                log = guest.collect()[start:]
                if 'INPUT REJECT ' in log:
                    raise ValueError(log[-1800:])
                guest.screenshot(f'prompt-{number}')
                if vision['matches'](out / f'prompt-{number}.png', prompt, font):
                    break
                time.sleep(.4)
            else:
                raise TimeoutError(f'Missing prompt {number} on {out.name}')
            guest.press(answer)
        if native:
            log = guest.wait('COMMAND OK\n', start=start)
            if 'INPUT REJECT ' in log[start:]:
                raise ValueError(log[start:][-1800:])
        time.sleep(4)
        guest.screenshot('completed')
        frame = out / 'completed.png'
        markers = {label: vision['matches'](frame, label, font) for label in EXPECTED[case]}
        for label in markers:
            if label.startswith('Ch:') and not markers[label]:
                markers[label] = vision['matches'](frame, label[3:], font)
        returned = dict(markers=markers, completed_sha256=sha(frame))
        if native:
            guest.command('6*7;')
            returned['fresh_result'] = guest.result_pixels()
        returned['result'] = 'pass' if all(markers.values()) else 'fail'
        return returned
    finally:
        guest.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original_iso', type=Path)
    parser.add_argument('native_image', type=Path)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir()
    original, native = (p.resolve() for p in (args.original_iso, args.native_image))
    inputs = {str(p): sha(p) for p in (original, native, SOURCE.resolve())}
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font = vision['glyphs'](Path('Kernel/FontStd.HC'))
    guest_type = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    results = {}
    with ThreadPoolExecutor(max_workers=4) as pool:
        futures = {}
        for side, image in (('original', original), ('native', native)):
            for case in CASES:
                name = f'{side}-{case}'
                working = image
                if side == 'native':
                    working = out / f'{name}.img'
                    shutil.copyfile(image, working)
                futures[name] = pool.submit(capture, guest_type, vision, font, working, out / name, side == 'native', case)
        for name, future in futures.items():
            try:
                results[name] = future.result()
            except (RuntimeError, TimeoutError, ValueError) as error:
                results[name] = dict(result='fail', error=str(error))
    unchanged = all(sha(Path(p)) == digest for p, digest in inputs.items())
    passed = unchanged and all(result['result'] == 'pass' for result in results.values())
    report = dict(result='pass' if passed else 'fail', inputs_unchanged=unchanged,
                  input_sha256=inputs, cases=CASES, runs=results)
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if not passed:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
