#!/usr/bin/env python3
"""Initialize unchanged autocomplete, read dictionary results, stop and restart it."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import struct
import sys
ROOT=Path(__file__).resolve().parents[1]

def verify_dictionary(data,words,definitions):
    pos=count=0;selected={};wanted={b'apple',b'temple',b'computer'}
    while pos<len(words):
        if pos==len(words)-1 and words[pos]==0:
            pos+=1;break
        if words[pos]==0:
            if words[pos:pos+3]!=b'\0'*3:raise ValueError('Invalid dictionary padding')
            pos+=3;continue
        if words[pos]!=1:raise ValueError('Missing dictionary word marker')
        end=words.index(0,pos+1);name=words[pos+1:end]
        block=struct.unpack_from('<H',words,end+1)[0]
        if block*16384>=len(definitions):raise ValueError('Dictionary block outside definitions')
        if name.lower() in wanted:selected[name.lower()]=(name,block)
        pos=end+3;count+=1
    if pos!=len(words) or set(selected)!=wanted:raise ValueError('Invalid dictionary word inventory')
    expected=bytearray(f'WORDS {count} BYTES {len(words)}\n'.encode());records={}
    for query in (b'apple',b'temple',b'computer'):
        name,block=selected[query];start=definitions.index(b'\x01'+name+b'\0')
        end=definitions.index(b'\x01',start+1)
        if not block*16384<=start<end<(block+2)*16384:raise ValueError('Definition outside its indexed two-block window')
        record=definitions[start:end]+b'\0';cursor=len(name)+2;items=[]
        while record[cursor]:
            kind=record[cursor]
            if not 2<=kind<=5:raise ValueError('Invalid definition field')
            finish=record.index(0,cursor+1)
            if kind==2:items.append(record[cursor+1:finish])
            cursor=finish+1
        if cursor!=len(record)-1 or not items:raise ValueError('Invalid definition record termination')
        expected+=b'WORD '+query+b'\n'
        second=None
        if len(items)>1:second=items[1]
        for label,value in ((b'FIRST',items[0]),(b'SECOND',second),(b'ALL',record)):
            size=-1 if value is None else len(value)
            expected+=label+b' '+str(size).encode()+b'\n'+(value or b'')+b'\n'
        records[query.decode()]=dict(definitions=len(items),record_bytes=len(record))
    if bytes(expected)!=data:raise ValueError('Runtime dictionary output differs from independent pinned-asset decoder')
    return dict(words=count,word_bytes=len(words),report_bytes=len(data),records=records)

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--archive',type=Path,default=ROOT/'build/i386-autocomplete-archive-original');ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-autocomplete-dictionary/Contract.HC';archive=args.archive.resolve()/'guest/ACWords.DATA.Z';archive_report=args.archive.resolve()/'result.json';inventory=ROOT/'docs/i386-compatibility-inventory.json'
    paths=[Path(__file__).resolve(),fixture,archive,archive_report,inventory]+[ROOT/p for p in ['tools/build-iso.py','tools/guest-run.py','tools/build-i386-kernel.py','tools/package-i386-native-image.py','tools/test-i386-timeclock-welcome.py','Kernel/FontStd.HC','Adam/AutoComplete/ACWords.DATA','Adam/AutoComplete/ACDefs.DATA','Adam/AutoComplete/MakeAC.HC','Adam/AutoComplete/ACFill.HC','Adam/AutoComplete/ACTask.HC','Adam/AutoComplete/ACInit.HC']]
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    info=json.loads(archive_report.read_text())
    if info.get('result')!='pass' or not info.get('inputs_unchanged') or info.get('archive_sha256')!=sha(archive):raise ValueError('Qualified original word archive required')
    expected_assets={e['path']:e['reference_sha256'] for e in json.loads(inventory.read_text())['entries'] if e['path'] in ('Adam/AutoComplete/ACWords.DATA','Adam/AutoComplete/ACDefs.DATA')}
    if len(expected_assets)!=2 or any(sha(ROOT/name)!=digest for name,digest in expected_assets.items()):raise ValueError('Dictionary source differs from pinned original')
    if args.disk:
        if not args.reference:ap.error('Native run needs a passed --reference directory')
        gold=args.reference.resolve();gold_report=json.loads((gold/'result.json').read_text())
        if gold_report.get('result')!='pass' or not gold_report.get('inputs_unchanged'):raise ValueError('Passed original reference required')
        paths += [args.disk.resolve(),gold/'result.json',gold/'ACDictionary.DATA']
    else:
        manifest=ROOT/'build/rebuild-test/result.json';snapshot=json.loads(manifest.read_text())
        if snapshot.get('result')!='pass':raise ValueError('Qualified original rebuild required')
        paths.append(manifest)
        for name,relative in [('Kernel.BIN','0000Boot/0000Kernel.BIN.C'),('Compiler.BIN','Compiler/Compiler.BIN')]:
            p=ROOT/'build/rebuild-test/overlay'/relative
            if sha(p)!=snapshot['generations'][-1][name]:raise ValueError('Rebuild binary mismatch')
            paths.append(p)
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',mode='native' if args.disk else 'rebuilt-original',input_sha256=pins,scope='Actual unchanged ACInit with pinned dictionaries, live autocomplete task, full word loading and accounting, three exact first/second/all-definition lookups and word pointers, missing lookup, stop/reinitialize/stop lifecycle. Not source-statistics traversal, visible suggestions/selection, exact app heap recovery or full desktop qualification.')
    try:
        if args.disk:
            image=out/'working.img';packer=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            _,files,_=packer['snapshot'](args.disk.read_bytes())
            if files['/Adam/AutoComplete/ACDefs.DATA'][2]!=(ROOT/'Adam/AutoComplete/ACDefs.DATA').read_bytes():raise ValueError('Candidate definitions differ')
            additions={'/ACDictionaryContract.HC':fixture.read_bytes(),'/Adam/AutoComplete/ACWords.DATA.Z':archive.read_bytes()}
            report['packaging']=packer['package'](args.disk.resolve(),image,additions=additions,addition_attributes={'/Adam/AutoComplete/ACWords.DATA.Z':0xC00})
            commands=['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/ACDictionaryContract.HC",FALSE);','Adam("ACDictionaryStart;");','Adam("ACDictionaryWrite;");','Adam("ACDictionaryCycle;");','6*7;']
            runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](image,out/'guest',commands,64,True,command_timeout=1800,accel='kvm')
            build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'));data=build['mutated_file_contents'](image,{'/ACDictionary.DATA'})['/ACDictionary.DATA']
            if data!=(gold/'ACDictionary.DATA').read_bytes():raise ValueError('Dictionary output differs from original')
            report['filesystem_integrity']=build['verify_mutated_volume'](image)
            (out/'ACDictionary.DATA').write_bytes(data)
        else:
            overlay=out/'overlay';(overlay/'Adam/AutoComplete').mkdir(parents=True)
            (overlay/'Adam/AutoComplete/ACWords.DATA.Z').write_bytes(archive.read_bytes());(overlay/'ACDictionaryContract.HC').write_bytes(fixture.read_bytes())
            source=b'U0 ACDOuterLog(U8*s){while(*s)OutU8(0xE9,*s++); }\nwhile(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\nAdamFile("T:/ACDictionaryContract.HC",FALSE);\nAdam("ACDictionaryStart;");\nAdam("ACDictionaryExport;");\nAdam("ACDictionaryCycle;");\nACDOuterLog("DONE autocomplete dictionary\\n");\n'
            (overlay/'Once.HC').write_bytes(source);iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay','build/rebuild-test/overlay','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','600'],cwd=ROOT,check=True)
            if 'AC DICTIONARY fixture loaded\n' not in (out/'guest/debug.log').read_text():raise ValueError('Dictionary fixture did not load completely')
            data=(out/'guest/ACDictionary.DATA').read_bytes();(out/'ACDictionary.DATA').write_bytes(data)
        report['independent_dictionary']=verify_dictionary(data,(ROOT/'Adam/AutoComplete/ACWords.DATA').read_bytes(),(ROOT/'Adam/AutoComplete/ACDefs.DATA').read_bytes())
        log=(out/'guest/debug.log').read_text()
        if 'PASS autocomplete dictionary\n' not in log or log.count('AC DICTIONARY ready ')!=2 or log.count('AC DICTIONARY stopped\n')!=2:raise ValueError('Dictionary lifecycle did not complete')
        report.update(result='pass',dictionary_sha256=hashlib.sha256(data).hexdigest(),dictionary_bytes=len(data),observations=[line for line in log.splitlines() if line.startswith('AC DICTIONARY ')])
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
