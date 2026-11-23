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
        control=args.reference/'output.json'
        pins[str(control)]=sha(control)
        pack=runpy.run_path(str(packer))
        snapshot,package=pack['snapshot'],pack['package']
        image=out/'working.img'
        native=app.read_bytes()
        prefix=b'''if(!HashFind("ACInit",adam_task->hash_table,HTT_FUN))
  AdamFile("/Adam/AutoComplete/MakeAC.HC",FALSE);;

'''
        anchor=b'U0 WordSearch()\n{\n'
        assert native.count(anchor)==1
        native=prefix+native.replace(anchor,anchor+b'''  if(!acd.num_words)
    Adam("ACInit;");
  if(!acd.num_words) {
    "Dictionary word list not present.\\n";
    return;
  }
''')
        name='/Demo/WordSearch.HC'
        baseline=snapshot(args.disk.read_bytes())[1]

        def patched(raw):
            tree,files,directories=snapshot(raw)
            attr,date,_=files[name]
            tree['Demo'][2]['WordSearch.HC']=files[name]=(attr,date,native)
            return tree,files,directories

        package.__globals__['snapshot']=patched
        try:
            report['packaging']=package(args.disk,image,additions={'/WordSearchProbe.HC':fixture.read_bytes()})
        finally:
            package.__globals__['snapshot']=snapshot
        delivered=snapshot(image.read_bytes())[1]
        assert {path for path in baseline if baseline[path]!=delivered.get(path)}=={name}
        report['application_sha256']=hashlib.sha256(native).hexdigest()
        (out/'WordSearch.HC').write_bytes(native)
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
    tokens=[word.decode() for word in re.findall(rb'[A-Za-z]{3,}',raw[match.end():])]
    if not tokens:
        raise ValueError('No dictionary matches in the output')
    output={'grid':match[0].decode().splitlines(),'words':tokens}
    (out/'output.json').write_text(json.dumps(output,indent=2)+'\n')
    if args.disk:
        if output!=json.loads(control.read_text()):
            raise ValueError('Full demo output differs from original')
        guest.command('6*7;')
        report['fresh_result']=guest.result_pixels()
    report.update(result='pass',grid_rows=20,output_words=len(tokens),
                  output_sha256=sha(out/'output.json'))
except Exception as error:
    report.update(result='fail',error=str(error))
    raise
finally:
    if guest:
        guest.close()
    report['inputs_unchanged']=all(sha(Path(name))==digest for name,digest in pins.items())
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
