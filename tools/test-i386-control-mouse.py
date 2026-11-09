#!/usr/bin/env python3
"""Compare actual WinMgr control clicks and captured dragging with original rules."""
import argparse,hashlib,json,re,runpy,struct,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def verify(out):
    if (out/'control-mask.bin').read_bytes()!=struct.pack('<q',15):raise ValueError('Control caller/heap restoration differs')
    raw=(out/'control-rows.bin').read_bytes()
    if len(raw)%64:raise ValueError('Malformed control callback records')
    rows=list(struct.iter_unpack('<8q',raw));summary=[]
    if any(not 0<=r[0]<8 or r[5:]!=(1,1,1) for r in rows):raise ValueError('Wrong callback task/owner/IRQ state')
    for phase in range(8):
        g=struct.unpack('<7q',(out/f'control-target-{phase}.bin').read_bytes());flags=g[2]
        border=8 if flags&2 else 0;start=(g[3]-g[0]+border,g[4]-g[1]+border);end=(g[5]-g[0]+border,g[6]-g[1]+border)
        rr=[r for r in rows if r[0]==phase];side=phase&1
        if phase>=6:
            if rr:raise ValueError('Inhibited controls received callbacks')
        elif phase<4:
            if [(r[1],r[2],r[3],r[4]) for r in rr]!=[(side,1,*start),(side,0,*start)]:raise ValueError('Ordinary control press/release differs: '+str(phase))
        else:
            if len(rr)<4 or any(r[1]!=side for r in rr) or any(not r[2] for r in rr[:-1]) or rr[-1][2]!=0:raise ValueError('Captured callback sequence differs: '+str(phase))
            if rr[0][3:5]!=start or rr[-1][3:5]!=end or sum(r[3:5]==start for r in rr[:-1])<2 or sum(r[3:5]==end for r in rr[:-1])<2:raise ValueError('Capture did not repeat stationary/outside or release outside')
            # A large relative move arrives in several standard PS/2 packets.
            # Every callback must stay on a monotone bounded drag to the endpoint.
            for axis in range(2):
                values=[r[3+axis] for r in rr]
                if any(not start[axis]<=v<=end[axis] for v in values) or values!=sorted(values):raise ValueError('Captured drag path differs')
        summary.append(dict(phase=phase,callbacks=len(rr),side=side,start=start,end=end))
    return summary

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--reference',type=Path);ap.add_argument('--raw',action='store_true');ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=a.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    if a.disk and not a.reference:ap.error('Native requires passing original --reference')
    fixture=ROOT/'tests/guest/i386-control-mouse/Contract.HC'
    paths=[Path(__file__).resolve(),fixture,ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py']]
    if a.disk:
        ref=json.loads((a.reference/'result.json').read_text())
        if ref.get('raw',False)!=a.raw:raise ValueError('Reference raw mode differs')
        if ref['result']!='pass' or not ref['inputs_unchanged'] or ref['fixture_sha256']!=sha(fixture):raise ValueError('Matching original control required')
        verify(a.reference);paths += [a.disk.resolve(),a.reference/'result.json']
    out.mkdir();pins={str(p):sha(p) for p in paths};(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());g=None;events=[]
    invocation='ControlMouseContract(TRUE);' if a.raw else 'ControlMouseContract;'
    report=dict(result='running',raw=a.raw,input_sha256=pins,fixture_sha256=sha(fixture),scope='Actual PS/2 ordinary left/right and border coordinates, captured left/right repeated stationary/drag outside/release outside, self/focus control inhibition, yielding callback identity/owner/IRQ state and caller/child/heap restoration. Not all controls, raster, wheel or asynchronous retirement qualification.')
    try:
        if a.disk:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions={'/Probe/ControlMouse.HC':fixture.read_bytes()});before=pack['snapshot'](image.read_bytes())[1]
        else:
            overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+fixture.read_bytes()+b'\n'+invocation.encode()+b'\n')
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(a.disk))
        if a.disk:
            g.wait('DONE native kernel startup\n')
            for c in ['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);','#include "C:/Probe/ControlMouse.HC"']:g.command(c)
            g.type(invocation);g.press('ret')
        def state():
            address=int(re.findall(r'CM STATE ([0-9A-F]+)\n',g.collect())[-1],16);p=g.out/'mouse-state.bin';g.call('pmemsave',val=address,size=24,filename=str(p));return struct.unpack('<3q',p.read_bytes())
        def move(x,y):
            deadline=time.monotonic()+15
            while time.monotonic()<deadline:
                sx,sy,b=state();events.append(dict(phase=phase,action='observe',position=[sx,sy],buttons=b,target=[x,y]))
                if (sx,sy)==(x,y):return
                relative=[x-sx,y-sy]
                g.call('input-send-event',events=[{'type':'rel','data':{'axis':'x','value':relative[0]}},{'type':'rel','data':{'axis':'y','value':relative[1]}}])
                events.append(dict(phase=phase,action='motion',relative=relative,target=[x,y]))
                # Original hardware scaling can reduce a relative move. Await a
                # changed, settled observation before computing the next correction;
                # never resend against the stale pre-injection position.
                previous=(sx,sy);stable=0;sent=time.monotonic()
                while time.monotonic()<deadline:
                    nx,ny,nb=state();events.append(dict(phase=phase,action='ack',position=[nx,ny],buttons=nb,target=[x,y]))
                    stable=stable+1 if (nx,ny)==previous else 0;previous=(nx,ny)
                    if time.monotonic()-sent>=.75 and stable>=3:break
                    time.sleep(.1)
            raise TimeoutError('Pointer did not reach target')
        for phase in range(8):
            g.wait(f'CM READY {phase}\n');n=f'control-target-{phase}.bin';data=(g.out/n).read_bytes();(out/n).write_bytes(data);target=struct.unpack('<7q',data)
            move(*target[3:5]);button='right' if phase&1 else 'left'
            for down in [True,False]:
                g.call('input-send-event',events=[{'type':'btn','data':{'button':button,'down':down}}]);events.append(dict(phase=phase,action='button',button=button,down=down));time.sleep(.5)
                if down and phase in [4,5]:move(*target[5:7]);time.sleep(.5)
            g.press('n')
        g.wait('CM DONE\n')
        for n in ['control-rows.bin','control-mask.bin','control-mode.bin']:(out/n).write_bytes((g.out/n).read_bytes())
        if (out/'control-mode.bin').read_bytes()!=struct.pack('<2q',int(a.raw),int(a.raw)):raise ValueError('Control fixture display/input mode differs')
        report['observed']=verify(out)
        if a.disk:g.command('6*7;');report['fresh_result']=g.result_pixels()
        g.close();g=None
        if a.disk:
            if pack['snapshot'](image.read_bytes())[1]!=before:raise ValueError('Unexpected file bytes/metadata changes')
            report['files_unchanged']=True
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc))
        if a.disk and g is not None and g.p.poll() is None:
            try:
                g.call('stop');g.collect();(out/'failure-registers.txt').write_text(g.call('human-monitor-command',**{'command-line':'info registers'}));g.call('pmemsave',val=0,size=64*1024*1024,filename=str(out/'failure-memory.bin'));report['failure_capture']={n:sha(out/n) for n in ['failure-memory.bin','failure-registers.txt']}
            except Exception as e:report['capture_error']=str(e)
        raise
    finally:
        if g:g.close()
        (out/'mouse-events.json').write_text(json.dumps(events,indent=2)+'\n');report['inputs_unchanged']=all(p.is_file() and sha(p)==h for p,h in ((Path(n),h) for n,h in pins.items()))
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
