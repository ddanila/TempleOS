"""Exercise DolDoc sprite and menu entry selection with PC-speaker capture."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path
import runpy
import shutil
import time


SOURCE = Path('Demo/DolDoc/MenuSprite.HC')


speaker = runpy.run_path(str(Path(__file__).resolve().parents[1] /
                             'i386-demo-menu-buttons-v1' / 'run.py'))
sha = speaker['sha']
frequencies = speaker['frequencies']


def capture(guest_type, image, out, native):
    audio=out/'speaker.wav'
    guest=guest_type(image,out,native,reference_cpus=1,audio_wav=audio)
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        start=len(guest.collect())
        drive='C' if native else 'T'
        guest.type(f'ExeFile("{drive}:/{SOURCE}");')
        guest.press('ret')
        time.sleep(3)
        log=guest.collect()[start:]
        if 'INPUT REJECT ' in log:
            raise ValueError(log[-1800:])
        images=[]
        def show(name):
            guest.screenshot(name)
            images.append(name)
        show('initial-menu')
        for index, name in enumerate(('sprite-tone', 'middle-tone', 'high-tone')):
            for _ in range(index):
                guest.press('tab')
            guest.press('spc')
            time.sleep(2)
            show(name)
        for _ in range(3):
            guest.press('tab')
        guest.press('spc')
        if native:
            log=guest.wait('COMMAND OK\n',timeout=15,start=start)
            if 'INPUT REJECT ' in log[start:]:
                raise ValueError(log[start:][-1800:])
        else:
            time.sleep(2)
        time.sleep(1)
        silent_start = audio.stat().st_size
        time.sleep(1)
        silent_bytes = audio.stat().st_size - silent_start
        show('after-exit')
        result=dict(silent_bytes=silent_bytes,screenshots_sha256={name:sha(out/f'{name}.png') for name in images})
        if native:
            guest.command('6*7;')
            result['fresh_result']=guest.result_pixels()
    finally:
        guest.close()
    hz=frequencies(audio)
    ranges = ((40, 60), (90, 110), (180, 215))
    passed = silent_bytes == 0 and all(
        any(low <= f <= high and count >= 5 for f, count in hz.items())
        for low, high in ranges)
    result.update(result='pass' if passed else 'fail',
                  audio_sha256=sha(audio), tone_windows=hz)
    return result


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original_iso',type=Path)
    parser.add_argument('native_image',type=Path)
    parser.add_argument('--out',required=True,type=Path)
    args=parser.parse_args()
    out=args.out.resolve()
    out.mkdir()
    original,native=(p.resolve() for p in (args.original_iso,args.native_image))
    pins={str(p):sha(p) for p in (original,native,SOURCE.resolve())}
    disk=out/'working.img'
    shutil.copyfile(native,disk)
    guest=runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    results={}
    with ThreadPoolExecutor(max_workers=2) as pool:
        runs={side:pool.submit(capture,guest,image,out/side,side=='native')
              for side,image in (('original',original),('native',disk))}
        for side,future in runs.items():
            try:
                results[side]=future.result()
            except (RuntimeError,TimeoutError,ValueError) as error:
                results[side]=dict(result='fail',error=str(error))
    unchanged=all(sha(Path(p))==digest for p,digest in pins.items())
    passed=unchanged and all(r['result']=='pass' for r in results.values())
    (out/'result.json').write_text(json.dumps(dict(result='pass' if passed else 'fail',
                                               input_sha256=pins,inputs_unchanged=unchanged,
                                               runs=results),indent=2)+'\n')
    if not passed:
        raise SystemExit(1)


if __name__=='__main__':
    main()
