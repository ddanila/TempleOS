#!/usr/bin/env python3
"""Check normal public compiler service caches in two first-use orders."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct

ROOT=Path(__file__).resolve().parents[1]
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--ram-mib',type=int,default=16);ap.add_argument('--reverse',action='store_true')
    args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir();fixture=ROOT/'tests/guest/i386-compiler-service-order/Contract.HC'
    paths=[Path(__file__).resolve(),fixture,args.disk.resolve()]
    paths += [ROOT/'tools'/n for n in ('test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','package-i386-native-image.py','build-i386-kernel.py')]
    for directory in ('Compiler','Kernel'):
        paths += sorted(p for p in (ROOT/directory).rglob('*') if p.is_file() and p.suffix in ('.HC','.HH'))
    pins={str(p):sha(p) for p in paths};g=None
    r=dict(result='running',input_sha256=pins,reverse=args.reverse,ram_mib=args.ram_mib,
           scope='Normal lexer/string, optimizer/backend and empty JIT/AOT fixups in one VM, two first-use orders and repeated calls; exact basic values and caller heaps, one publication per cache. This is service initialization integration, not relocation correctness, full compiler or concurrency/fault qualification.')
    try:
        pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
        before=pack['snapshot'](args.disk.read_bytes())[1];image=out/'working.img'
        code=b'#include "/Kernel/I386/PublicLexer.HH"\n#include "/Kernel/I386/PublicCompiler.HH"\n'
        if args.reverse:code+=b'#define PS_REVERSE 1\n'
        code+=fixture.read_bytes();additions={'/Probe/ServiceOrder.HC':code}
        (out/'fixture.HC').write_bytes(code);(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
        r['packaging']=pack['package'](args.disk.resolve(),image,additions=additions)
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g=Guest(image,out/'guest',True,ram_mib=args.ram_mib)
        g.wait('DONE native kernel startup\n');g.command('#include "C:/Probe/ServiceOrder.HC"',timeout=900)
        g.wait('PUBLIC SERVICES DONE\n',timeout=900)
        for name in ('service-state.bin','service-trace.bin','service-heap.bin'):
            (out/name).write_bytes((g.out/name).read_bytes())
        r['state']=list(struct.unpack('<8q',(out/'service-state.bin').read_bytes()))
        r['trace']=list(struct.unpack('<12q',(out/'service-trace.bin').read_bytes()))
        r['heaps']=list(struct.unpack('<2q',(out/'service-heap.bin').read_bytes()))
        assert r['state']==[1]*8,r['state']
        assert r['trace']==[42,5,42,10,1,17]*2,r['trace']
        assert r['heaps']==[0,0],r['heaps']
        text=g.collect();r['loads']={n:text.count('PUBLIC '+n+' loaded\n') for n in ('LEX','OPT','BACKEND','JIT')}
        assert list(r['loads'].values())==[1]*4,r['loads']
        g.command('6*7;');r['arithmetic_pixels']=g.result_pixels();g.close();g=None
        after=pack['snapshot'](image.read_bytes())[1]
        assert {n for n in set(before)|set(after) if before.get(n)!=after.get(n)}==set(additions)
        r['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        r['result']='pass'
    except BaseException as exc:
        r.update(result='fail',error=str(exc))
        if g:
            try:g.screenshot('failure')
            except Exception as cleanup_error:r['screenshot_error']=str(cleanup_error)
        raise
    finally:
        if g:
            try:g.close()
            except Exception as cleanup_error:r['cleanup_error']=str(cleanup_error)
        r['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not r['inputs_unchanged']:r.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(r,indent=2)+'\n')

if __name__=='__main__':main()
