#!/usr/bin/env python3
"""Verify packaged autocomplete dictionary lookup and full word-list expansion."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve();source=args.disk.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True);image=out/'working.img'
    fixture=ROOT/'tests/guest/i386-autocomplete-assets/Contract.HC';words=ROOT/'Adam/AutoComplete/ACWords.DATA';helper=ROOT/'tools/test-i386-timeclock-welcome.py';packager=ROOT/'tools/package-i386-native-image.py';build=ROOT/'tools/build-i386-kernel.py'
    paths=[source,fixture,words,helper,packager,build,Path(__file__).resolve()]
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,scope='Native dictionary lookup, compressed word-list full expansion and saved-byte comparison; not FOpen, autocomplete initialization or suggestion qualification')
    try:
        report['packaging']=runpy.run_path(str(packager))['package'](source,image,additions={'/ACAssets.HC':fixture.read_bytes()})
        runpy.run_path(str(helper))['guest'](image,out/'guest',['#include "C:/ACAssets.HC"','AutoCompleteAssetsCheck;','6*7;'],64,True,command_timeout=1800)
        files=runpy.run_path(str(build))['mutated_file_contents'](image,{'/ACAssets.HC','/ACWordsCopy.DATA'})
        if files['/ACAssets.HC']!=fixture.read_bytes() or files['/ACWordsCopy.DATA']!=words.read_bytes():raise ValueError('Expanded word list differs from original')
        report['word_sha256']=sha(words);report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(name))==digest for name,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
