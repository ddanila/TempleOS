#!/usr/bin/env python3
"""Compare the bundled Registry1 template's default and existing saved scores."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import subprocess

ROOT = Path(__file__).resolve().parents[1]
DEMO = 'Demo/Templates/Registry1.HC'
FIXTURE = r'''
U0 RegistryTemplateLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 RegistryTemplateCapture(U8 *name)
{
  I64 size;
  U8 *data=FileRead(sys_registry_doc->filename.name,&size),*line;
  if(!data)throw('RegTempl',TRUE);
  line=MStrPrint("EXPORT %s %X %X\n",name,data,size);
  RegistryTemplateLog(line);
  Sleep(1000);
  Free(line);
  Free(data);
}
CDoc *registry_template_previous=sys_registry_doc;
sys_registry_doc=DocNew("@DRIVE@:/TemplateRegistry.HC.Z",Fs);
In("x");
ExeFile("::/Demo/Templates/Registry1.HC");
RegistryTemplateCapture("default.HC");
if(!RegWrite("MyCompany/MyApp","F64 best_score=42.125;\n"))throw('RegTempl',TRUE);
In("x");
ExeFile("::/Demo/Templates/Registry1.HC");
RegistryTemplateCapture("existing.HC");
DocDel(sys_registry_doc);
sys_registry_doc=registry_template_previous;
RegistryTemplateLog("REGISTRY TEMPLATE DONE\n");
'''
SCORES = re.compile(rb'F64 best_score= *([0-9]+\.[0-9]+);')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    disk, out = args.disk.resolve(), args.out.resolve()
    out.mkdir()
    packer = ROOT/'tools/package-i386-native-image.py'
    guest_tool = ROOT/'tools/test-i386-autocomplete-interaction.py'
    reference = ROOT/'tools/test-i386-timeclock-reference.py'
    paths = (disk, ROOT/DEMO, packer, guest_tool, reference, Path(__file__).resolve())
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    pins = {str(path): sha(path) for path in paths}
    report = dict(result='fail', input_sha256=pins,
                  scope='Unchanged Registry1 template with queued key input; default and existing score persisted')
    try:
        overlay = out/'overlay'
        report['reference_revision'] = runpy.run_path(str(reference))['restore_reference'](overlay)
        pack = runpy.run_path(str(packer))
        _, before, _ = pack['snapshot'](disk.read_bytes())
        original_source = (overlay/DEMO).read_bytes()
        if original_source != before['/'+DEMO][2] or sha(overlay/DEMO) != pins[str(ROOT/DEMO)]:
            raise ValueError('Registry template differs from the pinned original')
        if '/TemplateRegistry.HC.Z' in before:
            raise ValueError('Registry fixture destination already exists')
        (overlay/'Once.HC').write_text(FIXTURE.replace('@DRIVE@', 'B'))
        iso = out/'original.iso'
        subprocess.run(['python3', str(ROOT/'tools/build-iso.py'), '--overlay', str(overlay), '--output', str(iso)],
                       cwd=ROOT, check=True)
        working = out/'working.img'
        fixture_path = '/Probe/RegistryTemplate.HC'
        fixture = FIXTURE.replace('@DRIVE@', 'C').encode()
        pack['package'](disk, working, additions={fixture_path: fixture})

        Guest = runpy.run_path(str(guest_tool))['Guest']
        report['cases'] = {}
        for native, image, name in [(False, iso, 'original'), (True, working, 'native')]:
            guest = Guest(image, out/name, native, reference_cpus=1)
            try:
                if native:
                    guest.wait('DONE native kernel startup\n')
                    guest.command('#include "C:'+fixture_path+'"')
                guest.wait('REGISTRY TEMPLATE DONE\n')
                scores = {}
                for case, expected in [('default', b'9999.0000'), ('existing', b'42.1250')]:
                    data = (guest.out/(case+'.HC')).read_bytes()
                    if SCORES.findall(data) != [expected]:
                        raise ValueError(f'{name} {case} saved score differs: {data!r}')
                    scores[case] = expected.decode()
                if native:
                    guest.command('6*7;')
                    report['arithmetic_pixels'] = guest.result_pixels()
                report['cases'][name] = scores
            finally:
                guest.close()
        _, after, _ = pack['snapshot'](working.read_bytes())
        changed = sorted(name for name in before.keys() | after.keys()
                         if before.get(name) != after.get(name))
        if changed != sorted((fixture_path, '/TemplateRegistry.HC.Z')):
            raise ValueError(f'Unexpected registry fixture file changes: {changed}')
        report['changed_files'] = changed
        report['result'] = 'pass'
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        report['inputs_unchanged'] = all(path.is_file() and sha(path) == pins[str(path)] for path in paths)
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Registry fixture inputs changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
