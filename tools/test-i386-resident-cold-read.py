#!/usr/bin/env python3
"""Original-oracle resident disk read followed by cached owned reads."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path, help='Bootable image with /Probe/ReadResident.BIN containing A,NUL,B,255 and resident metadata')
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--compressed', action='store_true', help='Require a resident .Z fixture containing the 64-byte ReadPackedBytes seed')
    parser.add_argument('--shared-lifetime', action='store_true', help='Require cache reuse across child task exit and directory-state replacement')
    parser.add_argument('--hash-visible', action='store_true', help='Require original public HTT_FILE cache visibility through Fs hash-table chain')
    parser.add_argument('--hash-removal', action='store_true', help='Remove the public cache entry and require a fresh disk read and repopulation')
    parser.add_argument('--prepare-fixture', action='store_true', help='Populate resident bytes on the disposable candidate before a separate cold boot')
    parser.add_argument('--empty', action='store_true', help='Qualify zero-byte resident files and their cache entries')
    parser.add_argument('--dotless', action='store_true', help='Use a filename without an extension and require its exact public cache key')
    parser.add_argument('--adam-root', action='store_true', help='Require the original adam_task global and its ownership of public cache allocations')
    args = parser.parse_args()
    if args.adam_root and not args.hash_visible:
        parser.error('--adam-root requires --hash-visible')
    if args.empty and (args.compressed or args.shared_lifetime):
        parser.error('--empty cannot combine with --compressed or --shared-lifetime')
    if args.hash_removal and not args.hash_visible:
        parser.error('--hash-removal requires --hash-visible')
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    candidate = out/'candidate.img'
    if candidate == args.disk.resolve():
        parser.error('output overlaps source')
    original = args.disk.read_bytes()
    candidate.write_bytes(original)
    report = dict(result='fail', source_disk_sha256=hashlib.sha256(original).hexdigest(),
                  scope='Resident disk population, first disk attributes then cached attributes, fresh owned reads')
    definitions = runpy.run_path(str(ROOT/'tools/test-i386-public-file-read.py'))['DEFINITIONS']
    selected = [definitions[0], definitions[2], definitions[4]]
    filename = 'ReadResident.BIN'
    checks = ['ReadCheck("C:/Probe/ReadResident.BIN",0xA00)',
              'ReadCheck("C:/Probe/ReadResident.BIN",0)',
              'ReadOwned("C:/Probe/ReadResident.BIN")']
    setup_buffer, setup_size = 'ReadBytes', 4
    if args.compressed:
        filename += '.Z'
        setup_buffer, setup_size = 'ReadPackedBytes', 64
        selected = [definitions[0],definitions[1],definitions[4],
                    'Bool ColdPacked(U8 *name,I64 attr){I64 n=-1,a=-1;U8 *p=FileRead(name,&n,&a);Bool ok=p&&n==64&&a==attr&&p[0]==65&&p[1]==0&&p[2]==255&&p[63]==65&&p[64]==0;Free(p);return ok;}']
        checks = ['ColdPacked("C:/Probe/ReadResident.BIN.Z",0xE00)',
                  'ColdPacked("C:/Probe/ReadResident.BIN.Z",0x400)',
                  'ColdPacked("C:/Probe/ReadResident.BIN",0x400)',
                  'ReadOwned("C:/Probe/ReadResident.BIN.Z")']
    if args.empty:
        setup_buffer, setup_size = '0', 0
        selected = [definitions[0],
                    'Bool ColdEmpty(U8 *name,I64 attr){I64 n=-1,a=-1;U8 *p=FileRead(name,&n,&a);Bool ok=p&&n==0&&a==attr&&p[0]==0;Free(p);return ok;}',
                    'Bool ColdOwnedEmpty(U8 *name){U8 *p=FileRead(name),*q=FileRead(name);Bool ok=p&&q&&p!=q&&MHeapCtrl(p)==Fs->data_heap&&MHeapCtrl(q)==Fs->data_heap;if(ok){p[0]=90;ok=q[0]==0;}Free(p);Free(q);return ok;}']
        checks = ['ColdEmpty("C:/Probe/ReadResident.BIN",0xA00)',
                  'ColdEmpty("C:/Probe/ReadResident.BIN",0)',
                  'ColdOwnedEmpty("C:/Probe/ReadResident.BIN")']
    if args.dotless:
        filename = filename.replace('.BIN', '')
        checks = [check.replace('ReadResident.BIN', 'ReadResident') for check in checks]
    report['dotless'] = args.dotless
    report['empty'] = args.empty
    report['prepare_fixture'] = args.prepare_fixture
    report['compressed'] = args.compressed
    report['shared_lifetime'] = args.shared_lifetime
    report['hash_visible'] = args.hash_visible
    report['adam_root'] = args.adam_root
    report['hash_removal'] = args.hash_removal
    if args.hash_visible:
        selected += ['Bool ColdHash(U8 *name){CHashGeneric *e=HashFind(name,Fs->hash_table,HTT_FILE);if(!e)return FALSE;if(!e->user_data0||e->user_data1<0)return FALSE;return MHeapCtrl(e)&&MHeapCtrl(e->str)&&MHeapCtrl(e->user_data0); }']
        checks += [f'ColdHash("C:/Probe/{filename}")']
    if args.adam_root:
        selected += ['Bool ColdAdamOwn(U8 *p){return MHeapCtrl(p)==adam_task->data_heap;}',
                     'Bool ColdRoot(U8 *name){CHashGeneric *e=HashFind(name,adam_task->hash_table,HTT_FILE);if(!e)return FALSE;return ColdAdamOwn(e)&&ColdAdamOwn(e->str)&&ColdAdamOwn(e->user_data0); }']
        checks += [f'ColdRoot("C:/Probe/{filename}")']
    if args.hash_removal:
        selected += ['CHashTable *ColdOwner(CHash *e){CHashTable *t=Fs->hash_table;CHash *p;I64 i;while(t){for(i=0;i<=t->mask;i++){p=t->body[i];while(p){if(p==e)return t;p=p->next;}}t=t->next;}return 0;}',
                     'Bool ColdRemove(U8 *name){CHash *e=HashFind(name,Fs->hash_table,HTT_FILE);CHashTable *t;if(!e)return FALSE;t=ColdOwner(e);if(!t)return FALSE;HashRemDel(e,t);return !HashFind(name,Fs->hash_table,HTT_FILE); }']
        selected += ['Bool ColdKeep(U8 *name){CHash *e=HashFind(name,Fs->hash_table,HTT_FILE);CHashTable *t=ColdOwner(e);if(!e||!t)return FALSE;return !HashRemDel(e,t,0)&&!HashRemDel(e,t,2)&&HashFind(name,Fs->hash_table,HTT_FILE)==e;}']
        fresh = checks[0]
        cached = checks[1]
        checks += [f'ColdKeep("C:/Probe/{filename}")', f'ColdRemove("C:/Probe/{filename}")', fresh, cached, f'ColdHash("C:/Probe/{filename}")']
    if args.shared_lifetime:
        cached_check = checks[1]
        owned_check = f'ReadOwned("C:/Probe/{filename}")'
        selected += ['I64 ColdTaskResult=0;',
                     'U0 ColdTask(U8 *data){if('+cached_check+'&&'+owned_check+')ColdTaskResult=1;else ColdTaskResult=2;}',
                     'Bool ColdChild(){I64 end=cnts.jiffies+2000;ColdTaskResult=0;if(!Spawn(&ColdTask,0,"ColdRead",-1,Fs,8192))return FALSE;while(!ColdTaskResult&&cnts.jiffies<end)Yield;Yield;return ColdTaskResult==1;}']
        checks += ['ColdChild','Cd("C:/Probe")',cached_check,'Cd("C:/")',cached_check]
    if args.hash_visible:
        checks.insert(1, f'ColdHash("C:/Probe/{filename}")')
    if args.adam_root:
        checks.insert(2, f'ColdRoot("C:/Probe/{filename}")')
    try:
        for source in selected:
            if len(source) > 255:
                raise ValueError(f'Native helper exceeds 255-byte input limit: {source[:40]}')
        overlay = out/'overlay'
        overlay.mkdir(exist_ok=True)
        lines = ['U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}']+[s.replace('C:/Probe/','B:/') for s in selected]
        lines += ['U0 ColdReads(){U8 *name;CHashGeneric *entry;']
        if args.compressed:lines.append('ReadSeed;')
        bad_write = '!=-1' if args.empty else '<=0'
        lines += [f'if(FileWrite("B:/{filename}",{setup_buffer},{setup_size},0x1122334455667788,0x200){bad_write}){{Report("FAIL setup\\n");return;}}',
                  f'name=FileNameAbs("B:/{filename}");entry=HashFind(name,adam_task->hash_table,HTT_FILE);Free(name);',
                  'if(!entry){Report("FAIL resident cache setup\\n");return;}HashRemDel(entry,adam_task->hash_table);']
        for index, check in enumerate(checks):
            check=check.replace('C:/Probe/','B:/').replace('"C:/Probe"','"B:/"').replace('"C:/"','"B:/"')
            lines.append('if(!('+check+')){Report("FAIL cold case '+str(index)+'\\n");return;}')
        lines += ['Report("DONE cold resident\\n");}', 'ColdReads;']
        (overlay/'Once.HC').write_text('\n'.join(lines)+'\n')
        subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(out/'oracle.iso')], cwd=ROOT, check=True)
        subprocess.run(['python3','tools/guest-run.py',str(out/'oracle.iso'),'--out',str(out/'oracle'),'--timeout','180','--qmp-stdio'], cwd=ROOT, check=True)
        report['original_oracle'] = 'pass'
        if args.prepare_fixture:
            prepare = [(source,[]) for source in definitions[:2]]
            if args.compressed:
                prepare += [('ReadSeed;',[])]
            good_write = '==-1' if args.empty else '>0'
            prepare += [(f'FileWrite("C:/Probe/{filename}",{setup_buffer},{setup_size},0x1122334455667788,0x200){good_write};',['1'])]
            prepare_runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
            report['fixture_preparation'] = prepare_runner(candidate,out/'fixture-preparation',snapshot=False,
                cpu='486,-fpu',qmp_stdio=True,startup_check={'status':'ok','answers':[],'commands':prepare})
        cold_baseline = candidate.read_bytes()
        report['cold_fixture_sha256'] = hashlib.sha256(cold_baseline).hexdigest()
        commands = [(source,[]) for source in selected]+[(check+';',['1']) for check in checks]+[('6*7;',['42'])]
        runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(candidate,out/'behavior',snapshot=False,cpu='486,-fpu',qmp_stdio=True,
                                   startup_check={'status':'ok','answers':[],'commands':commands})
        if candidate.read_bytes() != cold_baseline:
            raise ValueError('Read-only cold cache contract changed disk bytes')
        report['candidate_disk_unchanged'] = True
        report['result'] = 'pass'
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        report['source_disk_unchanged'] = args.disk.read_bytes() == original
        if not report['source_disk_unchanged']:
            report.update(result='fail',error='Source changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__ == '__main__':
    main()
