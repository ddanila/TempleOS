import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct

p = argparse.ArgumentParser()
p.add_argument('disk', type=Path)
p.add_argument('--out', type=Path, required=True)
args = p.parse_args()
root = Path(__file__).resolve().parent
contract = root/'FillBench.HC'
pack_path = Path('tools/package-i386-native-image.py')
guest_path = Path('tools/test-i386-autocomplete-interaction.py')
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
pins = {str(path): sha(path) for path in [
    Path(__file__), args.disk, contract, pack_path, guest_path]}
pack = runpy.run_path(str(pack_path))
Guest = runpy.run_path(str(guest_path))['Guest']
out = args.out.resolve()
out.mkdir()
report = {'result':'running', 'input_sha256':pins}
guest = None
try:
    original = pack['snapshot'](args.disk.read_bytes())[1]
    fixture = '/Probe/FillBench.HC'
    image = out/'working.img'
    report['packaging'] = pack['package'](args.disk, image, additions={fixture:contract.read_bytes()})
    guest = Guest(image, out/'guest', True)
    guest.wait('DONE native kernel startup\n')
    guest.command('#include "C:/Probe/FillBench.HC"')
    guest.command('FillBench;')
    guest.wait('EXPORT fill.bin ')
    guest.command('6*7;')
    guest.result_pixels()
    first, last = struct.unpack('<2q',(guest.out/'fill.bin').read_bytes())
    assert last >= first
    guest.close()
    guest = None
    final = pack['snapshot'](image.read_bytes())[1]
    assert final.keys() == original.keys() | {fixture}
    assert final[fixture][2] == contract.read_bytes()
    assert all(final[key] == value for key,value in original.items())
    report.update(result='pass', elapsed_guest_ms=last-first, bytes_per_fill=640*480, fills=5)
except Exception as error:
    report.update(result='fail', error=str(error))
    raise
finally:
    if guest:
        guest.close()
    report['inputs_unchanged'] = all(sha(Path(path)) == pin for path,pin in pins.items())
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
