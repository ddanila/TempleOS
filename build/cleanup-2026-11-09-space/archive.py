import os,json,hashlib,subprocess
from pathlib import Path
out=Path(__file__).parent
saved=count=0
with (out/'archives.jsonl').open('a') as m:
 for root,ds,fs in os.walk('build'):
  if 'working.img' not in fs:continue
  p=Path(root)/'working.img'
  if p.is_symlink():continue
  s=p.stat()
  if s.st_size<8*1024**2:continue
  z=Path(str(p)+'.zst')
  if z.exists():continue
  h=hashlib.sha256(p.read_bytes()).hexdigest()
  subprocess.run(['zstd','-q','-T2','-3',str(p),'-o',str(z)],check=True)
  proc=subprocess.Popen(['zstd','-q','-d','-c',str(z)],stdout=subprocess.PIPE)
  hh=hashlib.sha256()
  for b in iter(lambda:proc.stdout.read(8*1024**2),b''):hh.update(b)
  assert proc.wait()==0 and hh.hexdigest()==h
  assert p.stat().st_mtime_ns==s.st_mtime_ns
  gain=s.st_blocks*512-z.stat().st_blocks*512
  record=dict(path=str(p),archive=str(z),sha256=h,bytes=s.st_size,reclaimed_bytes=gain,restore=['zstd','-d','--keep',str(z),'-o',str(p)])
  m.write(json.dumps(record)+'\n');m.flush();os.fsync(m.fileno())
  p.unlink();saved+=gain;count+=1
  if count%25==0:print(count,round(saved/2**30,2),'GiB',flush=True)
 summary=dict(archived_files=count,reclaimed_bytes=saved,reclaimed_gib=saved/2**30,verification='decompressed SHA-256 equals original before raw copy removal')
 (out/'archive-summary.json').write_text(json.dumps(summary,indent=2)+'\n');print(summary,flush=True)
