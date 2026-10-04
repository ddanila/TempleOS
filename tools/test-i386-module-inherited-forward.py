#!/usr/bin/env python3
"""Module-source completion of a CPU-root forward class keeps the root unchanged."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('class CModuleForward:CHashSrcSym{I64 size,neg_offset;U32 member_cnt;U8 ptr_stars_cnt,raw_type;U16 flags;};', []),
    ('CModuleForward *ModuleOriginal=HashFind("CHashFun",Gs->seth_task->hash_table,HTT_CLASS);', []),
    ('Bool ModuleRoot(){CModuleForward *p=HashFind("CHashFun",Gs->seth_task->hash_table,HTT_CLASS);return p&&p==ModuleOriginal&&!p->size&&!p->neg_offset&&!p->member_cnt&&!p->ptr_stars_cnt&&(p->flags&1);}', []),
    ('ModuleRoot&&HashFind("CHashFun",Fs->hash_table,HTT_CLASS)==ModuleOriginal&&Fs->hash_table!=Gs->seth_task->hash_table;', ['1']),
    ('U8 *ModuleText="#include \\"/Kernel/SymbolTypes.HH\\"\\nI64 Main(){return sizeof(CHashFun); }\\n";', []),
    ('Bool ModuleSource(){CDoc *d=DocNew("C:/Probe/Inherited.HC");U8 *s=ModuleText;while(*s)DocPutKey(d,*s++);Bool ok=DocWrite(d);DocDel(d);return ok;}', []),
    ('ModuleSource;', ['1']),
    ('I386BuildModule("C:/Probe/Inherited.HC","C:/Probe/Inherited.t32m",TRUE)>0;', ['1']),
    ('ModuleRoot;', ['1']),
    ('6*7;', ['42']),
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    checker, disk_hash = sha(Path(__file__)), sha(args.disk)
    source = args.out/'source.img'
    shutil.copyfile(args.disk, source)
    report = {'result':'fail', 'checker_sha256':checker, 'disk_sha256':disk_hash,
              'scope':'Compile SymbolTypes with inherited CPU-root CHashFun forward declaration, preserve root identity/opaque shape and persist Main export; not full provider self-build or module execution'}
    try:
        if any(len(s) > 255 for s, _ in COMMANDS):
            raise ValueError('Forward module fixture exceeds interactive line limit')
        runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(source, args.out/'behavior', snapshot=False,
            cpu='486,-fpu', qmp_stdio=True, startup_check={'status':'ok',
            'answers':[], 'commands':COMMANDS, 'command_timeout':60})
        build = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        files = build['mutated_file_contents'](source, {'/Probe/Inherited.HC','/Probe/Inherited.t32m'})
        expected = '#include "/Kernel/SymbolTypes.HH"\nI64 Main(){return sizeof(CHashFun); }\n'
        if files.get('/Probe/Inherited.HC') != expected.encode()+b'\x05':
            raise ValueError('Persisted module source differs')
        module = files['/Probe/Inherited.t32m']
        retained = runpy.run_path(str(ROOT/'tools/test-i386-retained-build.py'))
        _, exports = retained['exports_of'](module)
        if exports != ['Main']:
            raise ValueError('Unexpected forward module exports')
        report.update(result='pass', module_sha256=hashlib.sha256(module).hexdigest(), exports=exports)
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        report['source_disk_unchanged'] = sha(args.disk) == disk_hash
        if not report['source_disk_unchanged'] or sha(Path(__file__)) != checker:
            report.update(result='fail', error='Disk or checker changed during execution')
        (args.out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise SystemExit(1)


if __name__ == '__main__':
    main()
