import argparse
import json
from pathlib import Path
import re
import runpy
import struct
import time

parser = argparse.ArgumentParser()
parser.add_argument('disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
fixture = Path(__file__).with_name('Probe.HC')
doc_types = Path('Kernel/DocTypes.HH').read_bytes()
start = doc_types.index(b'class CEdFileName\n')
chooser_type = doc_types[start:doc_types.index(b'\n};', start)+4]
chooser_type_include = b'#include "/Kernel/FileNameFormTypes.HH"\n'
doc_popup = Path('Adam/DolDoc/DocPopUp.HC').read_bytes()
chooser = doc_popup[doc_popup.index(b'public U8 *FileNameForm'):
                    doc_popup.index(b'#help_index "DolDoc"\n')]
chooser_include = b'#include "/Adam/DolDoc/FileNameFormCore.HC"\n\n'
sound = Path('Adam/ASnd.HC').read_bytes()
original_play = sound[sound.index(b'U8 *MusicSetOctave'):
                      sound.index(b'#include "/Adam/MusicResetCore.HC"')]
note_conversion = b'#include "/Adam/Snd/NoteConversionCore.HC"\n\n'
assert original_play.count(note_conversion) == original_play.count(b'cnts.jiffies') == 1
play = original_play.replace(note_conversion, b'').replace(b'cnts.jiffies', b'MUSIC_JIFFIES')
play_include = note_conversion + b'#include "/Adam/Snd/MusicPlayCore.HC"\n\n'
end_callback = sound[sound.index(b'public U0 SndTaskEndCB'):sound.index(b'#help_index "Snd/Math;Math"')]
music = b"""#define MUSIC_JIFFIES ToI64(Round(tS*1000.0))
#include "/Kernel/FileNameFormTypes.HH"
#include "/Adam/DolDoc/FileNameFormCore.HC"
#include "/Adam/Snd/MusicPlayCore.HC"
""" + end_callback
changed_sources = {
    '/Kernel/DocTypes.HH': doc_types.replace(chooser_type,chooser_type_include),
    '/Adam/DolDoc/DocPopUp.HC': doc_popup.replace(chooser,chooser_include),
    '/Adam/ASnd.HC': sound.replace(original_play,play_include),
}
image = out / 'working.img'
packer = runpy.run_path('tools/package-i386-native-image.py')
package = packer['package']
snapshot = packer['snapshot']
load_path = '/Apps/Span/Load.HC'
source = Path(load_path[1:]).read_bytes()
entry = b'#include "Span.HH"'
assert source.count(entry) == 1
startup = b"""#ifdef I386_PUBLIC_USER_INCLUDED
if(!HashFind("ODEsUpdate",adam_task->hash_table,HTT_FUN))
  AdamFile("/Kernel/I386/NativeODE.HC",FALSE);;
if(!HashFind("ACInit",adam_task->hash_table,HTT_FUN))
  AdamFile("/Adam/AutoComplete/MakeAC.HC",FALSE);;
if(!HashFind("SettingsPush",adam_task->hash_table,HTT_FUN))
  AdamFile("/Adam/TaskSettings.HC",FALSE);;
if(!HashFind("PopUpFileName",adam_task->hash_table,HTT_FUN))
  AdamFile("/Kernel/I386/NativeSpanServices.HC",FALSE);;
#ifndef I386_STRUT_BUTTONS_INCLUDED
#define I386_STRUT_BUTTONS_INCLUDED
#include "/Adam/Ctrls/CtrlsBttn.HC"
#endif
#endif
"""
replacement = source.replace(entry, startup + entry)


def overlay(raw):
    tree, entries, dirs = snapshot(raw)
    for path, data in {load_path:replacement, **changed_sources}.items():
        node = tree
        parts = path.strip('/').split('/')
        for name in parts[:-1]:
            node = node[name][2]
        attr, date, previous = node[parts[-1]]
        if path == load_path:
            assert previous in (source, replacement)
        node[parts[-1]] = entries[path] = (attr,date,data)
    return tree, entries, dirs


package.__globals__['snapshot'] = overlay
try:
    report = {'result':'running', 'package':package(args.disk,image,additions={
        '/SpanProbe.HC':fixture.read_bytes(),
                '/Kernel/I386/NativeSpanServices.HC':music,
        '/Kernel/FileNameFormTypes.HH':chooser_type+b'\n',
        '/Adam/DolDoc/FileNameFormCore.HC':chooser,
        '/Adam/Snd/MusicPlayCore.HC':play,
    })}
finally:
    package.__globals__['snapshot'] = snapshot
assert snapshot(image.read_bytes())[1][load_path][2] == replacement
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image, out / 'guest', True)
try:
    guest.wait('DONE native kernel startup\n')
    for command in (
        '#include "C:/Apps/Span/Load.HC"',
        '#include "C:/SpanProbe.HC"',
    ):
        report['command']=command
        guest.command(command)
    guest.type('SPProbe;')
    guest.press('ret')
    log = guest.wait('SPAN instructions ', 90)
    address = int(re.search(r'SPAN instructions ([0-9A-F]+)\n',log)[1],16)
    pointer = out / 'pointer.bin'

    def click(target):
        for _ in range(50):
            guest.call('pmemsave', val=address, size=16, filename=str(pointer))
            x, y = struct.unpack('<2q', pointer.read_bytes())
            if (x, y) == target:
                break
            guest.call('input-send-event', events=[
                {'type':'rel','data':{'axis':'x','value':target[0]-x}},
                {'type':'rel','data':{'axis':'y','value':target[1]-y}},
            ])
            time.sleep(.2)
        else:
            raise ValueError(f'Mouse could not reach {target}')
        for down in (True, False):
            guest.call('input-send-event', events=[
                {'type':'btn','data':{'down':down,'button':'left'}},
            ])
            time.sleep(.3)

    guest.screenshot('instructions')
    click((128,278))
    guest.wait('SPAN editor ', 30)
    click((260,135))
    guest.wait('SPAN placed mass\n', 20)
    guest.screenshot('edited')
    guest.press('spc')
    guest.wait('SPAN simulation advanced\n', 25)
    guest.press('spc')
    guest.wait('SPAN stopped\n', 20)
    guest.key('shift', True)
    guest.press('esc')
    guest.key('shift', False)
    log = guest.wait('SPAN returned\n', 30)
    if 'FAIL Span' in log:
        raise ValueError('Span fixture reported a state or cleanup failure')
    guest.command('6*7;')
    report['fresh_result'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    report['observations'] = [line for line in guest.collect().splitlines()
                              if line.startswith(('SPAN ', 'FAIL Span'))]
    guest.close()
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
