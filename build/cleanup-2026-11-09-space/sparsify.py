import os,hashlib,json,subprocess,time
from pathlib import Path
out=Path(__file__).parent
files=[]
for root,dirs,names in os.walk('build'):
 for name in names:
  p=Path(root)/name
  if p.is_symlink() or p.suffix not in ('.img','.bin','.iso'):continue
  s=p.stat()
  if s.st_size>=8*1024**2 and s.st_blocks*512>1024**2:files.append(p)
def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(8*1024**2),b''):h.update(b)
 return h.hexdigest()
seen=set();saved=0;count=0
with (out/'manifest.jsonl').open('a') as m:
 for p in files:
  s=p.stat()
  if (s.st_dev,s.st_ino) in seen:continue
  seen.add((s.st_dev,s.st_ino))
  h=sha(p)
  assert p.stat().st_mtime_ns==s.st_mtime_ns
  subprocess.run(['fallocate','--dig-holes',str(p)],check=True)
  after=p.stat()
  assert after.st_size==s.st_size and sha(p)==h
  gain=(s.st_blocks-after.st_blocks)*512;saved+=gain;count+=1
  m.write(json.dumps(dict(path=str(p),sha256=h,bytes=s.st_size,reclaimed_bytes=gain,action='deallocate-zero-blocks-content-unchanged'))+'\n');m.flush()
  if count%50==0:print(count,round(saved/2**30,2),'GiB reclaimed',flush=True)
summary=dict(verified_files=count,reclaimed_bytes=saved,reclaimed_gib=saved/2**30,all_hashes_unchanged=True)
(out/'summary.json').write_text(json.dumps(summary,indent=2)+'\n');print(summary,flush=True)
