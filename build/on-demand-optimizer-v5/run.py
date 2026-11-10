from pathlib import Path
import json,hashlib,subprocess,sys
out=Path(__file__).resolve().parent;sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();base=json.loads(Path('build/i386-emitter-known-cross-v1/result.json').read_text());overrides={str(p.relative_to(out/'overlay')):sha(p) for p in (out/'overlay').rglob('*') if p.is_file()};pins={str(p):sha(p) for p in [Path(__file__),out/'candidate.patch',Path('tools/build-iso.py'),Path('tools/guest-run.py'),Path('build/rebuild-test/result.json')]};r=dict(result='running',scope='Disposable full shared optimizer module cross build only; no loader, namespace publication or production/native/resource qualification.',source_sha256=base['source_sha256'],overrides=overrides,input_sha256=pins)
try:
 base['source_sha256']={name:sha(Path(name)) for name in base['source_sha256']};r['source_sha256']=base['source_sha256']
 subprocess.run([sys.executable,'tools/build-iso.py','--overlay','build/rebuild-test/overlay','--overlay',str(out/'overlay'),'--output',str(out/'compiler.iso')],check=True)
 subprocess.run([sys.executable,'tools/guest-run.py',str(out/'compiler.iso'),'--out',str(out/'exports'),'--qmp-stdio','--timeout','240'],check=True)
 module=out/'exports/OptRuntime.t32m';assert module.is_file();r.update(result='pass',module_bytes=module.stat().st_size,module_sha256=sha(module))
except Exception as e:r.update(result='fail',error=str(e));raise
finally:
 r['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items()) and all(sha(Path(p))==h for p,h in base['source_sha256'].items()) and all(sha(out/'overlay'/p)==h for p,h in overrides.items());assert r['inputs_unchanged'];(out/'result.json').write_text(json.dumps(r,indent=2)+'\n')
