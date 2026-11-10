import os,time,json,hashlib,subprocess
from pathlib import Path
out=Path(__file__).parent
def digest(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1024**2),b''):h.update(b)
 return h.hexdigest()
opened=set()
for p in Path('/proc').glob('[0-9]*/fd/*'):
 try:opened.add(p.resolve())
 except OSError:pass
saved=count=0
with (out/'screenshots-manifest.jsonl').open('x') as log:
 for root,dirs,files in os.walk('build'):
  for name in files:
   p=Path(root)/name
   if not (p.name.endswith('.asm.txt') or p.name=='kernel-assembly.txt' or p.suffix=='.ppm') or p.is_symlink() or p.resolve() in opened:continue
   st=p.stat()
   if st.st_mtime>time.time()-86400:continue
   if p.parent.name in ('i386-module-zero-cross-v1','i386-system-build-date-cross-v3'):continue
   target=Path(str(p)+'.zst')
   if target.exists():continue
   h=digest(p)
   subprocess.run(['zstd','-q','-3','-o',str(target),str(p)],check=True)
   proc=subprocess.Popen(['zstd','-q','-d','-c',str(target)],stdout=subprocess.PIPE)
   check=hashlib.sha256()
   for b in iter(lambda:proc.stdout.read(1024**2),b''):check.update(b)
   assert proc.wait()==0 and check.hexdigest()==h
   now=p.stat();assert (now.st_size,now.st_mtime_ns,now.st_ino)==(st.st_size,st.st_mtime_ns,st.st_ino)
   freed=st.st_blocks*512-target.stat().st_blocks*512
   if freed<=0:target.unlink();continue
   row=dict(path=str(p),archive=str(target),sha256=h,bytes=st.st_size,mode=st.st_mode&0o777,mtime_ns=st.st_mtime_ns,reclaimed_bytes=freed)
   log.write(json.dumps(row)+'\n');log.flush();os.fsync(log.fileno());p.unlink()
   saved+=freed;count+=1
summary=dict(files=count,reclaimed_bytes=saved,reclaimed_gib=saved/2**30,verification='Every archive decompressed and SHA-256 matched before removing raw file')
(out/'screenshots-summary.json').write_text(json.dumps(summary,indent=2)+'\n');print(summary)
