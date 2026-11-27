from pathlib import Path
from runpy import run_path
from hashlib import sha256
import json,re,sys,time
ram=int(sys.argv[3])
image=Path(sys.argv[1])
out=Path(sys.argv[2])
out.mkdir()
guest=run_path('tools/test-i386-autocomplete-interaction.py')['Guest'](
    image,out/'guest',True,ram_mib=ram,native_options=('-snapshot',))
analyze=run_path('tools/profile-i386-startup-memory.py')['analyze']
def sample(name):
    target=out/f'{name}.bin'
    guest.call('stop')
    try:
        guest.call('pmemsave',val=0,size=ram*1024*1024,filename=str(target))
        log=guest.collect()
    finally:
        guest.call('cont')
    raw=target.read_bytes()
    data=analyze(image,log,raw)
    return {k:data[k] for k in ('capacity','used','largest_free','allocations','failure_callers')}|{'sha256':sha256(raw).hexdigest()}
def sha(path):
    return sha256(path.read_bytes()).hexdigest()
report={'image_sha256':sha(image),'ram_mib':ram,'cpu':'486,-fpu'}
try:
    deadline=time.monotonic()+180
    while 'DONE native kernel startup\n' not in guest.collect():
        if time.monotonic()>deadline or guest.p.poll() is not None:
            raise TimeoutError('Missing completed startup marker')
        time.sleep(.1)
    report['startup_rejections']=[line for line in guest.collect().splitlines()
        if line.startswith(('PARSER CODE STORAGE REJECT','INPUT REJECT '))]
    report['prompt']=sample('prompt')
    guest.command('U0 DDCheck(I64 n){U8 *s=MStrPrint("DOC CHECK RET %d\\n",n),*p=s;while(*p)OutU8(0xE9,*p++);Free(s);}DDCheck(DocAllocationCheck);')
    log=guest.collect()
    report['returned']=int(re.search(r'^DOC CHECK RET (-?\d+)$',log,re.M)[1])
    report['after']=sample('after')
    report['result']='pass' if report['returned']==13 else 'fail'
    report['load_recovery_unload']=[log.count(s) for s in ('DOC DIAGNOSTIC loaded\n','DOC DOLLAR GROWTH recovery\n','DOC DIAGNOSTIC unloaded\n')]
    guest.command('6*7;')
    guest.result_pixels()
    report['caller_arithmetic']=42
except Exception as error:
    report.update(result='fail',error=str(error))
    raise
finally:
    guest.close()
    report['inputs_unchanged']=sha(image)==report['image_sha256']
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
