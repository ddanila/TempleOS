#!/usr/bin/env python3
"""Compare executable public expression APIs and final lexer state with the original system."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk', type=Path, nargs='?')
    ap.add_argument('--out', type=Path, required=True)
    ap.add_argument('--extended', action='store_true', help='Run the existing parser/type/lifetime/function/statement/stream contracts through normal native publication')
    args = ap.parse_args()
    if args.extended and not args.disk:
        ap.error('--extended requires a native image')
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-public-expression/Contract.HC'
    paths = [Path(__file__).resolve(), fixture] + [ROOT/('tools/'+name) for name in (
        'test-i386-autocomplete-interaction.py', 'test-i386-timeclock-reference.py',
        'test-i386-timeclock-welcome.py', 'build-iso.py',
        'package-i386-native-image.py', 'build-i386-kernel.py')]
    paths.append(ROOT/'Kernel/FontStd.HC')
    extended = [
        ('BinaryContract.HC','PUBLIC EXPRESSION BINARY DONE','public-expression-binary.bin',[1]*5),
        ('ParserGraph.HC','PUBLIC PARSER GRAPH DONE','public-parser-graph.bin',[63]),
        ('TypeContract.HC','PUBLIC TYPES DONE','public-types.bin',[1]*6),
        ('Runtime.HC','PUBLIC EXPRESSION RUNTIME DONE','public-expression-runtime.bin',[1]*11+[7,12,12,12,4615626668101337088,4612811918334230528,4612811918334230528,98,4617878467915022336,1<<40,98,1,1]),
        ('Lifetime.HC','PUBLIC EXPRESSION LIFETIME DONE','public-expression-lifetime-mask.bin',[15]),
        ('ClassContract.HC','PUBLIC CLASSES DONE','public-classes.bin',[1]*8),
        ('FunctionsContract.HC','PUBLIC FUNCTIONS DONE','public-functions.bin',[1]*7+[26,25,26,20,9,12,4615063718147915776,1,1]),
        ('StatementCompileContract.HC','PUBLIC STATEMENT COMPILE DONE','public-statement-compile.bin',[1]*10+[42,0x123456789ABCDEF,42,42,42,42,4615626668101337088,4615626668101337088]+[1]*4),
        ('ExecuteLineContract.HC','PUBLIC EXECUTE LINE DONE','public-execute-line.bin',[1]*16),
        ('../i386-public-compiler-stream/Contract.HC','PUBLIC COMPILER STREAM DONE','public-compiler-stream.bin',[1]*9),
    ] if args.extended else []
    for name,_,_,_ in extended:
        paths.append(fixture.parent/name)
    if args.disk:
        paths.append(args.disk.resolve())
        paths += sorted(p for directory in ('Compiler','Kernel') for p in (ROOT/directory).rglob('*') if p.is_file() and p.suffix in ('.HC','.HH'))
    out.mkdir()
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins,
                  scope='Actual original public LexExpression, LexExpressionI64 and LexExpressionF64: nine executable arithmetic/comparison/float cases and preserved final token/counters; native full parser/backend delivery remains open.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/PublicExpressions.HC': fixture.read_bytes()}
            additions.update({f'/Probe/Extended{i}.HC':(fixture.parent/name).read_bytes() for i,(name,_,_,_) in enumerate(extended)})
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(fixture.read_bytes())
            image = out/'original.iso'
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g = Guest(image, out/'guest', bool(args.disk), reference_cpus=1)
        if args.disk:
            g.wait('DONE native kernel startup\n')
            if 'PUBLIC PARSER loaded\n' in g.collect():
                raise ValueError('Parser loaded eagerly during normal startup')
            g.command('#include "C:/Probe/PublicExpressions.HC"')
        g.wait('PUBLIC EXPRESSION DONE\n')
        data=(g.out/'public-expression.bin').read_bytes()
        (out/'public-expression.bin').write_bytes(data)
        report['state']=list(struct.unpack('<18q',data))
        expected=[1]*9+[42,0x123456789ABCDEF,3,20,1,1,5,struct.unpack('<q',struct.pack('<d',7.0))[0],struct.unpack('<q',struct.pack('<d',3.75))[0]]
        if report['state']!=expected:raise ValueError('Expression result/control state differs: '+str(report['state']))
        if args.disk:
            report['extended_records']={}
            for i,(_,marker,filename,expected_records) in enumerate(extended):
                g.command(f'#include "C:/Probe/Extended{i}.HC"',timeout=240)
                g.wait(marker+'\n')
                data=(g.out/filename).read_bytes();(out/filename).write_bytes(data)
                records=list(struct.unpack('<'+'q'*len(expected_records),data))
                report['extended_records'][filename]=records
                if records!=expected_records:raise ValueError(filename+' differs: '+str(records))
            report['parser_publications']=g.collect().count('PUBLIC PARSER loaded\n')
            if report['parser_publications']!=1:raise ValueError('Expected one lazy parser publication')
            g.command('6*7;');report['arithmetic_pixels']=g.result_pixels()
        g.close()
        g = None
        if args.disk:
            after = pack['snapshot'](image.read_bytes())[1]
            if {n for n in set(before)|set(after) if before.get(n)!=after.get(n)} != set(additions):
                raise ValueError('Unexpected filesystem changes')
            report['filesystem'] = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        report['result'] = 'pass'
    except BaseException as exc:
        report.update(result='fail',error=str(exc))
        if g:g.screenshot('failure')
        raise
    finally:
        if g:
            try:
                g.close()
            except Exception as exc:
                report.update(result='fail',cleanup_error=str(exc))
        report['inputs_unchanged'] = all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:
            report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__ == '__main__':
    main()
