"""Check an unchanged RegistryDemo launch with a pre-existing custom score and value."""
import argparse
from pathlib import Path
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
parser.add_argument('--reference', type=Path)
args = parser.parse_args()
if bool(args.disk) != bool(args.reference):
    parser.error('Supply both --disk and --reference for the native run')

seed = ('RegDft("DemoCompany/Game1","F64 best_score=78.12500;\\n"); '
        'RegDft("DemoCompany/Game1/SimpleVal","31415;\\n");')
if args.disk:
    tool = Path('tools/test-i386-registry-demo.py').resolve()
    source = tool.read_text()
    start = "    ('F64 demo_before=tS;',[]),"
    assert source.count(start) == 1
    source = source.replace(start, "    ("+repr(seed)+",['0']),\n"+start)
    source = source.replace('1.23000', '78.12500').replace('1234', '31415').replace('1235', '31416')
    source = source.replace('fresh seeded defaults', 'pre-existing custom registry values')
    sys.argv = [str(tool), str(args.disk), '--out', str(args.out),
                '--reference', str(args.reference), '--require-bundled', '--managed-pointer']
else:
    tool = Path('tools/test-i386-registry-demo-reference.py').resolve()
    source = tool.read_text()
    fixture = Path(__file__).resolve().parent/'fixture'
    fixture.mkdir(exist_ok=True)
    original = Path('tests/guest/i386-registry-demo-reference/Once.HC').read_text()
    marker = 'F64 demo_before=tS;'
    assert original.count(marker) == 1
    (fixture/'Once.HC').write_text(original.replace(marker, seed+'\n'+marker))
    assignment = "fixture=ROOT/'tests/guest/i386-registry-demo-reference'"
    assert source.count(assignment) == 1
    source = source.replace(assignment, f'fixture=Path({str(fixture)!r})')
    source = source.replace('1.23000', '78.12500').replace('1234', '31415').replace('1235', '31416')
    source = source.replace('fresh seeded defaults', 'pre-existing custom registry values')
    sys.argv = [str(tool), '--out', str(args.out)]

exec(compile(source, str(tool), 'exec'), {'__file__': str(tool), '__name__': '__main__'})
