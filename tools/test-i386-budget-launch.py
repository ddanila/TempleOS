#!/usr/bin/env python3
"""Start Budget through its bundled launcher and abort a cold empty session."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = r'''
CDoc *budget_launch_put;
U0 BudgetLaunchLog(U8 *text)
{
  while (*text) OutU8(0xE9,*text++);
}
U0 BudgetLaunchWatch(CTask *owner)
{
  CDoc *doc;
  while (TRUE) {
    doc=owner->put_doc;
    if (doc && doc!=budget_launch_put && doc->user_put_key) {
      BudgetLaunchLog("BUDGET LAUNCH active\n");
      return;
    }
    Sleep(5);
  }
}
U0 BudgetLaunch()
{
  CDoc *display=Fs->display_doc;
  CTaskSettings *settings=Fs->next_settings;
  I64 size;
  U8 *accounts,*data,*strings;
  budget_launch_put=Fs->put_doc;
  Spawn(&BudgetLaunchWatch,Fs,"Budget observer");
  ExeFile("::/Apps/Budget/Run.HC");
  if (Fs->put_doc!=budget_launch_put || Fs->display_doc!=display ||
      Fs->next_settings!=settings)
    throw('BgtRun',TRUE);
  accounts=FileRead("~/Budget/Accts.DD.Z",&size);
  data=FileRead("~/Budget/Bgt.DATA.Z");
  strings=FileRead("~/Budget/Strs.DD.Z");
  if (!accounts || !size || !StrMatch("BANK",accounts) || data || strings)
    throw('BgtRun',TRUE);
  Free(accounts);
  BudgetLaunchLog("BUDGET LAUNCH done\n");
}
BudgetLaunch;
'''


def run(image, out, native):
    guest_type = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
    guest = guest_type(image, out, native, reference_cpus=1)
    try:
        if native:
            guest.wait('DONE native kernel startup\n')
            guest.type('#include "C:/Probe/BudgetLaunch.HC"')
        else:
            guest.wait('BUDGET LAUNCH ready\n')
            time.sleep(2)
            guest.type('ExeFile("T:/Probe/BudgetLaunch.HC");')
        guest.press('ret')
        guest.wait('BUDGET LAUNCH active\n')
        guest.screenshot('active')
        guest.key('shift', True)
        try:
            guest.press('esc')
        finally:
            guest.key('shift', False)
        guest.wait('BUDGET LAUNCH done\n', timeout=30)
        if native:
            guest.command('6*7;')
            guest.result_pixels()
    finally:
        guest.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--archive', required=True, type=Path)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    disk, out = args.disk.resolve(), args.out.resolve()
    out.mkdir(parents=True)
    sha = lambda data: hashlib.sha256(data).hexdigest()
    pins = {path: sha(path.read_bytes()) for path in (disk, args.archive)}
    report = dict(result='running', disk_sha256=pins[disk], archive_sha256=pins[args.archive])
    try:
        overlay = out/'original-source'
        runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
        (overlay/'Apps/Budget/Accts.DD.Z').write_bytes(args.archive.read_bytes())
        (overlay/'Once.HC').write_text(
            'U0 BudgetLaunchReady(){U8 *s="BUDGET LAUNCH ready\\n";while(*s)OutU8(0xE9,*s++);}\n'
            'BudgetLaunchReady;\n')
        (overlay/'Probe').mkdir(exist_ok=True)
        (overlay/'Probe/BudgetLaunch.HC').write_text(
            'Cd("B:/");DirMk("B:/BudgetProbeHome");HomeSet("B:/BudgetProbeHome");\n' + FIXTURE)
        iso = out/'original.iso'
        subprocess.run(['python3', str(ROOT/'tools/build-iso.py'), '--overlay', str(overlay),
                        '--output', str(iso)], cwd=ROOT, check=True)
        pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
        image = out/'native.img'
        fixture_path = '/Probe/BudgetLaunch.HC'
        pack['package'](disk, image, additions={fixture_path: FIXTURE.encode()})
        original_files = pack['snapshot'](disk.read_bytes())[1]
        run(iso, out/'original', False)
        run(image, out/'native', True)
        updated = pack['snapshot'](image.read_bytes())[1]
        budget_dir = runpy.run_path(str(ROOT/'tools/i386-budget-source.py'))['installed_budget_directory'](
            original_files, updated, fixture_path)
        report.update(result='pass', budget_directory=budget_dir,
                      installed_accounts_sha256=sha(updated[budget_dir+'/Accts.DD.Z'][2]),
                      preserved_files=len(original_files))
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(path.read_bytes()) == digest for path, digest in pins.items())
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if not report['inputs_unchanged']:
        raise ValueError('A launch input changed')


if __name__ == '__main__':
    main()
