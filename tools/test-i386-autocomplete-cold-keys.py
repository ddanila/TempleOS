#!/usr/bin/env python3
"""Check autocomplete shortcuts before the optional library is loaded."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
ROOT=Path(__file__).resolve().parents[1]

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();out=args.out.resolve();image=args.disk.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    manifest=image.parent/'result.json';sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
    if sha(image)!=json.loads(manifest.read_text())['disk_sha256']:raise ValueError('Image differs from build manifest')
    helper=ROOT/'tools/test-i386-autocomplete-interaction.py'
    paths=[image,manifest,helper,Path(__file__).resolve(),ROOT/'tools/test-i386-timeclock-welcome.py',ROOT/'tools/build-i386-kernel.py',ROOT/'Kernel/FontStd.HC']
    out.mkdir()
    for path,name in [(Path(__file__).resolve(),'runner-source.py'),(helper,'helper-source.py')]:
        copy=out/name;copy.write_bytes(path.read_bytes());paths.append(copy)
    pins={str(path):sha(path) for path in paths};working=out/'working.img';shutil.copyfile(image,working)
    report=dict(result='running',cpu='486,-fpu',ram_mib=64,input_sha256=pins,scope='Normal boot with library absence asserted: real Ctrl+F1 and Ctrl+1 leave 6*7 unchanged, which executes with visible 42. Not the complete key map or a full autocomplete workflow.')
    guest=None
    try:
        module=runpy.run_path(str(helper));guest=module['Guest'](working,out/'guest',True);guest.wait('DONE native kernel startup\n')
        guest.command('if(HashFind("AutoComplete",Fs->hash_table,HTT_FUN))throw(\'AutoLoad\',TRUE);')
        start=len(guest.collect());guest.type('6*');guest.key('ctrl',True);guest.press('f1');guest.press('1');guest.key('ctrl',False);guest.type('7;');guest.press('ret');guest.wait('COMMAND OK\n',start=start)
        text=guest.collect()[start:]
        if 'INPUT LINE 6*7;\n' not in text or 'INPUT REJECT ' in text:raise ValueError('Cold shortcuts modified the input or rejected execution')
        report['result_pixels']=guest.result_pixels();guest.close();guest=None
        report['filesystem_integrity']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](working)
        report.update(result='pass',library_absent=True,submitted_source='6*7;')
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        if guest:guest.close()
        report['inputs_unchanged']=all(sha(Path(path))==digest for path,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
