"""Compare the unchanged ExtChars demo and its installed character shape."""
import sys
from pathlib import Path

tool = Path('tools/test-i386-demo-batch.py').resolve()
source = tool.read_text()
anchor = '  ExeFile(path);'
assert source.count(anchor) == 1
source = source.replace('  I64 size,previous_seed=Fs->rand_seed;',
                        '  I64 size,previous_seed=Fs->rand_seed;\n  U64 saved_glyph=text.font[255];')
source = source.replace(anchor, r"""  ExeFile(path);
  line=MStrPrint("EXTCHARS CAPTURE %016X\n",text.font[255]);
  DemoBatchLog(line);Free(line);
  DocInsDoc(put,doc);
  Refresh;
  DemoBatchLog("EXTCHARS READY\n");
  Sleep(3000);
  text.font[255]=saved_glyph;""")
anchor = "        guest.wait('DEMO BATCH DONE\\n')"
source = source.replace(anchor, """        guest.wait('EXTCHARS READY\\n')
        guest.screenshot('glyph')
"""+anchor)
source = source.replace("            guest.command('#include \"C:/Probe/DemoBatch.HC\"')",
    "            guest.type('#include \"C:/Probe/DemoBatch.HC\"')\n            guest.press('ret')")
anchor = "        report['result'] = 'pass' if all(e['result'] == 'pass' for e in report['entries'].values()) else 'fail'"
assert source.count(anchor) == 1
source = source.replace(anchor, anchor+'''
        expected_glyph = int.from_bytes(bytes((0x3C,0x42,0xA5,0x81,0xC3,0xBD,0x42,0x3C)), 'little')
        marker = f'EXTCHARS CAPTURE {expected_glyph:016X}\\n'
        for name in ('original', 'native'):
            if (out/name/'debug.log').read_text().count(marker) != 1:
                raise ValueError(f'Glyph differs on {name}')
        report['glyph_rows'] = [0x3C,0x42,0xA5,0x81,0xC3,0xBD,0x42,0x3C]
''')
sys.argv[0] = str(tool)
exec(compile(source,str(tool),'exec'),{'__file__':str(tool),'__name__':'__main__'})
