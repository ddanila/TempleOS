"""Compare both language choices and case-insensitive answers in Define.HC."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import time


DEMO = '/Demo/Define.HC'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def capture(guest_type, image, out, native, spanish):
    guest = guest_type(image, out, native, reference_cpus=1)
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        setup = 'U0 DL(U8*s){while(*s)OutU8(0xE9,*s++);}'
        if native:
            guest.command(setup)
        else:
            guest.type(setup)
            guest.press('ret')
        start = len(guest.collect())
        drive = 'C' if native else 'T'
        label, answer = ('Salida', 'sI') if spanish else ('Exit', 'yES')
        guest.type(f'ExeFile("{drive}:{DEMO}");if(!StrCmp(Define("ST_EXIT"),"{label}") && DefineMatch("{answer}","ST_NO_YES_LST",LMF_IGNORE_CASE)==1)DL("DEFINE PASS\\n");')
        guest.press('ret')
        time.sleep(4)
        guest.press('y' if spanish else 'n')
        time.sleep(2)
        guest.screenshot('localized-prompt')
        guest.type('invalid')
        guest.press('ret')
        time.sleep(2)
        if 'DEFINE PASS\n' in guest.collect()[start:]:
            raise ValueError('The demo accepted an invalid answer')
        guest.screenshot('retry')
        guest.type(answer)
        guest.press('ret')
        guest.wait('DEFINE PASS\n', timeout=15, start=start)
        guest.screenshot('completed')
        result = dict(label=label, answer=answer, invalid_rejected=True, definitions_verified=True,
                      screenshots_sha256={name: sha(out/f'{name}.png')
                                          for name in ('localized-prompt','retry','completed')})
        if native:
            guest.command('6*7;')
            result['fresh_result'] = guest.result_pixels()
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
    original, native = (p.resolve() for p in (args.original_iso,args.native_image))
    inputs = {str(p):sha(p) for p in (original,native)}
    guest_type = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    report = dict(input_sha256=inputs, source_sha256=sha(Path(DEMO[1:])), runs={})
    with ThreadPoolExecutor(max_workers=4) as pool:
        runs = {}
        for side,image in (('original',original),('native',native)):
            for locale in ('english','spanish'):
                name = f'{side}-{locale}'
                working = image
                if side == 'native':
                    working = out/f'{name}.img'
                    shutil.copyfile(image,working)
                runs[name] = pool.submit(capture,guest_type,working,out/name,side=='native',locale=='spanish')
        for name,future in runs.items():
            try:
                report['runs'][name] = dict(result='pass',**future.result())
            except (ValueError,RuntimeError,TimeoutError) as error:
                report['runs'][name] = dict(result='fail',error=str(error))
    report['inputs_unchanged'] = all(sha(Path(p))==digest for p,digest in inputs.items())
    passed = report['inputs_unchanged'] and all(r['result']=='pass' for r in report['runs'].values())
    report['result'] = 'pass' if passed else 'fail'
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if not passed:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
