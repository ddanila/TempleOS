import hashlib
import json
from pathlib import Path
import runpy
import sys

disk, out = (Path(arg).resolve() for arg in sys.argv[1:])
out.mkdir()
values = (0, 9, 10, 0xffffffff, 0x100000000, 0x8000000000000000, 0xffffffffffffffff)
source = '#include "C:/Demo/Asm/PutDec.HC"\n' + r'''
U0 PutDecVectorCapture()
{
  CDoc *doc=DocNew,*previous=DocPut;
  U8 *data,*line,*s;
  I64 size;
  Fs->put_doc=doc;
''' + ''.join(f"  PutDecU64(0x{value:X});'\\n';\n" for value in values) + r'''
  Fs->put_doc=previous;
  data=DocSave(doc,&size);
  line=MStrPrint("EXPORT vectors.DD %X %X\n",data,size);
  for(s=line;*s;s++)OutU8(0xE9,*s);
  Sleep(1000);
  Free(line);
  Free(data);
  DocDel(doc);
}
PutDecVectorCapture;
'''
expected = (''.join(f'{value}\n' for value in values)+'\x05').encode()
out.joinpath('fixture.HC').write_text(source)

def sha(data):
    return hashlib.sha256(data).hexdigest()

original = sha(disk.read_bytes())
report = dict(result='fail', disk_sha256=original, values=values,
              expected_sha256=sha(expected), fixture_sha256=sha(source.encode()))
try:
    working = out/'working.img'
    runpy.run_path('tools/package-i386-native-image.py')['package'](
        disk, working, additions={'/Probe/PutDecVectors.HC': source.encode()})
    Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest = Guest(working, out/'guest', True)
    try:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Probe/PutDecVectors.HC"')
        actual = (guest.out/'vectors.DD').read_bytes()
        report['actual_sha256'] = sha(actual)
        if actual != expected:
            raise ValueError(f'Decimal vectors differ: {actual!r}')
        guest.command('6*7;')
        report['arithmetic_pixels'] = guest.result_pixels()
    finally:
        guest.close()
    report['result'] = 'pass'
finally:
    report['inputs_unchanged'] = sha(disk.read_bytes()) == original
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    assert report['inputs_unchanged']
