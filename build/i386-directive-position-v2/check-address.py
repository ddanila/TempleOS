"""Check that $$ points to the first byte of its generated expression."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('image', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
args.out.mkdir()
source_hash = hashlib.sha256(args.image.read_bytes()).hexdigest()
disk = args.out/'working.img'
shutil.copyfile(args.image, disk)
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(disk, args.out/'guest', True, ram_mib=8)
report = {'result':'running','image_sha256':source_hash}
try:
    guest.wait('DONE native kernel startup\n')
    guest.command('U8 *DirectivePc(){return $$;}')
    guest.command("U8 *pc=DirectivePc;if(pc<=&DirectivePc || pc>&DirectivePc+128 || *pc!=0xE8)throw('PC',TRUE);")
    guest.command('6*7;')
    report['fresh_result']=guest.result_pixels()
    report['result']='pass'
except Exception as error:
    report.update(result='fail', error=str(error))
    raise
finally:
    guest.close()
    report['inputs_unchanged'] = hashlib.sha256(args.image.read_bytes()).hexdigest()==source_hash
    (args.out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
