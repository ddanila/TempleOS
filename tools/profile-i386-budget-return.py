#!/usr/bin/env python3
"""Repeat read-only Budget reopen/abort and capture a stalled return."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import time

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path, help='Saved image from the nested entry-picker workflow')
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--runs', type=int, default=16)
    args = parser.parse_args()
    if not 1 <= args.runs <= 100:
        parser.error('Use between 1 and 100 sessions')
    out, disk = args.out.resolve(), args.disk.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-budget-entry-picker/Contract.HC'
    inputs = [disk, fixture, Path(__file__).resolve(), ROOT/'docs/i386-compatibility-inventory.json',
              ROOT/'Kernel/FontStd.HC'] + [ROOT/'tools'/name for name in
              ('test-i386-budget-entry-picker.py', 'test-i386-autocomplete-interaction.py',
               'test-i386-timeclock-welcome.py', 'package-i386-native-image.py',
               'i386-budget-source.py', 'build-i386-kernel.py')]
    pins = {str(p): sha(p) for p in inputs}
    oracle = runpy.run_path(str(ROOT/'tools/test-i386-budget-entry-picker.py'))
    pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
    files = pack['snapshot'](disk.read_bytes())[1]
    reviewed = runpy.run_path(str(ROOT/'tools/i386-budget-source.py'))['budget_source']
    inventory = json.loads((ROOT/'docs/i386-compatibility-inventory.json').read_text())
    for entry in inventory['entries']:
        if entry['path'].startswith('Apps/Budget/') and files['/'+entry['path']][2] != reviewed(entry):
            raise ValueError('Budget source differs: '+entry['path'])
    if not all(name in files for name in ('/Budget/Bgt.DATA.Z', '/Budget/Strs.DD.Z', '/Budget/Accts.DD.Z')):
        raise ValueError('A previously saved nested-entry image is required')
    out.mkdir(parents=True)
    report = dict(result='running',input_sha256=pins,runs_requested=args.runs,runs=[],
                  scope='Read-only Budget reopen/abort repetition on a previously saved image; '
                        'unchanged fixture, keyboard input, exact caller/record checks and stopped '
                        'CPU/RAM capture on failure. Not fresh entry or full resource qualification.')
    guest = None
    case = None
    try:
        image = out/'working.img'
        probe = files.get('/Probe/BudgetEntry.HC')
        if probe and probe[2] != fixture.read_bytes():
            raise ValueError('Saved image contains a different entry fixture')
        additions = {} if probe else {'/Probe/BudgetEntry.HC':fixture.read_bytes()}
        report['packaging'] = pack['package'](disk,image,additions=additions)
        baseline = pack['snapshot'](image.read_bytes())[1]
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']

        class RegionGuest(Guest):
            region_start = 0

            def collect(self):
                # Each command exports the same names; never reread previous, freed addresses.
                text = self.log.read_text(errors='replace')[self.region_start:]
                for line in text.split('\n')[:-1]:
                    if line.startswith('EXPORT ') and line not in self.seen:
                        _,name,address,size = line.split()
                        if Path(name).name != name:
                            raise ValueError('Invalid export name')
                        self.call('pmemsave',val=int(address,16),size=int(size,16),filename=str(self.out/name))
                        self.seen.add(line)
                return text

        guest = RegionGuest(image,out/'guest',True)
        guest.wait('DONE native kernel startup\n')
        time.sleep(3)
        for command in ['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);',
                        'AdamFile("C:/Adam/TaskSettings.HC",FALSE);',
                        '#include "C:/Apps/Budget/Load.HC"',
                        '#include "C:/Probe/BudgetEntry.HC"']:
            guest.command(command)
        for index in range(1,args.runs+1):
            case = out/f'round-{index:03d}'
            case.mkdir()
            guest.out = case
            guest.region_start = len(guest.log.read_text(errors='replace'))
            guest.seen = set()
            guest.type('BudgetEntry(TRUE);')
            guest.press('ret')
            guest.wait('BR ready\n',30)
            time.sleep(1)
            guest.key('shift',True)
            guest.press('esc')
            guest.key('shift',False)
            guest.wait('BR done\n',30)
            guest.wait('COMMAND OK\n',30)
            records = [(case/name).read_bytes() for name in oracle['REOPEN_NAMES']]
            if records[2] != struct.pack('<q',63) or records[0] != records[1]:
                raise ValueError('Reopen caller state/document changed')
            # The existing independent oracle checks every saved field with native amount bits.
            oracle['verify']([b'',records[0],struct.pack('<q',1023)]+records[3:],True)
            if pack['snapshot'](image.read_bytes())[1] != baseline:
                raise ValueError('Read-only reopen/abort changed file bytes or metadata')
            guest.command('6*7;')
            guest.result_pixels()
            (case/'debug.log').write_text(guest.collect())
            report['runs'].append(dict(index=index,mask=63,files_unchanged=True,fresh_arithmetic=True,
                                       exports_sha256={name:sha(case/name) for name in oracle['REOPEN_NAMES']}))
            (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
            print('Completed read-only return',index,flush=True)
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc))
        if guest is not None and guest.p.poll() is None:
            folder = case or out/'guest'
            guest.call('stop')
            registers = guest.call('human-monitor-command',**{'command-line':'info registers'})
            (folder/'failure-registers.txt').write_text(registers)
            memory = folder/'failure-memory.bin'
            guest.call('pmemsave',val=0,size=64*1024*1024,filename=str(memory))
            (folder/'debug.log').write_text(guest.collect())
            report['failure_capture'] = dict(folder=str(folder),memory_sha256=sha(memory),
                                             registers_sha256=sha(folder/'failure-registers.txt'))
        raise
    finally:
        if guest is not None:
            guest.close()
        report['inputs_unchanged'] = all(p.is_file() and sha(p)==pins[str(p)] for p in inputs)
        if not report['inputs_unchanged']:
            report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__ == '__main__':
    main()
