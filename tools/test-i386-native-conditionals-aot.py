#!/usr/bin/env python3
"""Compile conditionals into a guest-built module and execute it in the loader corpus."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
CONTRACT=runpy.run_path(str(ROOT/'tools/test-i386-native-conditionals.py'))
SOURCE=CONTRACT['SOURCE']+'''#if 1
#ifjit
I64 IfMode(){return 17;}
#else
I64 IfMode(){return 18;}
#endif
#else
invalid skipped mode branch
#endif
I64 Main(I64 unused,I64 unused2){return IfTrue+IfFalse+IfPointer+IfNested+IfFloat+IfTail+IfMode;}
'''


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--welcome',action='store_true',help='Expect the welcome screen')
    parser.add_argument('--packaged',action='store_true',
                        help='Stage the exact source in a disposable image before boot')
    args=parser.parse_args()
    out=args.out.resolve();out.mkdir(parents=True,exist_ok=True)
    result=out/'result.json';result.unlink(missing_ok=True)
    working=out/'working.img'
    if args.disk.resolve()==working:
        parser.error('Working copy must differ from source disk')
    inputs=(Path(__file__),ROOT/'tools/test-i386-native-conditionals.py',ROOT/'tools/test-i386-loader.py')
    sha=lambda file:hashlib.sha256(file.read_bytes()).hexdigest()
    before=sha(args.disk);checkers={str(file.relative_to(ROOT)):sha(file) for file in inputs}
    runner=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))
    if working.exists():runner['require_unlocked_image'](working)
    if args.packaged:
        packaging=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](
            args.disk.resolve(),working,additions={'/IfAot.HC':SOURCE.encode()})
    else:
        shutil.copyfile(args.disk,working)
    report=dict(result='fail',disk_sha256=before,checker_sha256=checkers,
                fixture_sha256=hashlib.sha256(SOURCE.encode()).hexdigest(),
                welcome=args.welcome,packaged=args.packaged,
                scope='Native JIT/AOT mode distinction and loaded guest-built module execution; not allocation-failure cleanup')
    if args.packaged:report['packaging']=packaging
    try:
        commands=([] if args.packaged else CONTRACT['stage'](SOURCE,'Aot'))+[
            ('#include "C:/IfAot.HC"', []),
            ('Main(0,0);', ['98']),
            ('I386BuildModule("C:/IfAot.HC","C:/Probe/ConditionalAot.t32m",TRUE)>0;', ['1']),
            ('6*7;', ['42']),
        ]
        assert all(len(source)<=255 for source,_ in commands)
        report['compile']=runner['run_input'](working,out/'compile',cpu='486,-fpu',
            qmp_stdio=True,snapshot=False,welcome=args.welcome,startup_timeout=360,
            startup_check={'status':'ok','answers':[], 'commands':commands,'command_timeout':600})
        files=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents']
        delivered=files(working,{'/Probe/ConditionalAot.t32m','/IfAot.HC'})
        if args.packaged and delivered.get('/IfAot.HC')!=SOURCE.encode():
            raise ValueError('Packaged conditional source changed')
        module=delivered['/Probe/ConditionalAot.t32m']
        path=out/'ConditionalAot.t32m';path.write_bytes(module)
        with (out/'loader.log').open('w') as log:
            subprocess.run([sys.executable,str(ROOT/'tools/test-i386-loader.py'),
                '--native-module',str(path),'--native-expected','99'],cwd=ROOT,stdout=log,stderr=log,check=True)
        loader=json.loads((ROOT/'build/i386-loader-test/result.json').read_text())
        if loader.get('result')!='pass' or loader.get('native_module')!={
                'sha256':hashlib.sha256(module).hexdigest(),'expected':99}:
            raise ValueError('Loader verdict does not match this native module')
        (out/'loader-result.json').write_text(json.dumps(loader,indent=2)+'\n')
        report.update(result='pass',module_sha256=hashlib.sha256(module).hexdigest(),
                      module_bytes=len(module),loaded_result=99,loader_cases=len(loader['cases']))
    except Exception as exc:
        report['error']=str(exc)
    report['source_disk_unchanged']=sha(args.disk)==before
    report['checkers_unchanged']=all(sha(file)==checkers[str(file.relative_to(ROOT))] for file in inputs)
    if not report['source_disk_unchanged'] or not report['checkers_unchanged']:report['result']='fail'
    result.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
    raise SystemExit(0 if report['result']=='pass' else 1)


if __name__=='__main__':main()
