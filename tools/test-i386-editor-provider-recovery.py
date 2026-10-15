#!/usr/bin/env python3
"""Reject optional editor modules, repair in guest, retry, and prove cached reuse."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct

ROOT = Path(__file__).resolve().parents[1]
PROVIDER = '/Modules/I386/EditorRuntime.t32m'

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--fault', choices=('wrong-target', 'wrong-version', 'missing-import'), required=True)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    if out.exists(): parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    build = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
    find_record = runpy.run_path(str(ROOT/'tools/test-i386-public-file-write.py'))['find_record']
    module = build['mutated_file_contents'](source, {PROVIDER})[PROVIDER]
    records = []
    count, table = struct.unpack_from('<II', module, 20)
    for i in range(count):
        kind, offset, name, length = struct.unpack_from('<4I', module, table+16*i)
        records.append((kind, offset, module[name:name+length], table+16*i))
    if args.fault == 'wrong-target':
        position, bad = 6, 4
        if module[position] != 3: raise ValueError('Not an i386 editor module')
    elif args.fault == 'wrong-version':
        position = 32+next(offset for kind, offset, name, _ in records if kind == 3 and name == b'editor_version')
        bad = 2
        if module[position] != 1: raise ValueError('Unexpected editor version')
    else:
        position = next(record for kind, _, name, record in records if kind == 1 and name == b'StrFind')
        bad = 2  #An unresolved import record, with no matching binding.
    changed = bytearray(source.read_bytes())
    entry = find_record(source, PROVIDER)
    changed[entry['block']*512+position] = bad
    working = out/'working.img'
    working.write_bytes(changed)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in (source, Path(__file__).resolve(), ROOT/'tools/i386-kernel-input.py',
                                    ROOT/'tools/build-i386-kernel.py', ROOT/'tools/test-i386-public-file-write.py')}
    patch = ('Bool ERPatch(I64 v){I64 n=0;U8*p=FileRead("C:'+PROVIDER+'",&n);'
             f'Bool ok=p&&n=={len(module)};if(ok){{p[{position}]=v;'
             'ok=FileWrite("C:'+PROVIDER+'",p,n)>0;}Free(p);return ok;}')
    commands = [
        ('U8*er_dir;CDoc*er_put,*er_display;I64 er_border;', []),
        ('Bool ERSetup(){Bool ok=Cd("C:/Probe");er_dir=FileNameAbs("EditorProbe.HC");er_put=DocPut;er_display=DocDisplay;er_border=Fs->border_src;return ok;}ERSetup;', ['1']),
        ('I64 ERReject(){I64 n=Fs->data_heap->used_u8s;Bool hit=FALSE;try{StrFind("cat","cat");}catch{if(Fs->except_ch==\'Editor\'){Fs->catch_except=TRUE;hit=TRUE;}}return hit&&Fs->data_heap->used_u8s==n;}', []),
        ('Bool ERDir(){U8*p=FileNameAbs("EditorProbe.HC");Bool ok=!StrCmp(p,er_dir);Free(p);return ok;}', []),
        (patch, []), ('Bool ERUse(){U8*s="xxcat";return StrFind("cat",s)==s+2;}', []),
        ('ERReject();', ['1']), ('ERReject();', ['1']), ('ERDir();', ['1']),
        ('DocPut==er_put&&DocDisplay==er_display&&Fs->border_src==er_border;', ['1']), ('6*7;', ['42']),
        (f'ERPatch({module[position]});', ['1']), ('ERUse();', ['1']), ('ERUse();', ['1']),
        (f'ERPatch({bad});', ['1']), ('ERUse();', ['1']), (f'ERPatch({module[position]});', ['1']),
        ('ERDir();', ['1']), ('DocPut==er_put&&DocDisplay==er_display&&Fs->border_src==er_border;', ['1']),
        ('Bool ERClean(){Free(er_dir);return Cd("C:/");}ERClean;', ['1']), ('6*7;', ['42'])]
    if any(len(command)>255 for command, _ in commands): raise ValueError('Editor recovery command exceeds input limit')
    report = dict(result='running', fault=args.fault, mutation_offset=position, input_sha256=pins,
                  scope='Repeated rejection, guest repair/retry, cached reuse after on-disk corruption, exact restored module, caller heap/directory/document roles; not complete cancellation/lifetime qualification', commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64, cpu='486,-fpu', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'command_timeout':120, 'rejection_prefixes':('INPUT REJECT ',)})
        log = (out/'qemu/debug.log').read_text()
        if log.count('EDITOR loaded ') != 1 or 'EDITOR loaded ' in log[:log.index('INPUT LINE ERUse();')]:
            raise ValueError('Only the repaired first use may publish the editor provider')
        if build['mutated_file_contents'](working, {PROVIDER})[PROVIDER] != module:
            raise ValueError('Guest repair differs from original provider bytes')
        report.update(result='pass', rejected_attempts=2, successful_invocations=3,
                      provider_loads=1, provider_restored_byte_identically=True)
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == digest for p, digest in pins.items())
        if not report['inputs_unchanged']: report.update(result='fail', error='Editor recovery inputs changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')

if __name__ == '__main__': main()
