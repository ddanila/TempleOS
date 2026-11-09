#!/usr/bin/env python3
"""Run the unchanged original Demo/MsgLoop.HC through real keyboard and PS/2 input."""
import argparse,hashlib,json,re,runpy,struct,subprocess,time
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def records(data):return [tuple(int(v,16) for v in m) for m in re.findall(rb'CMD:([0-9A-F]{2}) ARG1:([0-9A-F]{8}) ARG2:([0-9A-F]{16})',data)]
def stream_expected(shift=False):
 header=b'Use $LK,"msg_code",A="MN:MSG_CMD"$ defines in your programs instead of hardcoded nums.\n<ESC> to Exit\n'
 scan=lambda half:half|(half<<32)
 rows=[(2,97,scan(0x1e)),(3,97,scan(0x11e))]
 rows += [(code,322,243) for code in [4,5,6,9,10,7,8,5,9,6,10,5]]
 rows += [(2,98,scan(0x10030)),(3,98,scan(0x10130)),(6,322,243)]
 if shift:rows.append((2,0,scan(0x22a)))
 rows.append((2,28 if shift else 27,scan(0x201 if shift else 1)))
 return header+b''.join(f'CMD:{code:02X} ARG1:{arg1:08X} ARG2:{arg2:016X}\n'.encode() for code,arg1,arg2 in rows)+b'\0'

