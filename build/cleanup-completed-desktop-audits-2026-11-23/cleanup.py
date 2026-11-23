import hashlib,json,os,subprocess
from pathlib import Path
out=Path(__file__).parent
rows=[]
def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(4*1024**2),b''):h.update(b)
 return h.hexdigest()
paths=[Path('build')/name/'kernel-assembly.txt' for name in (
 'default-home-production-build-v1',
 'i386-default-home-cross-v1',
 'desktop-normal-boot-instruction-v1',
 'i386-desktop-handoff-cross-v2',
 'default-home-parser-budget-instruction-v1',
 'default-home-production-build-v2',
 'i386-public-lex-cross-v3',
 'i386-default-home-cross-v2',
 'parser-selector-production-build-v1',
 'desktop-handoff-production-build-audit-v1',
 'i386-parser-selector-cross-v1',
 'parser-record-select-build-v1',
 'i386-parser-record-select-cross-v1',
 'code-header-known-build-v2',
 'i386-code-header-known-cross-v2',
 'code-header-known-build-v4',
 'i386-code-header-known-cross-v4',
 'i386-system-build-date-cross-v3',
 'i386-module-zero-cross-v1',
)]
for p in paths:
 if not p.is_file() or p.is_symlink() or p.stat().st_size<8*1024**2:continue
 receipt=json.loads((p.parent/'result.json').read_text())
 if receipt.get('result')!='pass' and receipt.get('boot_instruction_audit',{}).get('result')!='pass':continue
 tracked=subprocess.check_output(['git','ls-files','--',str(p)],text=True)
 if tracked:continue
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
