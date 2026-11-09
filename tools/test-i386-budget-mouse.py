#!/usr/bin/env python3
"""Drive Budget row/account selection and save/abort with real PS/2 mouse events."""
import argparse,hashlib,json,re,runpy,struct,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
REPORTS=('before.DD','selected.DD','cancelled.DD','rent.DD','first.DD')
NAMES=REPORTS+tuple(n+'.live' for n in REPORTS)+('edit.DD','edit.fields','edit.state','accounts-menu.DD','selected.DD.position','first.DD.position','second-target.bin','rent-target.bin','first-target.bin','mask.bin','data.bin','strings.DD','accounts.DD')
REOPEN=('reopen-before.DD','reopen-before.DD.live','reopen-target.bin','reopen-mask.bin','reopen-data.bin','reopen-strings.DD','reopen-accounts.DD')
POINTER=re.compile(rb',U=0x([0-9A-F]+)\$');MENU_POINTER=re.compile(rb'LE=([0-9]+)')
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def body(rent=False):
 data=b'$FG,1$'
 for i,desc in enumerate(('first','second','third')):
  balance=(100 if rent else -100)*(i+1)
  data+=f'$MU-UL,"09/0{i+4}/98     BANK     RENT:{balance:8.2f}   100.00:{desc}",U=<entry>$\n'.encode()
 return data

def verify(out):
 if (out/'mask.bin').read_bytes()!=struct.pack('<q',1023):raise ValueError('Mouse/restoration mask differs')
 ids=None
 for name in REPORTS:
  d=(out/name).read_bytes();found=POINTER.findall(d)
  if len(found)!=3 or len(set(found))!=3 or not all(int(v,16) for v in found):raise ValueError('Invalid mouse row identities')
  if ids is not None and ids!=found:raise ValueError('Mouse workflow changed row identities')
  ids=found
  if d.count(b'\x05')!=1 or POINTER.sub(b',U=<entry>$',d.replace(b'\x05',b''))!=body(name in ('rent.DD','first.DD')):raise ValueError('Mouse report differs: '+name)
 for name in REPORTS+('reopen-before.DD',):
  raw=(out/(name+'.live')).read_bytes()
  if len(raw)!=216:raise ValueError('Live mouse rows length differs')
  rows=[struct.unpack_from('<9Q',raw,i*72) for i in range(3)]
  actions=[int(v,16) for v in POINTER.findall((out/name).read_bytes())]
  if [r[0] for r in rows]!=actions:raise ValueError('Mouse report actions differ from live rows')
  strings=[v for r in rows for v in r[6:]]
  if any(not 0<v<(1<<31) for r in rows for v in (r[0],)+r[6:]):raise ValueError('Live mouse pointer outside supported RAM')
  if len(set(strings))!=9 or not all(strings):raise ValueError('Mouse normal rows do not own distinct strings')
  for i,r in enumerate(rows):
   if r[1:6]!=((730000+i)<<32,0,0,0x4059000000000000,0):raise ValueError('Live mouse row values differ')
  if name not in ('before.DD','reopen-before.DD') and raw!=(out/'before.DD.live').read_bytes():raise ValueError('Mouse actions changed live row storage')
 if (out/'selected.DD.position').read_bytes()!=struct.pack('<qq',1,2) or (out/'first.DD.position').read_bytes()!=struct.pack('<qq',0,2):raise ValueError('Mouse cursor position differs')
 pairs=[line.split(',',1) for line in (out/'strings.DD').read_text().splitlines()];idx={v:int(k) for k,v in pairs}
 accounts=runpy.run_path(str(ROOT/'tools/test-i386-budget-recurrence.py'))['ACCOUNTS']
 names={'JOB','BANK','CREDIT','CASH','RENT','CAR','UTILITIES','MISC','CLOTHS','HEALTH','CHARITY','first','second','third'}
 if len(pairs)!=14 or set(idx)!=names or [int(k) for k,v in pairs]!=list(range(14)):raise ValueError('Mouse string table differs')
 data=struct.pack('<q',3)
 for i,desc in enumerate(('first','second','third')):data+=struct.pack('<QHHIIId',(730000+i)<<32,0,0,idx['BANK'],idx['RENT'],idx[desc],100.)
 data+=struct.pack('<q',0)
 if (out/'data.bin').read_bytes()!=data or (out/'accounts.DD').read_bytes()!=accounts:raise ValueError('Mouse workflow changed transaction/accounts storage')
 for name in ('second-target.bin','rent-target.bin','first-target.bin','reopen-target.bin'):
  x,y=struct.unpack('<qq',(out/name).read_bytes())
  if not 0<=x<640 or not 0<=y<480:raise ValueError('Mouse target outside display')
 if (out/'reopen-mask.bin').read_bytes()!=struct.pack('<q',63):raise ValueError('Mouse abort/restoration differs')
 for n in ('data.bin','strings.DD','accounts.DD'):
  if (out/('reopen-'+n)).read_bytes()!=(out/n).read_bytes():raise ValueError('Mouse cold reopen changed saved records')
 d=(out/'reopen-before.DD').read_bytes()
 if POINTER.sub(b',U=<entry>$',d.replace(b'\x05',b''))!=body() or d.count(b'\x05')!=1:raise ValueError('Cold report did not reset BANK')
 # Independent prefilled entry form/backing oracle; no decimal parser involved.
 expected=struct.pack('<512sd512s512s512s',b'09/05/98',100.,b'BANK',b'RENT',b'second')
 if (out/'edit.state').read_bytes()!=expected:raise ValueError('Mouse-selected edit does not prefill second row')
 fields=b'Date              :09/05/98_\n    100.00_\nCredit (from) Acct:BANK_\nDebit  (to)   Acct:RENT_\nDesc              :second_\n'
 if (out/'edit.fields').read_bytes()!=fields:raise ValueError('Mouse edit fields differ')
 # The original hash bucket order over the eleven installed accounts.
 order=('JOB','CASH','MISC','CHARITY','RENT','HEALTH','CREDIT','CLOTHS','CAR','UTILITIES','BANK');colors={'JOB':6,'CASH':2,'CREDIT':4,'BANK':1}
 menu=(out/'accounts-menu.DD').read_bytes();links=MENU_POINTER.findall(menu)
 if len(links)!=11 or len(set(links))!=11 or not all(int(v) for v in links):raise ValueError('Mouse account action identities differ')
 expected=b'View Acct\n\n'
 for name in order:expected+=f'$FG,{colors.get(name,0)}$'.encode()+(b'\x05' if name=='BANK' else b'')+f'$MU-UL,"{name}",LE=<account>$\n'.encode()
 if MENU_POINTER.sub(b'LE=<account>',menu)!=expected:raise ValueError('Mouse account menu differs')
 return [POINTER.sub(b',U=<entry>$',(out/n).read_bytes()) for n in REPORTS]+[data,(out/'strings.DD').read_bytes(),accounts,MENU_POINTER.sub(b'LE=<account>',menu),(out/'edit.DD').read_bytes()]

