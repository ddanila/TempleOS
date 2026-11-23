"""Compare Titanium's real finish and registry write with a staged match state."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import subprocess

APP = Path('Apps/Titanium')


def once(data, old, new):
    if data.count(old) != 1:
        raise ValueError(f'Ambiguous Titanium fixture anchor {old!r}')
    return data.replace(old, new, 1)


def fixture(body):
    body = once(body, b'      total_score=3*',
                b'      enemy_left=U_ENEMY_NUM-4; enemy_by_friendly=2;\n'
                b'      friendly_fire=1; bullets_fired=7; friendly_left=8;\n'
                b'      best_score=0; game_over=TRUE; t0=tS;\n'
                b'      total_score=3*')
    body = once(body, b'\tif (!ch) ch=GetChar(,FALSE);',
                b'\tTiTrace("FINISH",total_score,best_score);\n'
                b'\tch=GetChar(,FALSE);')
    body = once(body, b'  RegWrite("TempleOS/Titanium","I64 best_score=%d;\\n",best_score);',
                b'  if(RegWrite("TempleOS/Titanium","I64 best_score=%d;\\n",best_score))\n'
                b'    TiTrace("SAVED",total_score,best_score);\n')
    trace = (b'U0 TiTrace(U8 *tag,I64 score,I64 best)\n'
             b'{ U8 *s=MStrPrint("TITANIUM %s %d %d\\n",tag,score,best),*p=s;\n'
             b'  while(*p) OutU8(0xE9,*p++); Free(s); }\n')
    return trace+body


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    native = args.disk is not None
    out = args.out.resolve()
    out.mkdir()
    if native:
        read = runpy.run_path('tools/build-i386-kernel.py')['mutated_file_contents']
        paths = {f'/{APP}/{name}' for name in ('Titanium.HC', 'Load.HC')}
        files = read(args.disk, paths)
        body, loader = (files[f'/{APP}/{name}'] for name in ('Titanium.HC', 'Load.HC'))
    else:
        overlay = out/'overlay'
        runpy.run_path('tools/test-i386-timeclock-reference.py')['restore_reference'](overlay)
        body, loader = ((overlay/APP/name).read_bytes() for name in ('Titanium.HC', 'Load.HC'))
    probe = fixture(body)
    loader = once(loader, b'#include "Titanium"', b'#include "ScoreProbe.HC"')
    entry = b'Cd(__DIR__);;\n#include "ScoreLoad.HC"\nTitanium;\n'
    files = {'ScoreProbe.HC': probe, 'ScoreLoad.HC': loader, 'ScoreRun.HC': entry}
    if native:
        disk = out/'working.img'
        pack = runpy.run_path('tools/package-i386-native-image.py')['package']
        pack(args.disk, disk, additions={f'/{APP}/{name}': value for name, value in files.items()})
    else:
        for name, value in files.items():
            (overlay/APP/name).write_bytes(value)
        (overlay/'Once.HC').write_bytes(
            b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
            b'#include "T:/Apps/Titanium/ScoreRun.HC"\n')
        disk = out/'original.iso'
        subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                        '--output', str(disk)], check=True)
    report = {'result': 'running', 'native': native,
              'application_sha256': hashlib.sha256(body).hexdigest(),
              'fixture_sha256': hashlib.sha256(probe).hexdigest()}
    Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest = Guest(disk, out/'guest', native)
    try:
        if native:
            guest.wait('DONE native kernel startup\n')
            guest.type('#include "C:/Apps/Titanium/ScoreRun.HC"')
            guest.press('ret')
        observe = runpy.run_path('build/grmodels-menu-workflows-v1/run.py')['wait_text']
        check = runpy.run_path('tools/check-i386-autocomplete-numeric-pixels.py')
        observe(guest, check, check['font_bytes'](), b'Scoring:', 'instructions')
        guest.press('ret')
        guest.wait('TITANIUM FINISH ', 90)
        guest.screenshot('finish')
        guest.press('esc')
        guest.wait('TITANIUM SAVED ', 45)
        scores = re.findall(r'^TITANIUM (FINISH|SAVED) (-?\d+) (-?\d+)$',
                            guest.collect(), re.M)
        if scores != [('FINISH', '1915', '1915'), ('SAVED', '1915', '1915')]:
            raise ValueError(f'Unexpected Titanium scores {scores}')
        if native:
            guest.command('6*7;')
            report['fresh_arithmetic'] = guest.result_pixels()
        report.update(result='pass', scores=scores)
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        guest.close()
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
