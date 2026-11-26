"""Compare the bundled integer, F64, string and date prompts."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import time


SOURCE = Path('Demo/Prompt.HC')
STEPS = (
    ('integer', 'nter int expression', '6*7'),
    ('float', 'nter float expression', '13.0/4'),
    ('name', 'ame (John):', 'Ada'),
    ('date', 'ate (', '08/15/2024'),
)
EXPECTED = ('nt=42', 'loat=3.25000000e0', 'ame:Ada', 'ate=08/15/24')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def capture(guest_type, vision, font, image, out, native):
    guest = guest_type(image, out, native, reference_cpus=1)
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        start = len(guest.collect())
        drive = 'C' if native else 'T'
        guest.type(f'ExeFile("{drive}:/{SOURCE}");')
        guest.press('ret')
        frames = {}
        for stage, prompt, answer in STEPS:
            deadline = time.monotonic() + 20
            while time.monotonic() < deadline:
                log = guest.collect()[start:]
                if 'INPUT REJECT ' in log:
                    raise ValueError(log[-1500:])
                guest.screenshot(stage)
                frame = out / f'{stage}.png'
                positions = vision['matches'](frame, prompt, font)
                if positions:
                    frames[stage] = dict(positions=positions, sha256=sha(frame))
                    break
                time.sleep(.4)
            else:
                raise TimeoutError(f'{stage} prompt missing on {out.name}')
            guest.type(answer)
            guest.press('ret')
        if native:
            guest.wait('COMMAND OK\n', start=start)
        time.sleep(2)
        guest.screenshot('completed')
        frame = out / 'completed.png'
        values = {label: vision['matches'](frame, label, font) for label in EXPECTED}
        result = dict(frames=frames, values=values, completed_sha256=sha(frame))
        if native:
            guest.command('6*7;')
            result['fresh_result'] = guest.result_pixels()
        result['result'] = 'pass' if all(values.values()) else 'fail'
        return result
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
    disk = out / 'working.img'
    shutil.copyfile(native, disk)
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font = vision['glyphs'](Path('Kernel/FontStd.HC'))
    guest_type = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    results = {}
    with ThreadPoolExecutor(max_workers=2) as pool:
        runs = {name: pool.submit(capture, guest_type, vision, font, image, out / name, name == 'native')
                for name, image in (('original', original), ('native', disk))}
        for name, run in runs.items():
            try:
                results[name] = run.result()
            except (ValueError, RuntimeError, TimeoutError) as error:
                results[name] = dict(result='fail', error=str(error))
    unchanged = all(sha(Path(p)) == digest for p, digest in inputs.items())
    passed = unchanged and all(run['result'] == 'pass' for run in results.values())
    report = dict(result='pass' if passed else 'fail', input_sha256=inputs, inputs_unchanged=unchanged,
                  answers={name: answer for name, _, answer in STEPS}, runs=results)
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if not passed:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
