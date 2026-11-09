#!/usr/bin/env python3
"""Check exact MsHardSet source rebases pending physical packets and preserves raw API."""
import argparse,hashlib,json,re,runpy,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def compiled():
 header=(ROOT/'Kernel/I386/Mouse.HH').read_text();a=header.index('class CI386MouseState');b=header.index('};',a)+2;header=header[a:b].replace('CI386MouseState','CMPState')
 queue=(ROOT/'Kernel/I386/MouseEventQueue.HC').read_text()
 for old,new in [('CI386MouseEvents','CMPPackets'),('CI386MouseEvent','CMPEvent'),('I386MouseEventPush','MPPush'),('I386MouseEventPop','MPPop')]:queue=queue.replace(old,new)
 core=(ROOT/'Kernel/MouseHardPositionCore.HC').read_text().replace('MouseHardPositionCore','MPPosition')
 source=(ROOT/'Kernel/I386/MouseStateRuntime.HC').read_text();a=source.index('U0 MsHardSet(');b=source.index('\n#define MOUSE_SET_FUNCTION',a);source=source[a:b]
 names={'MsHardSet':'MPSet','NativeMouseDecoderInit':'MPInit','native_mouse_hard_prescale':'mp_hard','native_mouse_set_pending':'mp_pending','native_mouse_set_prescale':'mp_set','native_mouse_hard_scale':'mp_scale','native_mouse_irq_state':'mp_irq','native_mouse_irq_z':'mp_irq_z','native_mouse_packets':'mp_packets','native_mouse_packet_z':'mp_z','native_mouse_set_buttons':'mp_buttons','native_mouse_set_stamp':'mp_stamp','native_input_mouse':'mp_input','NativeTimeStamp':'MPTick','MouseHardPositionCore':'MPPosition','ms':'mp_ms','ms_grid':'mp_grid'}
 source=re.sub(r'\b('+'|'.join(names)+r')\b',lambda m:names[m.group()],source)
 return header+'\n'+queue+'\n'+core+'''\nCMPState mp_irq;CMPPackets mp_packets;CD3I64 mp_hard,mp_set;CD3 mp_scale;
CMsStateGlbls mp_ms;CGridGlbls mp_grid;I64 mp_irq_z,mp_z[64],mp_stamp;U32 mp_buttons;Bool mp_pending;
class CMPInput {I64 timestamp;};CMPInput mp_input;
U0 MPInit(){}\nI64 MPTick(){return 12345;}\n'''+source

def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=a.out.resolve();fixture=ROOT/'tests/guest/i386-mouse-set-queue/Contract.HC'
 if out.exists():ap.error('Use a fresh output directory')
 sources=[ROOT/n for n in ['Kernel/I386/Mouse.HH','Kernel/I386/MouseEventQueue.HC','Kernel/MouseHardPositionCore.HC','Kernel/I386/MouseStateRuntime.HC']]
 paths=[a.disk.resolve(),fixture,Path(__file__).resolve(),ROOT/'Kernel/FontStd.HC']+sources+[ROOT/('tools/'+n) for n in ['package-i386-native-image.py','build-i386-kernel.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py']]
 out.mkdir();pins={str(p):sha(p) for p in paths};code=compiled().encode()+fixture.read_bytes();(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'compiled.HC').write_bytes(code);(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());g=None
 report=dict(result='running',input_sha256=pins,scope='Exact delivered native MsHardSet source in isolated state: pending packet wrap/rebase/repeated sets, metadata/guards, fractional grid speeds and clipping. Clock/init are stubs in this source probe. Real MsSet also preserves raw MouseGet, IF and heap. Not live pending-IRQ interleavings, full ms_hard or C1-C5.')
 try:
  pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));source=pack['snapshot'](a.disk.read_bytes())[1]
  for p in sources:assert source['/'+str(p.relative_to(ROOT))][2]==p.read_bytes(),p
  image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions={'/Probe/MouseSetQueue.HC':code});before=pack['snapshot'](image.read_bytes())[1]
  Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',True);g.wait('DONE native kernel startup\n');g.command('#include "C:/Probe/MouseSetQueue.HC"');g.command('MouseSetQueueContract;')
  raw=(out/'guest/set-queue-mask.bin').read_bytes();(out/'set-queue-mask.bin').write_bytes(raw)
  if raw!=struct.pack('<q',63):raise ValueError('MsSet queue/raw API mask differs: '+repr(struct.unpack('<q',raw)))
  g.command('6*7;');report['fresh_result']=g.result_pixels();g.close();g=None;assert pack['snapshot'](image.read_bytes())[1]==before
  report.update(result='pass',mask=63,files_unchanged=True)
 except Exception as exc:report.update(result='fail',error=str(exc));raise
 finally:
  if g:g.close()
  report['inputs_unchanged']=all(p.is_file() and sha(p)==h for p,h in ((Path(n),h) for n,h in pins.items()))
  if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
