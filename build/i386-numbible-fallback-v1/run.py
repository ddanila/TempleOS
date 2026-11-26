"""Run the unchanged NumBible demo and export its saved DolDoc."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
args.out.mkdir()
export = rb'''
U0 BibleExport()
{
  I64 size;
  U8 *data=FileRead("~/DemoNumBible.DD.Z",&size),*line;
  if(!data || !size)throw('Bible',TRUE);
  line=MStrPrint("EXPORT numbered.DD %X %X\n",data,size);
  U8 *cursor=line;
  while(*cursor)OutU8(0xE9,*cursor++);
  Free(line);
  Sleep(5000);
  Free(data);
}
BibleExport;
'''
sample = b'Alpha\n\nBeta without a final newline'
source_sha = None
if args.disk:
    image = args.out / 'working.img'
    original = args.disk.read_bytes()
    source_sha = hashlib.sha256(original).hexdigest()
    pack = runpy.run_path(str(ROOT / 'tools/package-i386-native-image.py'))
    path = '/Demo/DolDoc/NumBible.HC'
    delivered = pack['snapshot'](original)[1][path][2]
    if delivered != (ROOT / path[1:]).read_bytes():
        raise ValueError('Bundled demo differs from the checked-in source')
    snapshot = pack['snapshot']
    def sample_snapshot(disk):
        tree, files, directories = snapshot(disk)
        name='/Misc/Bible.TXT'
        attr,date,_=files[name]
        files[name]=tree['Misc'][2]['Bible.TXT']=(attr,date,sample)
        return tree,files,directories
    pack['package'].__globals__['snapshot']=sample_snapshot
    pack['package'](args.disk,image,additions={
        '/Probe/NumBible.HC': b'#include "C:/Demo/DolDoc/NumBible.HC"\n' + export,
    })
else:
    overlay = args.out / 'reference'
    reference = runpy.run_path(str(ROOT / 'tools/test-i386-timeclock-reference.py'))
    reference['restore_reference'](overlay)
    (overlay/'Misc/Bible.TXT').write_bytes(sample)
    (overlay / 'Once.HC').write_bytes(
        b'Cd("B:/");DirMk("B:/Home");HomeSet("B:/Home");\n'
        b'#include "T:/Demo/DolDoc/NumBible.HC"\n' + export +
        b'OutU8(0xE9,65);OutU8(0xE9,10);\n')
    image = args.out / 'original.iso'
    subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),
                    '--output',str(image)],cwd=ROOT,check=True)

Guest = runpy.run_path(str(ROOT / 'tools/test-i386-autocomplete-interaction.py'))['Guest']
with_error = {'result':'fail','input_sha256':source_sha}
guest = Guest(image, args.out / 'guest', bool(args.disk))
try:
    if args.disk:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Probe/NumBible.HC"', timeout=1800)
        guest.command('6*7;')
        with_error['arithmetic'] = guest.result_pixels()
    else:
        guest.wait('\nA\n',1800)
    logical = (guest.out / 'numbered.DD').read_bytes()
    with_error.update(result='pass',output_bytes=len(logical),
                      output_sha256=hashlib.sha256(logical).hexdigest())
except Exception as error:
    with_error['error'] = str(error)
    raise
finally:
    guest.close()
    (args.out / 'result.json').write_text(json.dumps(with_error,indent=2)+'\n')
