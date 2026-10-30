#!/usr/bin/env python3
"""Compare unchanged native TimeClock storage/report and reboot to the original golden."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT/'tests/guest/i386-timeclock-report-native/Contract.HC'
GOLDEN = ROOT/'tests/i386/timeclock-reference.json'
COMMANDS = [('!FileFind("~/TimeClock",,FUF_JUST_DIRS);', ['1']),
            ('#include "C:/ReportNative.HC"', ['1']), ('TimeReportSeed;', ['1']), ('6*7;', ['42'])]
REOPEN = [('#include "C:/ReportNative.HC"', ['1']),
          ('TimeReportCapture("C:/report-reopened.DD");', ['1']), ('6*7;', ['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--welcome', action='store_true', help='Expect the welcome-document startup screen')
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    build = ROOT/'tools/build-i386-kernel.py'
    package = ROOT/'tools/package-i386-native-image.py'
    pins = {str(p):sha(p) for p in [source, FIXTURE, GOLDEN, runner, build, package, Path(__file__).resolve()]}
    golden = json.loads(GOLDEN.read_text())
    read_files = runpy.run_path(str(build))['mutated_file_contents']
    expected_sources = {'/'+n:d for n,d in golden['application_source_sha256'].items()}
    delivered = read_files(source,set(expected_sources))
    if {n:hashlib.sha256(v).hexdigest() for n,v in delivered.items()} != expected_sources:
        raise ValueError('Application differs from original golden source hashes')
    out.mkdir(parents=True)
    working = out/'working.img'
    report = dict(result='running', input_sha256=pins, application_sha256=expected_sources,
                  commands=COMMANDS, reopen_commands=REOPEN, ram_mib=64, cpu='486,-fpu',
                  scope='Unchanged native TimeClock deterministic typed records, exact original DolDoc report, 5400-second duration and cold reboot rereport; not physical input or whole application qualification')
    report['packaging'] = runpy.run_path(str(package))['package'](
        source,working,additions={'/ReportNative.HC':FIXTURE.read_bytes()})
    run_input = runpy.run_path(str(runner))['run_input']
    def execute(commands,destination):
        return run_input(working,destination,snapshot=False,ram_mib=64,cpu='486,-fpu',accel='tcg',qmp_stdio=True,welcome=args.welcome,
                         startup_check={'status':'ok','answers':[],'commands':commands,
                                        'rejected_answers':['0'],'rejection_prefixes':('INPUT REJECT ',),
                                        'command_timeout':120})
    try:
        report['behavior'] = execute(COMMANDS,out/'qemu')
        files = read_files(working,{'/report-records.DATA','/report-first.DD','/ReportNative.HC'}|set(expected_sources))
        if files.get('/ReportNative.HC') != FIXTURE.read_bytes():
            raise ValueError('Delivered report fixture differs from source')
        if any(hashlib.sha256(files.get(n,b'')).hexdigest()!=d for n,d in expected_sources.items()):
            raise ValueError('Application sources changed during execution')
        if files['/report-records.DATA'] != bytes.fromhex(golden['logical_file_hex']):
            raise ValueError('Native typed records differ from the original golden')
        if files['/report-first.DD'] != golden['report_latin1'].encode('latin1'):
            raise ValueError('Native report differs from exact original DolDoc golden')
        report['logical_file_sha256'] = hashlib.sha256(files['/report-records.DATA']).hexdigest()
        report['report_sha256'] = hashlib.sha256(files['/report-first.DD']).hexdigest()
        report['reopen'] = execute(REOPEN,out/'reopen')
        reopened = read_files(working,{'/report-reopened.DD'})['/report-reopened.DD']
        if reopened != files['/report-first.DD']:
            raise ValueError('Report changed after cold reboot')
        report.update(result='pass',expected_total_seconds=golden['expected_total_seconds'])
    except Exception as exc:
        report.update(result='fail',error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(n))==d for n,d in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail',error='Report inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
