"""Restore one archived raw file, or all with --all, preserving compressed recovery copy."""
import hashlib,json,os,subprocess,sys
from pathlib import Path
rows=[json.loads(l) for l in Path(__file__).with_name('screenshots-manifest.jsonl').read_text().splitlines()]
selected=rows if sys.argv[1:] == ['--all'] else [r for r in rows if r['path'] in sys.argv[1:]]
assert selected,'Specify an original path from screenshots-manifest.jsonl, or --all'
for r in selected:
 p=Path(r['path'])
 if p.exists():assert hashlib.sha256(p.read_bytes()).hexdigest()==r['sha256'];continue
 tmp=p.with_name(p.name+'.restore-tmp')
 with tmp.open('xb') as f:subprocess.run(['zstd','-q','-d','-c',r['archive']],stdout=f,check=True)
 assert hashlib.sha256(tmp.read_bytes()).hexdigest()==r['sha256']
 os.chmod(tmp,r['mode']);os.utime(tmp,ns=(r['mtime_ns'],r['mtime_ns']));os.replace(tmp,p)
 print(p)
