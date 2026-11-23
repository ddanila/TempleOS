import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess


parser = argparse.ArgumentParser()
parser.add_argument('disk', type=Path, nargs='?')
parser.add_argument('--port', action='store_true')
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
fixture = Path(__file__).with_name('Probe.HC')
application = Path('Demo/WordSearch.HC')
helper = Path('tools/test-i386-autocomplete-interaction.py')
reference = Path('tools/test-i386-timeclock-reference.py')
packer = Path('tools/package-i386-native-image.py')
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
inputs = [fixture,application,helper,reference,packer,Path(__file__)]
if args.disk:
    inputs.append(args.disk)
pins = {str(p):sha(p) for p in inputs}
report = {'result':'running','input_sha256':pins,'port':args.port,
          'scope':'Bundled WordSearch eight-direction collection and fixed-width pointer sort'}
source = application.read_bytes()
assert source.endswith(b'\nWordSearch;\n')
source = source.removesuffix(b'WordSearch;\n')
if args.port:
    edits = [
        (b'U8 *word_ptrs[',b'I64 word_ptrs['),
        (b'word_ptrs[n]=&words[n];',b'word_ptrs[n]=(&words[n])(I64);'),
        (b'w1=word_ptrs[i];',b'w1=word_ptrs[i](U8 *);'),
        (b'StrNICmp(word_ptrs[k++],',b'StrNICmp(word_ptrs[k++](U8 *),'),
    ]
    for old, new in edits:
        assert source.count(old)==1
        source=source.replace(old,new)
source += fixture.read_bytes()
guest = None
try:
    if args.disk:
        image=out/'working.img'
        pack=runpy.run_path(str(packer))
        delivered=pack['snapshot'](args.disk.read_bytes())[1]
        assert delivered['/Demo/WordSearch.HC'][2] == application.read_bytes()
        report['packaging']=pack['package'](args.disk,image,additions={'/WordSearchProbe.HC':source})
    else:
        overlay=out/'overlay'
        runpy.run_path(str(reference))['restore_reference'](overlay)
        (overlay/'Once.HC').write_bytes(
            b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+source+b'\nWordSearchProbe;\n')
        image=out/'original.iso'
        subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),
                        '--output',str(image)],check=True)
    Guest=runpy.run_path(str(helper))['Guest']
    guest=Guest(image,out/'guest',bool(args.disk))
    if args.disk:
        guest.wait('DONE native kernel startup\n')
        guest.command('AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);')
        guest.command('#include "C:/WordSearchProbe.HC"')
        guest.type('WordSearchProbe;')
        guest.press('ret')
    guest.wait('WORD SEARCH sorted\n',35)
    expected=[]
    for dx,dy in ((1,0),(0,1),(-1,0),(0,-1),(1,1),(-1,-1),(1,-1),(-1,1)):
        for y in range(20):
            for x in range(20):
                word=bytearray()
                row,column=y,x
                while 0<=row<20 and 0<=column<20:
                    word.append(65+(column*3+row*5)%26)
                    row+=dy
                    column+=dx
                expected.append(bytes(word))
    records=b''.join(word.ljust(21,b'\0') for word in sorted(expected))
    actual=(guest.out/'words.bin').read_bytes()
    if records!=actual:
        raise ValueError('Sorted word values differ from independent expected grid')
    report.update(result='pass',words=len(expected),word_sha256=hashlib.sha256(actual).hexdigest())
    if args.disk:
        guest.command('6*7;')
        report['fresh_result']=guest.result_pixels()
except Exception as exc:
    report.update(result='fail',error=str(exc))
    raise
finally:
    if guest:
        guest.close()
    report['inputs_unchanged']=all(sha(Path(n))==v for n,v in pins.items())
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
