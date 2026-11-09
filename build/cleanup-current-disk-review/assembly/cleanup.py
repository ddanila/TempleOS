import hashlib,json,os,subprocess
from pathlib import Path
out=Path(__file__).parent
rows=[]
def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(4*1024**2),b''):h.update(b)
 return h.hexdigest()
paths=sorted(Path('build').glob('*/kernel-assembly.txt'))
for p in paths:
 if p.is_symlink() or p.stat().st_size<8*1024**2:continue
 if p.parent.name in ('i386-mouse-set-cross-v4','i386-mouse-first-event-cross-v1','i386-kernel','i386-user-startup-cross-v5'):continue
 z=Path(str(p)+'.zst')
 if z.exists():continue
 s=p.stat();h=sha(p);tmp=Path(str(z)+'.cleanup-tmp')
 subprocess.run(['zstd','-q','-3',str(p),'-o',str(tmp)],check=True)
 proc=subprocess.Popen(['zstd','-q','-dc',str(tmp)],stdout=subprocess.PIPE)
 v=hashlib.sha256()
 for b in iter(lambda:proc.stdout.read(4*1024**2),b''):v.update(b)
 assert proc.wait()==0 and v.hexdigest()==h
 t=p.stat();assert (s.st_ino,s.st_size,s.st_mtime_ns)==(t.st_ino,t.st_size,t.st_mtime_ns)
 gain=s.st_blocks*512-tmp.stat().st_blocks*512
 if gain<=0:tmp.unlink();continue
 os.replace(tmp,z)
 row=dict(original=str(p),archive=str(z),sha256=h,size=s.st_size,reclaimed_bytes=gain,restore=['zstd','-d',str(z),'-o',str(p)])
 rows.append(row)
 (out/'manifest.json').write_text(json.dumps(dict(files=rows,reclaimed_bytes=sum(r['reclaimed_bytes'] for r in rows)),indent=2)+'\n')
 p.unlink()
 if len(rows)%10==0:print(len(rows),round(sum(r['reclaimed_bytes'] for r in rows)/2**30,2),'GiB',flush=True)
print('DONE',len(rows),sum(r['reclaimed_bytes'] for r in rows),flush=True)
