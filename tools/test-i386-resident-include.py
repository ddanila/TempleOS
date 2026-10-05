#!/usr/bin/env python3
"""Compare compiler includes after editing the original public resident cache."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess

ROOT = Path(__file__).resolve().parents[1]
CODE = 'RootCacheValue=6*7;'
MUTATE = ('Bool MutateCode(U8 *name){CHashGeneric *e=HashFind(name,adam_task->hash_table,HTT_FILE);'
          'U8 *p;if(!e)return FALSE;if(e->user_data1!=19)return FALSE;p=e->user_data0;p[15]=55;return TRUE;}')
READ = ('Bool CachedCode(U8 *name){I64 n;U8 *p=FileRead(name,&n);'
        'Bool ok=p&&n==19&&p[15]==55;Free(p);return ok;}')
DOC = ('Bool CachedDoc(U8 *name){CDoc *d=DocRead(name);I64 n;U8 *p;Bool ok;'
       'if(!d)return FALSE;p=DocSave(d,&n);ok=p&&n>=19&&p[15]==55;Free(p);DocDel(d);return ok;}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--builder', type=Path, default=ROOT/'tools/build-i386-kernel.py',
                        help='Independent image auditor matching the candidate file ABI')
    parser.add_argument('--document', action='store_true', help='Also require DocRead to see the edited cache')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    candidate = out/'candidate.img'
    if candidate == args.disk.resolve():
        parser.error('output overlaps source')
    original = args.disk.read_bytes()
    auditor = runpy.run_path(str(args.builder.resolve()))
    candidate.write_bytes(original)
    report = dict(result='fail', source_disk_sha256=hashlib.sha256(original).hexdigest(),
                  scope='Public cache source mutation must affect compiler #include; persisted source stays original')
    report['document'] = args.document
    try:
        overlay = out/'overlay'
        overlay.mkdir(exist_ok=True)
        oracle = ['U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}',
                  'I64 RootCacheValue=0;', f'U8 *CacheCode=StrNew("{CODE}");', MUTATE, READ,
                  'U0 IncludeCache(){',
                  'if(FileWrite("B:/CacheInclude.HC",CacheCode,19,0x1122334455667788,0x200)<=0){Report("FAIL write\n");return;}',
                  'if(!MutateCode("B:/CacheInclude.HC")||!CachedCode("B:/CacheInclude.HC")){Report("FAIL public mutation\n");return;}',
                  'ExePutS("#include \\"B:/CacheInclude.HC\\";\\n");',
                  'if(RootCacheValue!=49){Report("FAIL cached include\n");return;}',
                  'Report("DONE resident include\n");}', 'IncludeCache;']
        if args.document:
            oracle.insert(5, DOC)
            oracle.insert(oracle.index('ExePutS("#include \\"B:/CacheInclude.HC\\";\\n");'),
                          'if(!CachedDoc("B:/CacheInclude.HC")){Report("FAIL cached document\n");return;}')
        #HolyC strings need literal escape sequences, not embedded line breaks.
        oracle = [line.replace('\n', '\\n') for line in oracle]
        (overlay/'Once.HC').write_text('\n'.join(oracle)+'\n')
        subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                        '--output', str(out/'oracle.iso')], cwd=ROOT, check=True)
        subprocess.run(['python3', 'tools/guest-run.py', str(out/'oracle.iso'),
                        '--out', str(out/'oracle'), '--timeout', '180', '--qmp-stdio'], cwd=ROOT, check=True)
        report['original_oracle'] = 'pass'
        commands = [('I64 RootCacheValue=0;', []), (f'U8 *CacheCode=StrNew("{CODE}");', []),
                    (MUTATE, []), (READ, []),
                    ('FileWrite("C:/Probe/CacheInclude.HC",CacheCode,19,0x1122334455667788,0x200)>0;', ['1']),
                    ('MutateCode("C:/Probe/CacheInclude.HC");', ['1']),
                    ('CachedCode("C:/Probe/CacheInclude.HC");', ['1']),
                    ('#include "C:/Probe/CacheInclude.HC"', ['49']),
                    ('RootCacheValue;', ['49'])]
        if args.document:
            commands.insert(4, (DOC, []))
            commands.insert(-2, ('CachedDoc("C:/Probe/CacheInclude.HC");', ['1']))
        runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(candidate, out/'behavior', snapshot=False, cpu='486,-fpu',
                                   qmp_stdio=True, startup_check={'status': 'ok', 'answers': [], 'commands': commands})
        report['result'] = 'pass'
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        try:
            report['volume_audit'] = auditor['verify_mutated_volume'](candidate)
            persisted = auditor['mutated_file_contents'](candidate, {'/Probe/CacheInclude.HC'})
            report['persisted_source_unchanged'] = persisted.get('/Probe/CacheInclude.HC') == CODE.encode('ascii')
            if not report['persisted_source_unchanged']:
                raise ValueError('Persisted include source differs from the original fixture')
        except Exception as audit_error:
            report.update(result='fail', audit_error=str(audit_error))
        report['source_disk_unchanged'] = args.disk.read_bytes() == original
        if not report['source_disk_unchanged']:
            report.update(result='fail', error='Source changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
        if 'audit_error' in report or not report['source_disk_unchanged']:
            raise RuntimeError(report.get('audit_error', 'Source changed'))


if __name__ == '__main__':
    main()
