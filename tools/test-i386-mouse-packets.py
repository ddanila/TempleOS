#!/usr/bin/env python3
"""Exhaustive original packet arithmetic versus exact native stream decoder source."""
import argparse,hashlib,json,runpy,struct,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
REFERENCE='ce055f205fc38536443289fb1cfc73632f6624f4'
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def original_math():
 source=subprocess.check_output(['git','show',REFERENCE+':Kernel/SerialDev/Mouse.HC']).decode()
 a=source.index('  ms_hard.bttns[0] =',source.index('U0 MsHardHndlr()'));z=source.index('  ms_hard.prescale.x+=',a)
 body=source[a:z].replace('ms_hard.bttns','buttons')
 return 'U0 PacketMath(U8 *ms_buf,I64 *r)\n{\n  I64 dx,dy,dz;Bool buttons[5];\n'+body+'  r[0]=dx;r[1]=dy;r[2]=dz;r[3]=buttons[0]+2*buttons[1]+4*buttons[2]+8*buttons[3]+16*buttons[4];\n}\n'
def decoder(native):
 math=original_math()
 if not native:return math+'''U0 PacketDecode(U8 h,U8 a,U8 b,U8 c,I64 size,I64 *r)
{U8 bytes[4];bytes[0]=h;bytes[1]=a;bytes[2]=b;bytes[3]=c;PacketMath(bytes,r);r[4]=1;}
'''
 header=(ROOT/'Kernel/I386/Mouse.HH').read_text();start=header.index('class CI386MouseState');end=header.index('};',start)+2
 cls=header[start:end].replace('CI386MouseState','CPacketState')
 if 'packet_size' not in cls:cls=cls.replace('bytes[3],count,installed;','bytes[3],count,installed,packet_size,protocol_flags,fourth;')
 core=(ROOT/'Kernel/I386/MouseFeedCore.HC').read_text();core=core[core.index('public Bool MOUSE_FEED_FUNCTION'):].replace('MOUSE_FEED_FUNCTION','PacketFeed').replace('CI386MouseState','CPacketState')
 helper=ROOT/'Kernel/MousePacketCore.HC';dependencies=helper.read_text() if helper.exists() else ''
 core='\n'.join(l for l in core.splitlines() if not l.startswith('#include'))+'\n'
 return math+cls+'\n#assert sizeof(CPacketState)==40;\n#assert offset(CPacketState.count)==35;\n#assert offset(CPacketState.installed)==36;\n#define MOUSE_FEED_UNBOUNDED\n'+dependencies+core+'''U0 PacketDecode(U8 h,U8 a,U8 b,U8 c,I64 size,I64 *r)
{
  CPacketState state;U8 bytes[4];I64 decoded[4];
  MemSet(&state,0,sizeof(CPacketState));state.installed=TRUE;state.packet_size=size;
  PacketFeed(&state,h,0x20);PacketFeed(&state,a,0x20);PacketFeed(&state,b,0x20);
  if(size==4)PacketFeed(&state,c,0x20);
  bytes[0]=h;bytes[1]=a;bytes[2]=b;bytes[3]=state.fourth;PacketMath(bytes,decoded);
  r[0]=state.x;r[1]=state.y;r[2]=decoded[2];r[3]=state.buttons|(decoded[3]&24);
  r[4]=state.count==0 && state.packets==1 && state.dropped==0 && (size==3 || state.fourth==c);
}
'''
def verify(out,reference=None):
 raw=(out/'packet-rows.bin').read_bytes()
 if len(raw)!=10240*40:raise ValueError('Packet rows length differs')
 rows=list(struct.iter_unpack('<5q',raw))
 if reference and raw!=(reference/'packet-rows.bin').read_bytes():
  gold=list(struct.iter_unpack('<5q',(reference/'packet-rows.bin').read_bytes()));bad=[i for i,(a,b) in enumerate(zip(rows,gold)) if a!=b];raise ValueError('Packet values/assembly differ at '+str(len(bad))+' cases; first '+repr(bad[:8]))
 return rows

def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=a.out.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 if a.disk and not a.reference:ap.error('Native requires passing original')
 fixture=ROOT/'tests/guest/i386-mouse-packets/Contract.HC';paths=[fixture,Path(__file__).resolve()]+[ROOT/('tools/'+n) for n in ['test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py']]
 if a.disk:
  ref=json.loads((a.reference/'result.json').read_text());assert ref['result']=='pass' and ref['inputs_unchanged'] and ref['fixture_sha256']==sha(fixture)
  paths += [a.disk.resolve(),a.reference/'result.json',a.reference/'packet-rows.bin',ROOT/'Kernel/I386/Mouse.HH',ROOT/'Kernel/I386/MouseFeedCore.HC']
  if (ROOT/'Kernel/MousePacketCore.HC').exists():paths.append(ROOT/'Kernel/MousePacketCore.HC')
 out.mkdir();pins={str(p):sha(p) for p in paths};code=decoder(bool(a.disk)).encode()+fixture.read_bytes();(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'compiled.HC').write_bytes(code);(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());g=None
 report=dict(result='running',input_sha256=pins,fixture_sha256=sha(fixture),scope='Original MsHardHndlr arithmetic compiled unchanged except explicit local outputs; exact native decoder source in layout-preserving40-byte probe with unbounded coordinates. Exhaustive signed axes/button combinations and all wheel bytes. Not live IRQ, negotiation, malformed-stream/timing or whole input qualification.')
 try:
  if a.disk:
   pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions={'/Probe/MousePackets.HC':code});before=pack['snapshot'](image.read_bytes())[1]
  else:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
   (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+code+b'\nPacketContract;\n');image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
  Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(a.disk))
  if a.disk:g.wait('DONE native kernel startup\n');g.command('#include "C:/Probe/MousePackets.HC"');g.type('PacketContract;');g.press('ret')
  g.wait('PACKET DONE\n');(out/'packet-rows.bin').write_bytes((g.out/'packet-rows.bin').read_bytes());rows=verify(out,a.reference if a.disk else None)
  report['cases']=len(rows);report['wheel_values']=[rows[8192+i][2] for i in range(16)]
  if a.disk:g.command('6*7;');report['fresh_result']=g.result_pixels()
  g.close();g=None
  if a.disk:
   assert pack['snapshot'](image.read_bytes())[1]==before;report['files_unchanged']=True
  report['result']='pass'
 except Exception as exc:report.update(result='fail',error=str(exc));raise
 finally:
  if g:g.close()
  report['inputs_unchanged']=all(p.is_file() and sha(p)==h for p,h in ((Path(n),h) for n,h in pins.items()))
  if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
