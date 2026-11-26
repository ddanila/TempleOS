import hashlib
import json
from pathlib import Path
import runpy
import sys

disk, out = (Path(value).resolve() for value in sys.argv[1:])
out.mkdir()
valid = b'''
I64 LoopCarry(I64 value)
{
  I64 result=0;
  asm {
    MOV EAX,0
    MOV EBX,0
    STC
    ADC EAX,U32 &value[EBP]
    STC
    ADC EBX,EAX
    STC
    ADC U32 &value[EBP],EBX
    MOV ECX,2
@@again:
    ADD EAX,1
    LOOP I8 @@again
    MOV U32 &result[EBP],EAX
  }
  return result+value;
}
if(LoopCarry(20)!=66)throw('AsmCarry',TRUE);
'''
valid += (b'I64 LoopNear(){asm {MOV ECX,2 LOOP @@far '+b'NOP '*127+
          b'@@far: NOP}return 1;}\nif(LoopNear!=1)throw(\'AsmRange\',TRUE);\n')
invalid = b'I64 LoopTooFar(){asm {LOOP @@far '+b'NOP '*130+b'@@far: NOP}return 0;}\n'
additions = {'/Probe/LoopCarry.HC': valid, '/Probe/LoopTooFar.HC': invalid}
sha = lambda data: hashlib.sha256(data).hexdigest()
source_hash = sha(disk.read_bytes())
report = dict(result='fail', source_disk_sha256=source_hash,
              fixtures={path: sha(data) for path, data in additions.items()})
try:
    image = out/'working.img'
    runpy.run_path('tools/package-i386-native-image.py')['package'](disk,image,additions=additions)
    Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest = Guest(image, out/'guest', True)
    try:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Probe/LoopCarry.HC"')
        start = len(guest.collect())
        guest.type('#include "C:/Probe/LoopTooFar.HC"')
        guest.press('ret')
        log = guest.wait('INPUT REJECT ',start=start)
        if 'Native frontend service unavailable' not in log[start:]:
            raise ValueError('Unexpected guest rejection')
        guest.command('6*7;')
        report['arithmetic_pixels'] = guest.result_pixels()
    finally:
        guest.close()
    report.update(result='pass', accepted_displacement=127, rejected_displacement=130)
finally:
    report['inputs_unchanged'] = sha(disk.read_bytes()) == source_hash
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    assert report['inputs_unchanged']
