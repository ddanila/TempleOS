#!/usr/bin/env python3
"""Exercise the bundled character animation and its task report in a native guest."""

import argparse
import hashlib
import json
from pathlib import Path
import runpy
import time

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / 'build/i386-char-animation-reference-v1/Probe.HC'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True)
    disk = args.disk.resolve()
    disk_sha256 = sha(disk)
    working = out / 'working.img'
    package = runpy.run_path(str(ROOT / 'tools/package-i386-native-image.py'))['package']
    guest_type = runpy.run_path(str(ROOT / 'tools/test-i386-autocomplete-interaction.py'))['Guest']
    package(disk, working, {'/Probe/Animation.HC': FIXTURE.read_bytes()})
    guest = guest_type(working, out / 'native', True)
    try:
        guest.wait('DONE native kernel startup\n')
        time.sleep(3)
        guest.command("if(TaskMemAlloced!=Fs->code_heap->alloced_u8s+"
                      "(Fs->code_heap!=Fs->data_heap)*Fs->data_heap->alloced_u8s || "
                      "TaskMemAlloced(0x80000000)) throw('TaskMem',TRUE);")
        start = len(guest.collect())
        guest.type('#include "C:/Probe/Animation.HC"')
        guest.press('ret')
        guest.wait('DONE character animation\n', 180, start)
        guest.wait('COMMAND OK\n', 180, start)
        guest.command('U8 *rep_test=DocSave(DocPut);'
                      'if(!StrMatch("CPU00",rep_test)||!StrMatch("Animate",rep_test))'
                      "throw('TaskRep',TRUE);Free(rep_test);")
        guest.command('CTask *rep_animation=Fs->last_child_task;'
                      'if(!TaskValidate(rep_animation)||StrCmp(rep_animation->task_title,"Animate"))'
                      "throw('AnimTask',TRUE);")
        guest.command('if(!Kill(rep_animation)||TaskValidate(rep_animation)||text.font!=animation_base)'
                      "throw('AnimEnd',TRUE);")
    finally:
        guest.close()
    if sha(disk) != disk_sha256:
        raise ValueError('Source disk changed')
    result = dict(result='pass', animation_space_patterns=4, task_memory_default_and_invalid_checked=True,
                  report_cpu_and_child_checked=True, original_font_restored=True,
                  fixture_sha256=sha(FIXTURE), disk_sha256=disk_sha256)
    (out / 'result.json').write_text(json.dumps(result, indent=2) + '\n')


if __name__ == '__main__':
    main()
