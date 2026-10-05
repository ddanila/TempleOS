#!/usr/bin/env python3
"""Compare compiler includes after editing the original public resident cache."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
CODE = 'RootCacheValue=6*7;'
MUTATE = ('Bool MutateCode(U8 *name){CHashGeneric *e=HashFind(name,adam_task->hash_table,HTT_FILE);'
          'U8 *p;if(!e)return FALSE;if(e->user_data1!=19)return FALSE;p=e->user_data0;p[15]=55;return TRUE;}')
READ = ('Bool CachedCode(U8 *name){I64 n;U8 *p=FileRead(name,&n);'
        'Bool ok=p&&n==19&&p[15]==55;Free(p);return ok;}')
DOC = ('Bool CachedDoc(U8 *name){CDoc *d=DocRead(name);I64 n;U8 *p;Bool ok;'
       'if(!d)return FALSE;p=DocSave(d,&n);ok=p&&n>=19&&p[15]==55;Free(p);DocDel(d);return ok;}')
REMOVE = ('Bool RemoveCode(U8 *name){CHashGeneric *e=HashFind(name,adam_task->hash_table,HTT_FILE);'
          'if(!e)return FALSE;return HashRemDel(e,adam_task->hash_table);}')


def failure_layout(auditor, disk):
    paths = {'/Kernel/I386/Scheduler.HH', '/Kernel/I386/Context.HH', '/Kernel/I386/TaskFiles.HH'}
    sources = auditor['mutated_file_contents'](disk, paths)
    def clean(data):
        return re.sub(r'\s+', '', re.sub(r'//[^\n]*', '', data.decode('ascii')))
    expected = ('class CI386Task:CTask{CI386Context context;CI386Task *next,*last;'
                'CI386Scheduler *owner;U32 finished,blocked;CI386Task *join_head,*join_next,*join_target;'
                'CI386Heap *memory;U0 (*cleanup)(CI386Task *task);U32 finishing;'
                'CI386MsgQueue *messages;CI386Except *except_top;U32 io_locks;U8 *file_state;')
    files = ('class CI386TaskFiles{CI386Heap *heap;CI386Task *task;CFilePathContext *environment;'
             'CI386FileVolumes *volumes;U32 signature,bytes,busy;U8 drive;};')
    if (clean(expected.encode()) not in clean(sources.get('/Kernel/I386/Scheduler.HH', b'')) or
            'classCI386Context{U32esp;};' not in clean(sources.get('/Kernel/I386/Context.HH', b'')) or
            clean(files.encode()) not in clean(sources.get('/Kernel/I386/TaskFiles.HH', b''))):
        raise ValueError('Review allocation-failure observer: private file-state layout changed')
    return {name: hashlib.sha256(data).hexdigest() for name, data in sources.items()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--builder', type=Path, default=ROOT/'tools/build-i386-kernel.py',
                        help='Independent image auditor matching the candidate file ABI')
    parser.add_argument('--document', action='store_true', help='Also require DocRead to see the edited cache')
    parser.add_argument('--removal', action='store_true', help='Remove cache and require include to reload and repopulate from disk')
    parser.add_argument('--default-extension', action='store_true', help='Include a bare name and require original HC.Z default/alternate resolution')
    parser.add_argument('--allocation-failure', action='store_true', help='Native-only ABI-45 allocation failure and borrowed file-state recovery')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    candidate = out/'candidate.img'
    if candidate == args.disk.resolve():
        parser.error('output overlaps source')
    original = args.disk.read_bytes()
    auditor = runpy.run_path(str(args.builder.resolve()))
    layout = failure_layout(auditor, args.disk) if args.allocation_failure else None
    candidate.write_bytes(original)
    report = dict(result='fail', source_disk_sha256=hashlib.sha256(original).hexdigest(),
                  scope='Public cache source mutation must affect compiler #include; persisted source stays original')
    report['document'] = args.document
    report['removal'] = args.removal
    report['default_extension'] = args.default_extension
    report['allocation_failure'] = args.allocation_failure
    if layout:
        report['failure_layout_sources'] = layout
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
        if args.removal:
            oracle.insert(5, REMOVE)
            index = oracle.index('Report("DONE resident include\n");}')
            oracle[index:index] = [
                'if(!RemoveCode("B:/CacheInclude.HC")){Report("FAIL remove\n");return;}',
                'ExePutS("#include \\"B:/CacheInclude.HC\\";\\n");',
                'if(RootCacheValue!=42){Report("FAIL disk include\n");return;}',
                'if(!MutateCode("B:/CacheInclude.HC")||!CachedCode("B:/CacheInclude.HC")){Report("FAIL repopulate\n");return;}']
        #HolyC strings need literal escape sequences, not embedded line breaks.
        if args.default_extension:
            oracle = [line.replace('CacheInclude.HC', 'CacheInclude') if '#include' in line else line
                      for line in oracle]
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
        if args.removal:
            commands.insert(4, (REMOVE, []))
            commands += [('RemoveCode("C:/Probe/CacheInclude.HC");', ['1']),
                         ('#include "C:/Probe/CacheInclude.HC"', ['42']),
                         ('RootCacheValue;', ['42']),
                         ('MutateCode("C:/Probe/CacheInclude.HC");', ['1']),
                         ('CachedCode("C:/Probe/CacheInclude.HC");', ['1'])]
        runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        if args.default_extension:
            commands = [(source.replace('CacheInclude.HC', 'CacheInclude') if '#include' in source else source, answers)
                        for source, answers in commands]
        if args.allocation_failure:
            report['failure_scope'] = 'Native-only ABI-45: force public allocation rejection, restore cache metadata, require file-state busy zero'
            commands += [
                ('Bool CodeSize(I64 n){CHashGeneric *e=HashFind("C:/Probe/CacheInclude.HC",adam_task->hash_table,HTT_FILE);if(!e)return FALSE;e->user_data1=n;return TRUE;}', []),
                ('class CacheFailTask:CTask{U32 private_prefix[15];U8 *file_state;};', []),
                ('Bool CacheBorrowClear(){U8 *p=Fs(CacheFailTask *)->file_state;if(!p)return FALSE;return *(p+24)(U32 *)==0;}', []),
                ('sizeof(CTask)==992&&offset(CacheFailTask.file_state)==1052;', ['1']),
                ('CacheBorrowClear;', ['1']),
                ('CodeSize(0x100000000);', ['1']),
                ('#include "C:/Probe/CacheInclude.HC"', ['Out of memory']),
                ('CodeSize(19);', ['1']),
                ('CacheBorrowClear;', ['1']),
                ('#include "C:/Probe/CacheInclude.HC"', ['49'])]
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
