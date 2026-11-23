import argparse
import hashlib
import json
from pathlib import Path
import runpy


parser = argparse.ArgumentParser()
parser.add_argument('disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
lifetime = Path('tools/test-i386-popup-lifetime.py')
order = Path('tests/guest/i386-window-order/Popup.HC')
helper = Path('tools/test-i386-autocomplete-interaction.py')
packer = Path('tools/package-i386-native-image.py')
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
pins = {str(path): sha(path) for path in (args.disk, lifetime, order, helper, packer, Path(__file__))}
report = {'result': 'running', 'input_sha256': pins,
          'scope': 'Existing popup state and window-order contracts, with direct result markers'}
commands = runpy.run_path(str(lifetime))['COMMANDS']
definitions = '\n'.join(source for source, answers in commands if not answers)
reporter = '''
U0 PopupContractLog(U8 *s) {while(*s)OutU8(0xE9,*s++);}
U0 PopupContractRun()
{
  I64 normal=PLPrevious,retired=PLPrevious(TRUE),
      cancelled=PLRun(0),committed=PLRun(1),live=PLLive;
  U8 line[120];
  StrPrint(line,"POPUP LIFETIME %d %d %d %d %d\\n",normal,retired,cancelled,committed,live);
  PopupContractLog(line);
}

U0 PopupOrderRun()
{
  I64 mask=JRContract;
  U8 line[80];
  sys_focus_task=Fs;
  StrPrint(line,"POPUP ORDER %d\\n",mask);
  PopupContractLog(line);
}
'''
pack = runpy.run_path(str(packer))
Guest = runpy.run_path(str(helper))['Guest']
guest = None
try:
    image = out/'working.img'
    report['packaging'] = pack['package'](
        args.disk,image,additions={
            '/PopupContracts.HC': (definitions+'\n'+order.read_text()+'\n'+reporter).encode(),
        })
    guest = Guest(image, out/'guest', True)
    guest.wait('DONE native kernel startup\n')
    guest.command('#include "C:/PopupContracts.HC"')
    guest.type('PopupContractRun;')
    guest.press('ret')
    guest.wait('POPUP LIFETIME 1 1 63 63 255\n', 120)
    guest.type('PopupOrderRun;')
    guest.press('ret')
    guest.wait('POPUP ORDER 255\n', 120)
    guest.command('6*7;')
    report['fresh_result'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    if guest:
        log = guest.collect()
        report['observations'] = [line for line in log.splitlines() if line.startswith('POPUP ')]
        guest.close()
    report['inputs_unchanged'] = all(sha(Path(path)) == digest for path,digest in pins.items())
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
