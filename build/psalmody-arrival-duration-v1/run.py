from pathlib import Path
import json
import runpy
import struct
import sys

out = Path(__file__).resolve().parent
runner = Path('tools/test-i386-psalmody-keyboard.py').resolve()
archive = '/Apps/Psalmody/PsalmodyMain.HC'
payload = (out/'PsalmodyMain.HC').read_bytes()

def diagnostic_package(pack, image, working, fixture):
    original = pack['snapshot']
    package = pack['package']
    def snapshot(raw):
        tree, files, dirs = original(raw)
        entry = tree['Apps'][2]['Psalmody'][2]
        name = Path(archive).name
        attr, stamp, _ = entry[name]
        entry[name] = files[archive] = (attr, stamp, payload)
        return tree, files, dirs
    package.__globals__['snapshot'] = snapshot
    try:
        report = package(image, working, additions={'/Probe/PsalmodyKeyboard.HC':fixture})
    finally:
        package.__globals__['snapshot'] = original
    before = original(image.read_bytes())[1]
    after = original(working.read_bytes())[1]
    assert {key for key in before.keys() | after.keys()
            if before.get(key) != after.get(key)} == {archive, '/Probe/PsalmodyKeyboard.HC'}
    assert after[archive][2] == payload
    return report

text = runner.read_text()
text = text.replace("paths=[Path(__file__).resolve(),fixture,",
    "paths=[Path(__file__).resolve(),fixture,Path(wrapper).resolve(),payload_path,")
start = text.index("image=out/'working.img';")
end = text.index('\n', start)
text = text[:start] + ("image=out/'working.img';report['packaging']="
    "diagnostic_package(pack,args.disk.resolve(),image,fixture.read_bytes());"
    "report['scope']='Physical keyboard recording duration from queued keyboard timestamps'") + text[end:]
text = text.replace("if changed!={'/Probe/PsalmodyKeyboard.HC'}:", "if changed!={'/Probe/PsalmodyKeyboard.HC', archive}:")
text = text.replace("        verify(records)", """        report['timing'] = [line for line in g.collect().splitlines() if line.startswith(('PS timing ', 'PS queue '))]
        verify(records)""")
exec(compile(text, str(runner), 'exec'), {'__file__':str(runner), '__name__':'__main__',
     'diagnostic_package':diagnostic_package, 'archive':archive, 'wrapper':__file__, 'payload_path':out/'PsalmodyMain.HC'})
