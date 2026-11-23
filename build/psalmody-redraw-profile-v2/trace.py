from pathlib import Path
import json
import runpy
import struct
import sys

out = Path(__file__).resolve().parent
runner = Path('tools/test-i386-psalmody-keyboard.py').resolve()
archive = '/Apps/Psalmody/PsalmodyDraw.HC'
source = Path(archive.lstrip('/')).read_bytes()
marker = b'U0 PsmMenu(I64 psm_octave)'
assert source.count(marker) == 1
prefix, menu = source.split(marker)
helper = b"""U0 PsmRedrawTrace(I64 phase)
{
  U8 line[80],*p=line;
  StrPrint(line,"PS redraw %d %d\\n",phase,ToI64(tS*1000));
  while(*p)OutU8(0xE9,*p++);
}

"""
for label, original, replacement in [
    (1, b'  DocClear;', b'  PsmRedrawTrace(1);\n  DocClear;'),
    (2, b'  DocClear;', b'  DocClear;\n  PsmRedrawTrace(2);'),
    (3, b'  DrawDC2;', b'  DrawDC2;\n  PsmRedrawTrace(3);'),
    (4, b'  Refresh(2);', b'  PsmRedrawTrace(4);\n  Refresh(2);'),
    (5, b'  Refresh(2);', b'  Refresh(2);\n  PsmRedrawTrace(5);'),
]:
    assert menu.count(original) == 1, label
    menu = menu.replace(original, replacement)
start = b"""U0 DrawDC2()
{
  DCFill;
  DrawPickNoteBox;
  DrawPickMeterBox;
  DrawPickTools;
}"""
end = b"""U0 DrawDC2()
{
  PsmRedrawTrace(21);
  DCFill;
  PsmRedrawTrace(22);
  DrawPickNoteBox;
  PsmRedrawTrace(23);
  DrawPickMeterBox;
  PsmRedrawTrace(24);
  DrawPickTools;
  PsmRedrawTrace(25);
}"""
assert prefix.count(start) == 1
prefix = prefix.replace(start, helper + end)
for n, token in enumerate([
    b'  Sprite($IB,"<17>",BI=17$);',
    b'  "   ";\n  if (psm.playing)',
    b'  "   ";\n  if (psm.record_entry->checked)',
    b'  "$$CM+LX,0,6$$";',
    b'  PsmSetOctave(psm_octave);',
], 11):
    assert menu.count(token) == 1, token
    menu = menu.replace(token, f'  PsmRedrawTrace({n});\n'.encode() + token)
payload = prefix + marker + menu
(out/'PsalmodyDraw.HC').write_bytes(payload)

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
start = text.index("image=out/'working.img';")
end = text.index('\n', start)
text = text[:start] + ("image=out/'working.img';report['packaging']="
    "diagnostic_package(pack,args.disk.resolve(),image,fixture.read_bytes());"
    "report['scope']='Diagnostic overlay with guest Psalmody menu timing'") + text[end:]
text = text.replace("if changed!={'/Probe/PsalmodyKeyboard.HC'}:", "if changed!={'/Probe/PsalmodyKeyboard.HC', archive}:")
text = text.replace("        verify(records)", """        report['timing'] = [line for line in g.collect().splitlines() if line.startswith('PS redraw ')]
        verify(records)""")
exec(compile(text, str(runner), 'exec'), {'__file__':str(runner), '__name__':'__main__',
     'diagnostic_package':diagnostic_package, 'archive':archive})
