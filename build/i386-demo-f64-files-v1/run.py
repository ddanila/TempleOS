"""Reopen the files written by the original generator and sorter demos."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import math
from pathlib import Path
import re
import runpy
import shutil
import struct
import time


DEMO = 'Demo/SortFileDemo'
DUMP_FILE = 'U0 F64DumpFile(U8*p,U8*n){I64 s;U8*b=FileRead(p,&s);if(b){U8*l=MStrPrint("EXPORT %s %X %X\\n",n,b,s);while(*l)OutU8(0xE9,*l++);}}'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def command(guest, native, text):
    if native:
        guest.command(text)
    else:
        guest.type(text)
        guest.press('ret')
        time.sleep(1)


def export(guest, native, stage, extension):
    name = f'Demo{stage}F64.{extension}.Z'
    target = f'{stage.lower()}-{extension.lower()}.bin'
    command(guest, native, f'F64DumpFile("~/{name}","{target}");')
    guest.wait(f'EXPORT {target} ', timeout=15)
    path = guest.out / target
    deadline = time.monotonic() + 5
    while not path.is_file() and time.monotonic() < deadline:
        guest.collect()
        time.sleep(.05)
    if not path.is_file():
        raise TimeoutError(f'Incomplete export of {target}')
    return path.read_bytes()


def examine(guest, native, stage):
    raw = export(guest, native, stage, 'DATA')
    text = export(guest, native, stage, 'DD')
    if len(raw) != 80:
        raise ValueError(f'{stage} binary length differs from ten doubles')
    values = struct.unpack('<10d', raw)
    if not all(math.isfinite(x) and 0 <= x < 1 for x in values):
        raise ValueError(f'{stage} binary values are out of range')
    numbers = re.findall(rb'(?m)^\s*(0\.\d{6})\s*$', text)
    if len(numbers) != 10:
        raise ValueError(f'{stage} DolDoc has {len(numbers)} numeric records')
    return values, [float(x) for x in numbers]


def capture(guest_type, image, out, native):
    guest = guest_type(image, out, native, reference_cpus=1)
    report = {}
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        drive = 'C' if native else 'T'
        if not native:
            command(guest, native, 'HomeSet("B:/");')
        command(guest, native, DUMP_FILE)
        start = len(guest.collect())
        command(guest, native, f'Seed(1);ExeFile("{drive}:/{DEMO}/F64FileGen.HC");')
        if 'INPUT REJECT ' in guest.collect()[start:]:
            raise ValueError(guest.collect()[start:][-1800:])
        raw, text = examine(guest, native, 'Unsorted')
        if len(set(raw)) != 10 or len(set(text)) != 10:
            raise ValueError('The generated records must be distinct')
        report['generator'] = dict(result='pass', binary_values=raw, text_values=text)
        start = len(guest.collect())
        command(guest, native, f'ExeFile("{drive}:/{DEMO}/F64FileSort.HC");')
        if 'INPUT REJECT ' in guest.collect()[start:]:
            raise ValueError(guest.collect()[start:][-1800:])
        ordered_raw, ordered_text = examine(guest, native, 'Sorted')
        if list(ordered_raw) != sorted(raw) or ordered_text != sorted(text):
            raise ValueError('The sorted files differ from the input records')
        report['sorter'] = dict(result='pass', binary_values=ordered_raw, text_values=ordered_text)
        if native:
            command(guest, native, '6*7;')
            report['fresh_result'] = guest.result_pixels()
        report['result'] = 'pass'
    except (ValueError, RuntimeError, TimeoutError) as exc:
        report.update(result='fail',error=str(exc))
    finally:
        guest.close()
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original_iso',type=Path)
    parser.add_argument('native_image',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    out=args.out.resolve()
    out.mkdir()
    original,native=(p.resolve() for p in (args.original_iso,args.native_image))
    inputs={str(p):sha(p) for p in (original,native)}
    working=out/'working.img'
    shutil.copyfile(native,working)
    guest=runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    with ThreadPoolExecutor(max_workers=2) as pool:
        runs = {side:pool.submit(capture,guest,image,out/side,side=='native')
                for side,image in (('original',original),('native',working))}
        results={name:future.result() for name,future in runs.items()}
    unchanged=all(sha(Path(p))==h for p,h in inputs.items())
    passed=unchanged and all(r['result']=='pass' for r in results.values())
    report=dict(result='pass' if passed else 'fail',input_sha256=inputs,inputs_unchanged=unchanged,
                source_sha256={name:sha(Path(DEMO)/name) for name in ('F64FileGen.HC','F64FileSort.HC')},
                runs=results)
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if not passed:
        raise SystemExit(1)


if __name__=='__main__':
    main()