def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--reference',type=Path);ap.add_argument('--shift-exit',action='store_true');ap.add_argument('--frame-barriers',action='store_true',help='Use a full-refresh test document, two real frame barriers per input phase and split key down/up');ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=a.out.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 if a.disk and not a.reference:ap.error('Native requires passing matching original')
 fixture=ROOT/'tests/guest/i386-msg-loop/Contract.HC';program=ROOT/'Demo/MsgLoop.HC';original=subprocess.check_output(['git','show','ce055f205fc38536443289fb1cfc73632f6624f4:Demo/MsgLoop.HC']);assert program.read_bytes()==original
 paths=[fixture,program,Path(__file__).resolve(),ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['build-iso.py','test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','package-i386-native-image.py','build-i386-kernel.py']]
 if a.frame_barriers:paths.append(fixture.with_name('Frames.HC'))
 if a.disk:
  r=json.loads((a.reference/'result.json').read_text());assert r['result']=='pass' and r['inputs_unchanged'] and r['shift_exit']==a.shift_exit and r['fixture_sha256']==sha(fixture)
  assert r.get('frame_barriers',False)==a.frame_barriers
  if a.frame_barriers:assert r['frame_fixture_sha256']==sha(fixture.with_name('Frames.HC'))
  if a.frame_barriers:paths.append(a.reference/'guest/program-final.png')
  paths += [a.disk.resolve(),a.reference/'result.json',a.reference/'msg-loop.DD',a.reference/'msg-loop-return.bin',a.reference/'msg-loop-mask.bin',a.reference/'msg-loop-stream.bin']
 out.mkdir();pins={str(p):sha(p) for p in paths};(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'program.HC').write_bytes(original);(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());g=None;events=[]
 report=dict(result='running',input_sha256=pins,fixture_sha256=sha(fixture),program_sha256=sha(program),shift_exit=a.shift_exit,frame_barriers=a.frame_barriers,scope='Unchanged MsgLoop source loaded with CCF_JUST_LOAD, then its top-level MsgLoop call: real keys, motion, single/double/simultaneous buttons, wheel no-message behavior, typing with left held, Escape/Shift-Escape exit, original output and caller restoration. Not every key/desktop/resource or complete C1-C5 qualification.')
 try:
  if a.frame_barriers:report['frame_fixture_sha256']=sha(fixture.with_name('Frames.HC'))
  harness=fixture.read_bytes()
  if a.frame_barriers:
   start=harness.index(b'U0 MLObserve(');end=harness.index(b'U0 MLStart()',start)
   harness=harness[:start]+fixture.with_name('Frames.HC').read_bytes()+harness[end:]
   harness=harness.replace(b'DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS',b'DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS|DOCF_DO_FULL_REFRESH')
   (out/'frame-fixture.HC').write_bytes(fixture.with_name('Frames.HC').read_bytes())
  if a.frame_barriers:report['render_policy']='DOCF_DO_FULL_REFRESH; two completed document/WinMgr frames after each observed phase; double-click batch retains original timing'
  path='C:/Demo/MsgLoop.HC' if a.disk else 'T:/Demo/MsgLoop.HC';code=harness+f'\nExeFile("{path}",CCF_JUST_LOAD);\nU0 MLRun(){{MLStart;MsgLoop;MLFinish;}}\nMLRun;\n'.encode()
  report['harness_sha256']=hashlib.sha256(code).hexdigest()
  if a.disk:
   pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';source=pack['snapshot'](a.disk.read_bytes())[1];assert source['/Demo/MsgLoop.HC'][2]==original
   report['packaging']=pack['package'](a.disk.resolve(),image,additions={'/Probe/MsgLoopWorkflow.HC':code});before=pack['snapshot'](image.read_bytes())[1]
  else:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay);(overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+code);image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
  Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(a.disk))
  if a.disk:
   g.wait('DONE native kernel startup\n')
   for c in ['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);']:g.command(c)
   g.type('#include "C:/Probe/MsgLoopWorkflow.HC"');g.press('ret')
  g.wait('ML READY\n');time.sleep(.6)
  def wait_count(n):
   g.wait(f'ML COUNT {n}\n',30)
   if a.frame_barriers:g.wait(f'ML FRAME {n}\n',30)
  def typed_key(key,down_count,up_count):
   if a.frame_barriers:
    g.key(key,True);events.append(dict(action='key-down',key=key));wait_count(down_count)
    g.key(key,False);events.append(dict(action='key-up',key=key));wait_count(up_count)
   else:g.press(key);events.append(dict(action='key',key=key));wait_count(up_count)
  def btn(button,down):
   e=[{'type':'btn','data':{'button':button,'down':down}}];g.call('input-send-event',events=e);events.append(dict(action='button',events=e))
  def pause():time.sleep(.6)
  if a.frame_barriers:wait_count(0)
  typed_key('a',1,2)
  e=[{'type':'rel','data':{'axis':'x','value':4}},{'type':'rel','data':{'axis':'y','value':6}}];g.call('input-send-event',events=e);events.append(dict(action='motion',events=e));wait_count(3)
  for button,base in [('left',3),('right',5)]:
   btn(button,True);pause();wait_count(base+1);btn(button,False);pause();wait_count(base+2)
  for down in [True,False,True,False]:btn('left',down);time.sleep(.06)
  pause();wait_count(9)
  for down,count in [(True,11),(False,13)]:
   e=[{'type':'btn','data':{'button':b,'down':down}} for b in ['left','right']];g.call('input-send-event',events=e);events.append(dict(action='simultaneous',events=e));pause();wait_count(count)
  btn('wheel-down',True);btn('wheel-down',False);pause()
  if a.frame_barriers:g.wait('ML WHEEL FRAME\n',30)
  assert 'ML COUNT 14\n' not in g.collect()
  btn('left',True);pause();wait_count(14);typed_key('b',15,16);btn('left',False);pause();wait_count(17)
  if a.shift_exit:g.key('shift',True);events.append(dict(action='key-down',key='shift'));wait_count(18)
  if a.frame_barriers:
   g.key('esc',True);events.append(dict(action='key-down',key='esc'));wait_count(19 if a.shift_exit else 18)
   g.key('esc',False);events.append(dict(action='key-up',key='esc'))
  else:g.press('esc')
  if a.shift_exit:g.key('shift',False);events.append(dict(action='key-up',key='shift'))
  g.wait('ML CAPTURE\n');g.screenshot('program-final')
  if a.frame_barriers:
   screen=Image.open(g.out/'program-final.png').convert('RGB');assert screen.size==(640,480)
   report['raster_sha256']=hashlib.sha256(screen.tobytes()).hexdigest()
   if a.disk:
    expected=Image.open(a.reference/'guest/program-final.png').convert('RGB');assert expected.size==(640,480)
    report['raster_equal']=screen.tobytes()==expected.tobytes()
  for n in ['msg-loop.DD','msg-loop-return.bin','msg-loop-stream.bin']:(out/n).write_bytes((g.out/n).read_bytes())
  data=(out/'msg-loop.DD').read_bytes();parsed=records(data);report['records']=parsed;stream=(out/'msg-loop-stream.bin').read_bytes();report['stream_records']=records(stream)
  expected_count=19 if a.shift_exit else 18
  if len(parsed)!=expected_count:raise ValueError('Program record count differs: '+repr(parsed))
  g.press('q');g.wait('ML DONE\n');(out/'msg-loop-mask.bin').write_bytes((g.out/'msg-loop-mask.bin').read_bytes());(out/'msg-loop-heaps.bin').write_bytes((g.out/'msg-loop-heaps.bin').read_bytes())
  if (out/'msg-loop-mask.bin').read_bytes()!=struct.pack('<q',7):raise ValueError('Program restoration differs')
  if stream!=stream_expected(a.shift_exit):raise ValueError('Program output stream differs from independent original model')
  if a.disk:
   if stream!=(a.reference/'msg-loop-stream.bin').read_bytes():raise ValueError('Program output stream differs from original')
   if data!=(a.reference/'msg-loop.DD').read_bytes() or parsed!=records((a.reference/'msg-loop.DD').read_bytes()):raise ValueError('Program output differs from original')
   if a.frame_barriers and not report['raster_equal']:raise ValueError('Program pixels differ from original')
   if a.frame_barriers:report['pixels']=640*480
   g.command('6*7;');report['fresh_result']=g.result_pixels()
  g.close();g=None
  if a.disk:assert pack['snapshot'](image.read_bytes())[1]==before;report['files_unchanged']=True
  report.update(result='pass',mask=7)
 except Exception as exc:report.update(result='fail',error=str(exc));raise
 finally:
  if g:g.close()
  (out/'events.json').write_text(json.dumps(events,indent=2)+'\n');report['inputs_unchanged']=all(p.is_file() and sha(p)==h for p,h in ((Path(n),h) for n,h in pins.items()))
  if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
