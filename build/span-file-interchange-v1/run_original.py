import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('native_file', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
overlay = out / 'overlay'
reference = runpy.run_path('tools/test-i386-timeclock-reference.py')
source_hashes = reference['restore_reference'](overlay)
original = args.native_file.read_bytes()
(overlay/'IncomingBridge.DATA').write_bytes(original)
fixture = Path(__file__).with_name('Import.HC').read_bytes()
fixture = fixture.replace(b'C:/IncomingBridge.DATA', b'T:/IncomingBridge.DATA')
fixture = fixture.replace(b'C:/ReturnedBridge.DATA', b'B:/ReturnedBridge.DATA')
bootstrap = b"""while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
#include "T:/Apps/Span/Load.HC"
U0 SpanProbeLog(U8 *s) {while(*s)OutU8(0xE9,*s++);}
"""
capture = b"""
U0 CaptureReturnedBridge()
{
  I64 size;
  U8 *data=FileRead("B:/ReturnedBridge.DATA",&size),line[160];
  if(!data) {SpanProbeLog("FAIL Span RAM disk readback\\n"); return;}
  StrPrint(line,"EXPORT ReturnedBridge.DATA %X %X\\n",data,size);
  SpanProbeLog(line);
  Sleep(2000);
  Free(data);
  SpanProbeLog("SPAN readback done\\n");
}
BridgeImportProbe;
CaptureReturnedBridge;
"""
(overlay/'Once.HC').write_bytes(bootstrap + fixture + capture)
image = out/'original.iso'
subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),
                '--output',str(image)],check=True)
sha = lambda data: hashlib.sha256(data).hexdigest()
report = {'result':'running', 'incoming_sha256':sha(original), 'fixture_sha256':sha(fixture),
    'source_sha256':{name:digest for name,digest in source_hashes.items()
                     if name.startswith('Apps/Span/')}}
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image,out/'guest',False)
try:
    log = guest.wait('SPAN readback done\n',90)
    returned = (out/'guest/ReturnedBridge.DATA').read_bytes()
    report['readback_sha256'] = sha(returned)
    if returned != original or 'FAIL Span' in log:
        raise ValueError('Original Span did not preserve the native bridge file')
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail',error=str(exc))
    raise
finally:
    guest.close()
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
