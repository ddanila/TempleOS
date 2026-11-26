import hashlib
import json
from pathlib import Path
import runpy
import sys

disk, out = (Path(arg).resolve() for arg in sys.argv[1:])
out.mkdir()
source = Path('Kernel/I386/Ata.HC')
data = source.read_bytes()
start = data.index(b'U0 I386AtaReadWords(')
end = data.index(b'U0 I386AtaPause(', start)
encoding = bytes.fromhex('f3666d')
fixture = data[start:end] + b'''
U0 VerifyAtaWordTransferEncoding()
{
  CHashFun *fun=HashFind("I386AtaReadWords",Fs->hash_table,HTT_FUN);
  I64 index=0;
  if(!fun || !fun->exe_addr)throw('ATAWords',TRUE);
  U8 *code=fun->exe_addr;
  while(index<64 && code[index]!=0xC3) {
    if(code[index]==0xF3 && code[index+1]==0x66 && code[index+2]==0x6D)return;
    index++;
  }
  throw('ATAWords',TRUE);
}
VerifyAtaWordTransferEncoding;
'''
out.joinpath('fixture.HC').write_bytes(fixture)

def sha(data):
    return hashlib.sha256(data).hexdigest()

hashes = {str(path): sha(path.read_bytes()) for path in (disk, source)}
report = dict(result='fail', input_sha256=hashes, encoding=encoding.hex(), fixture_sha256=sha(fixture))
try:
    working = out/'working.img'
    runpy.run_path('tools/package-i386-native-image.py')['package'](
        disk, working, additions={'/Probe/ATAWords.HC': fixture})
    Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest = Guest(working, out/'guest', True)
    try:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Probe/ATAWords.HC"')
        guest.command('6*7;')
        report['arithmetic_pixels'] = guest.result_pixels()
    finally:
        guest.close()
    report['result'] = 'pass'
finally:
    report['inputs_unchanged'] = all(sha(Path(path).read_bytes())==digest for path,digest in hashes.items())
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    assert report['inputs_unchanged']