def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--archive',type=Path);ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=a.out.resolve();fixture=ROOT/'tests/guest/i386-budget-mouse/Contract.HC'
 if out.exists():ap.error('Use a fresh output directory')
 if a.disk and not a.reference or not a.disk and not a.archive:ap.error('Native requires --reference; original requires --archive')
 paths=[Path(__file__).resolve(),fixture,ROOT/'docs/i386-compatibility-inventory.json',ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ('test-i386-budget-recurrence.py','i386-budget-source.py','build-iso.py','guest-run.py','test-i386-timeclock-reference.py','package-i386-native-image.py','build-i386-kernel.py','test-i386-timeclock-welcome.py','test-i386-autocomplete-interaction.py')]
 if a.disk:
  gold=a.reference.resolve();r=json.loads((gold/'result.json').read_text())
  if r.get('result')!='pass' or not r.get('inputs_unchanged') or r.get('fixture_sha256')!=sha(fixture):raise ValueError('Matching original control required')
  paths += [a.disk.resolve(),gold/'result.json']+[gold/n for n in NAMES+REOPEN]
 else:paths.append(a.archive.resolve())
 out.mkdir(parents=True);pins={str(p):sha(p) for p in paths};(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());guest=None
 report=dict(result='running',fixture_sha256=sha(fixture),input_sha256=pins,scope='Three constructed/persisted transactions, full Budget: PS/2 select second row, keyboard open/cancel edit, mouse account RENT selection, mouse select first row and double-left-click save. Reopen and double-right-click abort, real cold boot natively. Exact rows/identities/cursors/form/menu/storage, caller restoration and native file/metadata preservation. Not mouse entry creation, whole desktop, settled raster equality or resources qualification.')
 try:
  if not a.disk:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay);(overlay/'Apps/Budget/Accts.DD.Z').write_bytes(a.archive.read_bytes())
   (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;Cd("B:/");DirMk("B:/Home");HomeSet("B:/Home");\n#include "T:/Apps/Budget/Load.HC"\n#include "T:/Apps/Budget/Install.HC"\n'+fixture.read_bytes()+b'\nBudgetMouse;\n')
   image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
  else:
   pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));before=pack['snapshot'](a.disk.read_bytes())[1];expected=runpy.run_path(str(ROOT/'tools/i386-budget-source.py'))['budget_source']
   for e in json.loads((ROOT/'docs/i386-compatibility-inventory.json').read_text())['entries']:
    if e['path'].startswith('Apps/Budget/') and before['/'+e['path']][2]!=expected(e):raise ValueError('Budget source differs: '+e['path'])
   image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions={'/Probe/BudgetMouse.HC':fixture.read_bytes()})
  Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];guest=Guest(image,out/'guest',bool(a.disk))
  commands=['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);','#include "C:/Apps/Budget/Load.HC"','#include "C:/Apps/Budget/Install.HC"','#include "C:/Probe/BudgetMouse.HC"'];report['commands']=commands
  if a.disk:
   guest.wait('DONE native kernel startup\n')
   for c in commands:guest.command(c)
   guest.type('BudgetMouse;');guest.press('ret')
  events=[];phase=0
  def state():
   text=guest.collect();address=int(re.findall(r'BM STATE ([0-9A-F]+)\n',text)[-1],16);p=guest.out/'mouse-state.bin';guest.call('pmemsave',val=address,size=24,filename=str(p));return struct.unpack('<3q',p.read_bytes())
  def move(name):
   target=struct.unpack('<2q',(guest.out/name).read_bytes());deadline=time.monotonic()+15
   if not 0<=target[0]<640 or not 0<=target[1]<480:raise ValueError('Mouse target outside display')
   while time.monotonic()<deadline:
    x,y,b=state();events.append(dict(phase=phase,action='observe',position=[x,y],buttons=b,target=target))
    if (x,y)==target:return
    dx,dy=target[0]-x,target[1]-y;guest.call('input-send-event',events=[{'type':'rel','data':{'axis':'x','value':dx}},{'type':'rel','data':{'axis':'y','value':dy}}]);events.append(dict(phase=phase,action='motion',relative=[dx,dy]));time.sleep(.2)
   raise TimeoutError('Mouse did not reach observed layout target')
  def click(button='left',double=False):
   for i in range(2 if double else 1):
    for down in [True,False]:
     guest.call('input-send-event',events=[{'type':'btn','data':{'down':down,'button':button}}]);events.append(dict(phase=phase,action='button',button=button,down=down,time=time.monotonic()));time.sleep(.08)
    if double:time.sleep(.04)
  guest.wait('BM ready\n');move('second-target.bin');click();guest.wait('BM selected.DD\n',30);time.sleep(1);guest.screenshot('selected')
  guest.press('ret');guest.wait('BM edit ready\n',30);guest.screenshot('edit');guest.key('shift',True);guest.press('esc');guest.key('shift',False);guest.wait('BM edit cancelled\n',30)
  guest.press('v');guest.wait('BM account ready\n',30);move('rent-target.bin');click();guest.wait('BM account selected\n',30);time.sleep(1);guest.screenshot('rent')
  move('first-target.bin');click();guest.wait('BM save ready\n',30);time.sleep(1);guest.screenshot('first');click(double=True);guest.wait('BM done\n',30)
  if a.disk:
   guest.wait('COMMAND OK\n',start=guest.collect().index('INPUT LINE BudgetMouse;'));guest.command('6*7;');report['fresh_result']=guest.result_pixels()
   guest.close();guest=None;persisted=pack['snapshot'](image.read_bytes())[1];guest=Guest(image,out/'guest-reopen',True);guest.wait('DONE native kernel startup\n')
   for c in commands:
    if '/Install.HC' not in c:guest.command(c)
  for n in NAMES:(out/n).write_bytes((out/'guest'/n).read_bytes())
  phase=1;guest.type('BudgetMouse(TRUE);');guest.press('ret');guest.wait('BM reopen ready\n',30);move('reopen-target.bin');time.sleep(1);guest.screenshot('reopened');click('right',True);guest.wait('BM done\n',30,start=guest.collect().rfind('BM STATE'))
  if a.disk:
   guest.wait('COMMAND OK\n',start=guest.collect().index('INPUT LINE BudgetMouse(TRUE);'));guest.command('6*7;');report['reopen_fresh_result']=guest.result_pixels()
  for n in REOPEN:(out/n).write_bytes((guest.out/n).read_bytes())
  guest.close();guest=None
  if a.disk:
   files=pack['snapshot'](image.read_bytes())[1]
   if files!=persisted:raise ValueError('Cold mouse abort changed file bytes or metadata')
   changed={n for n in set(before)|set(files) if before.get(n)!=files.get(n)};allowed={'/Probe/BudgetMouse.HC','/Budget/Accts.DD.Z','/Budget/Strs.DD.Z','/Budget/Bgt.DATA.Z'}
   if changed-allowed:raise ValueError('Unrelated file changed: '+repr(changed-allowed))
   report.update(cold_reopen_files_unchanged=True,changed_files=sorted(changed),preserved_files=len(set(before)-allowed))
  normalized=verify(out)
  if a.disk and normalized!=verify(gold):raise ValueError('Original/native mouse workflow differs')
  report.update(result='pass',mask=1023,reopen_mask=63)
 except Exception as exc:
  report.update(result='fail',error=str(exc))
  if a.disk and guest is not None and guest.p.poll() is None:
   try:
    guest.call('stop');guest.collect();(out/'failure-registers.txt').write_text(guest.call('human-monitor-command',**{'command-line':'info registers'}));guest.call('pmemsave',val=0,size=64*1024*1024,filename=str(out/'failure-memory.bin'));report['failure_capture']={n:sha(out/n) for n in ('failure-memory.bin','failure-registers.txt')}
   except Exception as err:report['capture_error']=str(err)
  raise
 finally:
  if guest is not None:guest.close()
  (out/'mouse-events.json').write_text(json.dumps(locals().get('events',[]),indent=2)+'\n');report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
  if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
