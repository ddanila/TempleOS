"""Exercise the DolDoc buttons, frequency popup, and emitted speaker tones."""
import argparse
import array
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import math
from pathlib import Path
import runpy
import shutil
import sys
import time
import wave


SOURCE = Path('Demo/DolDoc/MenuBttn.HC')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def frequencies(path):
    with wave.open(str(path),'rb') as wav:
        if (wav.getnchannels(),wav.getsampwidth(),wav.getframerate())!=(1,2,44100):
            raise ValueError('Unexpected PCM format')
        samples=array.array('h',wav.readframes(wav.getnframes()))
    if sys.byteorder!='little':
        samples.byteswap()
    width=4410
    detected={}
    for offset in range(0,len(samples)-width+1,width):
        current=samples[offset:offset+width]
        if math.sqrt(sum(x*x for x in current)/width)<100:
            continue
        mean=sum(current)/width
        hz=10*sum(a<=mean<b for a,b in zip(current,current[1:]))
        detected[hz]=detected.get(hz,0)+1
    return detected


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
        guest.press('spc')
        time.sleep(2)
        show('tone-on')
        guest.press('tab')
        guest.press('spc')
        time.sleep(2)
        show('frequency')
        guest.press('tab')
        guest.press('tab')
        guest.press('spc')
        time.sleep(2)
        show('changed-tone')
        guest.press('spc')
        time.sleep(1)
        silent_start=audio.stat().st_size
        time.sleep(1)
        silent_bytes=audio.stat().st_size-silent_start
        show('tone-off')
        guest.key('shift',True)
        try:
            guest.press('esc')
        finally:
            guest.key('shift',False)
        if native:
            log=guest.wait('COMMAND OK\n',timeout=15,start=start)
            if 'INPUT REJECT ' in log[start:]:
                raise ValueError(log[start:][-1800:])
        else:
            time.sleep(2)
        show('after-exit')
        result=dict(silent_bytes=silent_bytes,screenshots_sha256={name:sha(out/f'{name}.png') for name in images})
        if native:
            guest.command('6*7;')
            result['fresh_result']=guest.result_pixels()
    finally:
        guest.close()
    hz=frequencies(audio)
    result.update(result='pass' if any(90<=f<=110 and n>=5 for f,n in hz.items())
                       and any(370<=f<=425 and n>=5 for f,n in hz.items())
                       and silent_bytes==0 else 'fail',
                  audio_sha256=sha(audio),tone_windows=hz)
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
