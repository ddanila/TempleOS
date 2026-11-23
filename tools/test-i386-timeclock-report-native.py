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
REOPEN = [('#include "C:/ReportNative.HC"', []),
          ('TimeReportCapture("C:/report-reopened.DD");', ['1']), ('6*7;', ['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--welcome', action='store_true', help='Expect the welcome-document startup screen')
    parser.add_argument('--managed-pointer', action='store_true', help='Expect the standard managed pointer in welcome frames')
    parser.add_argument('--accel', choices=('tcg', 'kvm'), default='tcg')
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
    load_line='After Loading, type PunchIn;, PunchOut; or TimeRep;'
    report_lines=['IN  09/04/98 01:30:00:','start','','OUT 09/04/98 03:00:00:',
                  'finish','','Week Total:01:30:00','1','> ']
    plugin_line='You might want to make PLUGINS for hot keys.'
    row_styles={load_line:[(0,len(load_line),0),(20,28,2),(30,39,2),(43,51,2)],
                plugin_line:[(0,len(plugin_line),0)],
                'start':[(0,5,0)],'finish':[(0,6,0)],
                report_lines[0]:[(0,len(report_lines[0]),4)],
                report_lines[3]:[(0,len(report_lines[3]),4)],
                report_lines[6]:[(0,len(report_lines[6]),4)]}
    report_cleared_colors={(7,0):0,(8,0):0}
    def execute(commands,destination,reopening=False):
        styles={}
        if args.welcome:
            if not reopening:
                styles[1]={'return_rows':[load_line,plugin_line,'','','> '],
                           'return_colors':{(4,0):0}}
                styles[2]={'typing_colors':{(4,0):0},'return_rows':report_lines,
                           'return_colors':report_cleared_colors}
                styles[3]={'typing_colors':report_cleared_colors,
                           'return_colors':report_cleared_colors}
            else:
                styles[1]={'return_rows':report_lines,'return_colors':report_cleared_colors}
                styles[2]={'typing_colors':report_cleared_colors,
                           'return_colors':report_cleared_colors}
        return run_input(working,destination,snapshot=False,ram_mib=64,cpu='486,-fpu',accel=args.accel,qmp_stdio=True,welcome=args.welcome,
                         managed_pointer=args.managed_pointer,keep_window_manager=args.managed_pointer,
                         startup_check={'status':'ok','answers':[],'commands':commands,
                                        'pause_window_manager':not args.managed_pointer,
                                        'rejected_answers':['0'],'rejection_prefixes':('INPUT REJECT ',),
                                        'command_timeout':120,'row_styles':row_styles,'command_styles':styles})
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
        report['reopen'] = execute(REOPEN,out/'reopen',True)
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
