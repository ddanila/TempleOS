"""Capture the main heap before and after the installed User child allocation."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('disk',type=Path)
parser.add_argument('--expect-exhausted',action='store_true')
parser.add_argument('--out',type=Path,required=True)
args=parser.parse_args()
out=args.out.resolve()
out.mkdir()
fixture_path=Path('tests/guest/i386-user-startup-reference/UserStartup.HC')
fixture=fixture_path.read_bytes()
working=out/'working.img'
pack=runpy.run_path('tools/package-i386-native-image.py')['package']
package=pack(args.disk,working,additions={'/UserStartup.HC':fixture})
Guest=runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
analyze=runpy.run_path('tools/profile-i386-startup-memory.py')['analyze']
user8=runpy.run_path('tools/test-i386-user-startup.py')
guest=Guest(working,out/'guest',True,ram_mib=8)
report={'result':'running','package':package,'snapshots':{},
        'fixture_sha256':hashlib.sha256(fixture).hexdigest()}
try:
    guest.wait('DONE native kernel startup\n')
    commands=user8['COMMANDS']
    for command,_ in commands[:3]:
        guest.command(command)

    def snapshot(label):
        dump=out/(label+'.bin')
        guest.call('stop')
        try:
            guest.call('pmemsave',val=0,size=8*1024*1024,filename=str(dump))
            registers=guest.call('human-monitor-command',**{'command-line':'info registers'})
            data=dump.read_bytes()
            detail=analyze(working,guest.collect(),data,registers)
        finally:
            guest.call('cont')
        (out/(label+'.json')).write_text(json.dumps(detail,indent=2)+'\n')
        keys=('capacity','used','largest_free','allocations','failure_callers','stopped_callers')
        report['snapshots'][label]={key:detail[key] for key in keys}
        report['snapshots'][label]['memory_sha256']=hashlib.sha256(data).hexdigest()

    snapshot('before-user')
    start=len(guest.collect())
    guest.type(commands[3][0]);guest.press('ret')
    if args.expect_exhausted:
        guest.wait('HEAP EXHAUSTED ',start=start)
        snapshot('after-failure')
        report['failure_log']=[line for line in guest.collect()[start:].splitlines()
                               if line.startswith(('HEAP EXHAUSTED','HEAP FAILURE CALLERS'))]
    else:
        guest.wait('USER START MASK 255\n',start=start)
        guest.wait('COMMAND OK\n',start=start)
    report['result']='pass'
except Exception as error:
    report.update(result='fail',error=str(error))
    raise
finally:
    guest.close()
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
