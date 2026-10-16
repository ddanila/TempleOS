#!/usr/bin/env python3
"""Exercise unchanged TimeClock punch commands, persisted records and reboot reopen."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT/'tests/guest/i386-timeclock-punch-native/Contract.HC'
COMMANDS = [('!FileFind("~/TimeClock",,FUF_JUST_DIRS);', ['1']),
            ('#include "C:/PunchNative.HC"', ['1'])] + [
    (f'PunchStage({i});', ['1']) for i in range(7)] + [('6*7;', ['42'])]
REOPEN = [('#include "C:/PunchNative.HC"', ['1']), ('!TimeRep;', ['1']),
          ('PunchSave("C:/punch-reopen.DATA");', ['1']), ('6*7;', ['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    build = ROOT/'tools/build-i386-kernel.py'
    package = ROOT/'tools/package-i386-native-image.py'
    reference = ROOT/'tools/test-i386-timeclock-punch-reference.py'
    inventory = ROOT/'docs/i386-compatibility-inventory.json'
    pins = {str(p): sha(p) for p in [source, FIXTURE, runner, build, package,
                                   reference, inventory, Path(__file__).resolve()]}
    read_files = runpy.run_path(str(build))['mutated_file_contents']
    decode = runpy.run_path(str(reference))['decode']
    expected_sources = {('/'+e['path']): e['reference_sha256']
                        for e in json.loads(inventory.read_text())['entries']
                        if e['path'].startswith('Apps/TimeClock/')}
    delivered = read_files(source, set(expected_sources))
    if {n: hashlib.sha256(v).hexdigest() for n,v in delivered.items()} != expected_sources:
        raise ValueError('TimeClock application differs from the pinned original sources')
    out.mkdir(parents=True)
    working = out/'working.img'
    report = dict(result='running', ram_mib=64, cpu='486,-fpu',
                  scope='Unchanged TimeClock scripted punch commands, independent typed-file decoding, duplicate/cancel behavior and cold reboot reopen; not physical keyboard or complete application qualification',
                  input_sha256=pins, application_sha256=expected_sources,
                  commands=COMMANDS, reopen_commands=REOPEN)
    report['packaging'] = runpy.run_path(str(package))['package'](
        source, working, additions={'/PunchNative.HC': FIXTURE.read_bytes()})
    run_input = runpy.run_path(str(runner))['run_input']
    def execute(commands, destination):
        return run_input(working, destination, snapshot=False, ram_mib=64,
                         cpu='486,-fpu', accel='tcg', qmp_stdio=True,
                         startup_check={'status':'ok', 'answers':[], 'commands':commands,
                                        'rejection_prefixes':('INPUT REJECT ',), 'rejected_answers':['0'],
                                        'command_timeout':120})
    try:
        report['behavior'] = execute(COMMANDS, out/'qemu')
        names = ['empty', 'in', 'duplicate-in', 'out', 'duplicate-out',
                 'cancel-in', 'final', 'bounds']
        paths = {f'/punch-{name}.DATA' for name in names}
        files = read_files(working, paths | set(expected_sources) | {'/PunchNative.HC'})
        if any(hashlib.sha256(files.get(n,b'')).hexdigest()!=digest for n,digest in expected_sources.items()):
            raise ValueError('Application sources changed during punch commands')
        if files.get('/PunchNative.HC') != FIXTURE.read_bytes():
            raise ValueError('Delivered native fixture differs from source')
        read = lambda name: files[f'/punch-{name}.DATA']
        final = decode(read('final'))
        expected = [(1,b'alpha\nbeta\n'), (2,b'finish\n'), (1,b''), (2,b'')]
        if [(kind,text) for kind,date,text in final] != expected:
            raise ValueError('Punch record types/descriptions differ from original oracle')
        bounds = struct.unpack('<8Q', read('bounds'))
        for i,(_,date,_) in enumerate(final):
            if not bounds[2*i] <= date <= bounds[2*i+1]:
                raise ValueError('Punch date outside measured Now bounds')
        for name,count in [('empty',0), ('in',1), ('out',2), ('cancel-in',3)]:
            if decode(read(name)) != final[:count]:
                raise ValueError('Intermediate file differs from final prefix: '+name)
        for name in ('in','out'):
            if read(name)!=read('duplicate-'+name):
                raise ValueError('Duplicate punch changed saved file: '+name)
        report['records'] = [dict(type=k,date_ticks=d,description=t.decode('latin1')) for k,d,t in final]
        report['persisted_sha256'] = {n:hashlib.sha256(files[n]).hexdigest() for n in sorted(paths)}
        report['reopen'] = execute(REOPEN, out/'reopen')
        reopened = read_files(working, {'/punch-reopen.DATA'})['/punch-reopen.DATA']
        if reopened != read('final'):
            raise ValueError('Reopened application file differs from persisted punch sequence')
        report['reopened_sha256'] = hashlib.sha256(reopened).hexdigest()
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(n))==digest for n,digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Native punch inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
