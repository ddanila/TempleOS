#!/usr/bin/env python3
"""Add pinned autocomplete dictionaries to a native image without replacing files."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--archive',type=Path,required=True);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve();source=args.disk.resolve();archive_dir=args.archive.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True);image=out/'candidate.img'
    archive=archive_dir/'guest/ACWords.DATA.Z';archive_report=archive_dir/'result.json';inventory=ROOT/'docs/i386-compatibility-inventory.json'
    words=ROOT/'Adam/AutoComplete/ACWords.DATA';defs=ROOT/'Adam/AutoComplete/ACDefs.DATA';packager=ROOT/'tools/package-i386-native-image.py';build=ROOT/'tools/build-i386-kernel.py'
    paths=[source,archive,archive_report,inventory,words,defs,packager,build,Path(__file__).resolve()]
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,scope='Pinned uncompressed definitions and original-system compressed word-list packaging; not dictionary initialization or autocomplete qualification')
    try:
        expected={e['path']:e['reference_sha256'] for e in json.loads(inventory.read_text())['entries'] if e['path'] in ('Adam/AutoComplete/ACWords.DATA','Adam/AutoComplete/ACDefs.DATA')}
        if len(expected)!=2 or any(sha(ROOT/name)!=digest for name,digest in expected.items()):raise ValueError('Dictionary asset differs from original')
        archive_info=json.loads(archive_report.read_text())
        if archive_info.get('result')!='pass' or not archive_info.get('inputs_unchanged') or archive_info.get('archive_sha256')!=sha(archive) or archive_info.get('expanded_bytes')!=words.stat().st_size:raise ValueError('Need matching original round-trip archive')
        additions={'/Adam/AutoComplete/ACWords.DATA.Z':archive.read_bytes(),'/Adam/AutoComplete/ACDefs.DATA':defs.read_bytes()}
        attrs={'/Adam/AutoComplete/ACWords.DATA.Z':0xC00}
        pkg=runpy.run_path(str(packager))
        report['packaging']=pkg['package'](source,image,additions=additions,addition_attributes=attrs)
        _,files,_=pkg['snapshot'](image.read_bytes())
        for name,payload in additions.items():
            attr,date,data=files[name]
            if attr!=attrs.get(name,0x800) or data!=payload:raise ValueError('Packaged dictionary mismatch: '+name)
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(name))==digest for name,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
