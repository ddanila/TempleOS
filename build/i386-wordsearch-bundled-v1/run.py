import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import subprocess


parser=argparse.ArgumentParser()
parser.add_argument('disk',type=Path,nargs='?')
parser.add_argument('--reference',type=Path)
parser.add_argument('--out',type=Path,required=True)
args=parser.parse_args()
out=args.out.resolve()
out.mkdir()
fixture=Path(__file__).with_name('Probe.HC')
app=Path('Demo/WordSearch.HC')
helper=Path('tools/test-i386-autocomplete-interaction.py')
source_restore=Path('tools/test-i386-timeclock-reference.py')
packer=Path('tools/package-i386-native-image.py')
archive=Path('build/i386-autocomplete-archive-original/guest/ACWords.DATA.Z')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
pins={str(p):sha(p) for p in (fixture,app,helper,source_restore,packer,archive,Path(__file__))}
report={'result':'running','input_sha256':pins,
        'scope':'Seeded full WordSearch demo with the bundled dictionary, both searches, prompt recovery'}
guest=None
try:
    if args.disk:
        if not args.reference:
            raise ValueError('Native run requires the original reference')
        pins[str(args.disk)]=sha(args.disk)
        control=args.reference/'guest/wordsearch.dd'
        pins[str(control)]=sha(control)
        pack=runpy.run_path(str(packer))
        snapshot,package=pack['snapshot'],pack['package']
        image=out/'working.img'
        native=app.read_bytes()
        name='/Demo/WordSearch.HC'
        baseline=snapshot(args.disk.read_bytes())[1]
        if baseline[name][2]!=native:
            raise ValueError('Disk does not contain the production WordSearch source')
        report['packaging']=package(args.disk,image,additions={'/WordSearchProbe.HC':fixture.read_bytes()})
        delivered=snapshot(image.read_bytes())[1]
        if {path for path in delivered if baseline.get(path)!=delivered.get(path)}!={'/WordSearchProbe.HC'}:
            raise ValueError('Packaged tree differs outside the test observer')
        report['application_sha256']=hashlib.sha256(native).hexdigest()
    else:
        overlay=out/'overlay'
        runpy.run_path(str(source_restore))['restore_reference'](overlay)
        (overlay/'Adam/AutoComplete/ACWords.DATA.Z').write_bytes(archive.read_bytes())
        (overlay/'Once.HC').write_bytes(
            b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\nAdam("ACInit;");\n'+
            fixture.read_bytes()+b'\nWSBegin;\n#include "T:/Demo/WordSearch.HC"\nWSEnd;\n')
        image=out/'original.iso'
        subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),
                        '--output',str(image)],check=True)
    Guest=runpy.run_path(str(helper))['Guest']
    guest=Guest(image,out/'guest',bool(args.disk))
    if args.disk:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/WordSearchProbe.HC"')
        guest.command('WSBegin;')
        guest.command('#include "C:/Demo/WordSearch.HC"',timeout=600)
        guest.command('WSEnd;')
    guest.wait('WORD SEARCH captured\n',600)
    raw=(guest.out/'wordsearch.dd').read_bytes()
    match=re.search(rb'([A-Z]{20}\n){20}',raw)
    if not match:
        raise ValueError('Missing 20-by-20 seed grid in document output')
    output=raw[match.start():]
    if args.disk:
        suffix=b'> $PT$WSEnd;\n\x05'
        if not output.endswith(suffix):
            raise ValueError('Capture command echo does not have the expected suffix')
        output=output.removesuffix(suffix)+b'\x05'
    tokens=re.findall(rb'[A-Za-z]{3,}',raw[match.end():].split(b'> $PT$WSEnd;')[0])
    if not tokens:
        raise ValueError('No dictionary matches in the output')
    (out/'output.dd').write_bytes(output)
    if args.disk:
        original=control.read_bytes()
        original=original[re.search(rb'([A-Z]{20}\n){20}',original).start():]
        if output!=original:
            raise ValueError('Full demo output differs from original')
        guest.command('6*7;')
        report['fresh_result']=guest.result_pixels()
    report.update(result='pass',grid_rows=20,output_words=len(tokens),
                  output_sha256=sha(out/'output.dd'))
except Exception as error:
    report.update(result='fail',error=str(error))
    raise
finally:
    if guest:
        guest.close()
    report['inputs_unchanged']=all(sha(Path(name))==digest for name,digest in pins.items())
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
