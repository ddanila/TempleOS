"""Run the bundled FPrintF demo against identical disposable directory trees."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import time

from PIL import Image, ImageOps


SOURCE = Path('Demo/Dsk/FPrintF.HC')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def capture(Guest, image, out, native):
    guest = Guest(image, out, native, reference_cpus=1)
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font = vision['glyphs'](Path('Kernel/FontStd.HC'))
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        drive = 'C' if native else 'T'
        include = f'ExeFile("{drive}:/Probe/TreeHarness.HC");'
        if native:
            guest.command(include)
        else:
            guest.type(include)
            guest.press('ret')
            time.sleep(1)
        guest.type('FPSetup;' if native else 'FPSetup("B:/Tree.DD");')
        guest.press('ret')
        guest.wait('TREE READY\n', timeout=30)
        start = len(guest.collect())
        guest.type(f'ExeFile("{drive}:/{SOURCE}");')
        guest.press('ret')
        deadline = time.monotonic() + 25
        while time.monotonic() < deadline:
            guest.screenshot('save-form')
            frame = out / 'save-form.png'
            inverted = out / 'save-form-inverted.png'
            with Image.open(frame) as image:
                ImageOps.invert(image.convert('RGB')).save(inverted)
            if any(vision['matches'](candidate, 'FileName:', font, first_row=0)
                   for candidate in (frame, inverted)):
                form_sha256 = sha(frame)
                guest.press('esc')
                if native:
                    guest.wait('COMMAND OK\n', start=start)
                else:
                    time.sleep(2)
                path = 'C:/Tmp.DD.Z' if native else 'B:/Tree.DD'
                export_start = len(guest.collect())
                guest.type(f'FPExport("{path}");')
                guest.press('ret')
                deadline = time.monotonic() + 30
                document = out / 'tree.DD'
                while not document.exists() and time.monotonic() < deadline:
                    log = guest.collect()[export_start:]
                    if 'INPUT REJECT ' in log:
                        raise ValueError(log[-2000:])
                    time.sleep(.2)
                if not document.exists():
                    raise TimeoutError('Missing saved directory document')
                report = dict(result='saved', screenshot_sha256=form_sha256,
                              document_sha256=sha(document))
                if native:
                    guest.wait('COMMAND OK\n', start=export_start)
                    guest.command('6*7;')
                    report['fresh_result'] = guest.result_pixels()
                return report
            log = guest.collect()[start:]
            if 'INPUT REJECT ' in log:
                return dict(result='reject', log=log)
            if native and 'COMMAND OK\n' in log:
                return dict(result='no-prompt', screenshot_sha256=sha(frame), log=log)
            time.sleep(.5)
        return dict(result='timeout', screenshot_sha256=sha(frame))
    finally:
        guest.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('native', type=Path)
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    disk, out = args.native.resolve(), args.out.resolve()
    out.mkdir()
    helper = Path(__file__).with_name('TreeHarness.HC')
    overlay = out/'overlay'
    runpy.run_path('tools/test-i386-timeclock-reference.py')['restore_reference'](overlay)
    (overlay/'Probe').mkdir(exist_ok=True)
    (overlay/'Probe/TreeHarness.HC').write_bytes(helper.read_bytes())
    (overlay/'Once.HC').write_text('U0 FPReady(){U8 *s="DEMO BATCH READY\\n";while(*s)OutU8(0xE9,*s++);}FPReady;\n')
    original = out/'original.iso'
    subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(original)],check=True)
    pack = runpy.run_path('tools/package-i386-native-image.py')
    delivered = pack['snapshot'](disk.read_bytes())[1]['/'+SOURCE.as_posix()][2]
    if delivered != (overlay/SOURCE).read_bytes() or delivered != SOURCE.read_bytes():
        raise ValueError('The bundled demo differs from the original')
    working = out/'working.img'
    pack['package'](disk, working, additions={'/Probe/TreeHarness.HC':helper.read_bytes()})
    inputs = {str(path.resolve()):sha(path) for path in (disk, original, SOURCE, helper)}
    Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    runs = {}
    with ThreadPoolExecutor(max_workers=2) as pool:
        futures = {side:pool.submit(capture,Guest,image,out/side,side=='native')
                   for side,image in (('original',original),('native',working))}
        for side,future in futures.items():
            try:
                runs[side] = future.result()
            except (TimeoutError, RuntimeError, ValueError) as error:
                runs[side] = dict(result='fail',error=str(error))
    unchanged = all(sha(Path(path)) == digest for path,digest in inputs.items())
    (out/'result.json').write_text(json.dumps(dict(input_sha256=inputs,inputs_unchanged=unchanged,
                                                  runs=runs),indent=2)+'\n')


if __name__ == '__main__':
    main()
