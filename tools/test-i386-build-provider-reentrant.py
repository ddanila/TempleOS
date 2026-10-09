#!/usr/bin/env python3
"""Build an initializer that recursively acquires itself, then test a fresh boot."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import struct

ROOT = Path(__file__).resolve().parents[1]
PROVIDER = '/Modules/I386/BuildRuntime.t32m'
FIXTURE_MODULE = '/Probe/ReentrantBuildRuntime.t32m'
OUTPUTS = ('/Probe/ReentrantStartup1.t32m', '/Probe/ReentrantStartup2.t32m')
PROVIDER_SOURCE = (ROOT/'Kernel/I386/BuildRuntime.HC').read_text()
if PROVIDER_SOURCE.count('I64 Main(') != 1:
    raise ValueError('Provider initializer declaration is not unique')
SOURCE = PROVIDER_SOURCE.replace('I64 Main(', 'I64 BuildOriginalMain(', 1) + r'''
import CI386BuildServices *I386BuildRuntimeAcquire();
I64 Main(CI386BuildServices *services,I64 bytes)
{
  if(I386BuildRuntimeAcquire)return 0;
  KernelLog("BUILD PROVIDER REENTRANT rejected\n");
  return BuildOriginalMain(services,bytes);
}
'''



def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    candidate = out/'candidate.img'
    original_sha = hashlib.sha256(args.disk.read_bytes()).hexdigest()
    shutil.copyfile(args.disk, candidate)
    runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
    build = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
    audit = runpy.run_path(str(ROOT/'tools/test-i386-retained-build.py'))['exports_of']
    report = dict(result='running', stage='build-fixture', source_disk_sha256=original_sha,
                  fixture_source_sha256=hashlib.sha256(SOURCE.encode()).hexdigest(),
                  scope='Recursive acquisition during provider initialization and cached reuse at 16 MiB')
    def save():
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    def run(directory, commands):
        runner(candidate, out/directory, snapshot=False, ram_mib=16, accel='tcg',
               cpu='486,-fpu', qmp_stdio=True, startup_timeout=180,
               startup_check={'status':'ok', 'answers':[], 'commands':commands,
                              'command_timeout':1200, 'rejected_answers':['0'],
                              'rejection_prefixes':('BUILD MODULE REJECT ',)})
    save()
    try:
        commands = [(f'U8 *ReentrantSource=CAlloc({len(SOURCE)+1});', []),
                    ('U0 ReentrantTransfer(I64 offset,U8 *text,I64 size){MemCpy(ReentrantSource+offset,text,size);}', [])]
        for offset in range(0,len(SOURCE),60):
            chunk = SOURCE[offset:offset+60]
            commands.append((f'ReentrantTransfer({offset},{json.dumps(chunk)},{len(chunk)});', []))
        commands += [(f'FileWrite("C:/ReentrantBuildRuntime.HC",ReentrantSource,{len(SOURCE)})>0;', ['1']),
                     ('Free(ReentrantSource);', []),
                     (f'I386BuildModule("C:/ReentrantBuildRuntime.HC","C:{FIXTURE_MODULE}",TRUE)>0;', ['1']),
                     (f'Bool InstallReentrant(){{I64 n;U8 *p=FileRead("C:{FIXTURE_MODULE}",&n);Bool ok=p&&FileWrite("C:{PROVIDER}",p,n)>0;Free(p);return ok;}}', []),
                     ('InstallReentrant;', ['1'])]
        if any(len(source.encode())>255 for source,_ in commands):
            raise ValueError('Fixture transfer exceeds interactive line limit')
        run('fixture', commands)
        files = build['mutated_file_contents'](candidate,{PROVIDER,FIXTURE_MODULE})
        module = files[PROVIDER]
        _, exports = audit(module)
        if module != files[FIXTURE_MODULE] or not {'Main','BuildOriginalMain'} <= set(exports):
            raise ValueError('Guest-built initializer fixture was not installed')
        count, records = struct.unpack_from('<II',module,20)
        imports = {module[name:name+length] for kind,_,name,length in
                   (struct.unpack_from('<4I',module,records+16*i) for i in range(count)) if kind in (2,5)}
        if b'I386BuildRuntimeAcquire' not in imports:
            raise ValueError('Fixture does not import recursive acquisition')
        report.update(stage='fresh-boot', fixture_module_sha256=hashlib.sha256(module).hexdigest())
        save()
        run('behavior', [(f'I386BuildModule("C:/Kernel/I386/Startup.HC","C:{path}",TRUE)>0;', ['1'])
                         for path in OUTPUTS]+[('6*7;', ['42'])])
        log = (out/'behavior/debug.log').read_text()
        nested = 'BUILD PROVIDER REENTRANT rejected\n'
        loaded = 'BUILD PROVIDER loaded\n'
        ready = log.find('READY native kernel')
        if (log.count(nested)!=1 or log.count(loaded)!=1 or ready<0 or
                not ready < log.find(nested) < log.find(loaded)):
            raise ValueError('Recursive acquisition and outer publication order failed')
        outputs = build['mutated_file_contents'](candidate,set(OUTPUTS))
        reference = build['mutated_file_contents'](args.disk,{'/Modules/I386/Startup.t32m'})
        _, expected = audit(reference['/Modules/I386/Startup.t32m'])
        for path in OUTPUTS:
            _, actual = audit(outputs.get(path))
            if set(actual)!=set(expected):
                raise ValueError('Reentrant fixture build changed Startup export contract')
        if outputs[OUTPUTS[0]] != outputs[OUTPUTS[1]]:
            raise ValueError('Reentrant first use and reuse differ')
        report.update(result='pass',stage='complete',nested_acquisition_rejections=1,
                      build_provider_loads=1,successful_builds=2)
    except Exception as error:
        report.update(result='fail',error=str(error))
        raise
    finally:
        if hashlib.sha256(args.disk.read_bytes()).hexdigest()!=original_sha:
            report.update(result='fail',error='Input disk changed')
        save()
    if report['result']!='pass':
        raise ValueError(report['error'])
    print(json.dumps(report,indent=2))


if __name__=='__main__':
    main()
