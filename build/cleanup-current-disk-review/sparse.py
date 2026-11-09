import os,hashlib,json,subprocess
from pathlib import Path
root=Path('build'); out=root/'cleanup-current-disk-review'; saved=0; count=0
with (out/'manifest.jsonl').open('x') as log:
 for d,ds,fs in os.walk(root):
  for n in fs:
   p=Path(d)/n
   if p.is_symlink() or p.suffix not in ('.img','.iso','.bin'):continue
   s=p.stat()
   if s.st_size<16*1024**2 or s.st_blocks*512<16*1024**2:continue
   def digest():
    h=hashlib.sha256()
    with p.open('rb') as f:
     for b in iter(lambda:f.read(4*1024**2),b''):h.update(b)
    return h.hexdigest()
   before=digest()
   subprocess.run(['fallocate','--dig-holes',str(p)],check=True)
   after=p.stat()
   assert digest()==before and after.st_size==s.st_size
   delta=(s.st_blocks-after.st_blocks)*512
   if delta:
    row=dict(path=str(p),sha256=before,bytes=s.st_size,reclaimed_bytes=delta,method='zero ranges converted to sparse holes; complete SHA256 verified')
    log.write(json.dumps(row)+'\n');log.flush();saved+=delta;count+=1
    if count%25==0:print(count,round(saved/2**30,3),'GiB',flush=True)
(out/'summary.json').write_text(json.dumps(dict(files=count,reclaimed_bytes=saved,method='byte-preserving sparse files; no files removed'),indent=2)+'\n')
print('DONE',count,saved,flush=True)
