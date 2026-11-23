import hashlib
import json
from pathlib import Path
import runpy

out=Path(__file__).resolve().parent
base=Path('build/original-user-stack-reserve-v5/candidate.img')
pack=runpy.run_path('tools/package-i386-native-image.py')
snapshot,package=pack['snapshot'],pack['package']
raw=base.read_bytes()
original=snapshot(raw)[1]
startup='/Kernel/I386/StartOS.HC'
prompt=original['/Compiler/I386/MakeCommandPrompt.HC'][2]
disassembler=original['/Compiler/UAsmCore.HC'][2]
include=b'#include "/Compiler/UAsmCore.HC"\n'
setup,tail=prompt.split(include)
split=disassembler.index(b'U0 Ui(')
assert disassembler[:split].rstrip().endswith(b'}')
parts={
    '/Compiler/I386/PromptSetup.HC':setup,
    '/Compiler/I386/PromptUAsmHead.HC':b'#define UASM_CODE_BITS 32\n'+disassembler[:split],
    '/Compiler/I386/PromptUAsmUi.HC':b'#define UASM_CODE_BITS 32\n'+disassembler[split:],
    '/Compiler/I386/PromptFinish.HC':tail,
}
assert (parts['/Compiler/I386/PromptUAsmHead.HC'].split(b'\n',1)[1]+
        parts['/Compiler/I386/PromptUAsmUi.HC'].split(b'\n',1)[1])==disassembler
prefix=b'AdamFile("::/Compiler/I386/MakeCommandPrompt.HC",FALSE);'
before=original[startup][2]
assert before.count(prefix)==1
script=b'\n'.join(f'AdamFile("::{p}",FALSE);'.encode() for p in parts)
after=before.replace(prefix,script)
(out/'StartOS.HC').write_bytes(after)
for p,data in parts.items():
    (out/Path(p).name).write_bytes(data)

def patched(image):
    tree,files,dirs=snapshot(image)
    attr,stamp,_=files[startup]
    tree['Kernel'][2]['I386'][2]['StartOS.HC']=files[startup]=(attr,stamp,after)
    return tree,files,dirs

image=out/'candidate.img'
package.__globals__['snapshot']=patched
try:
    report=package(base,image,additions=parts)
finally:
    package.__globals__['snapshot']=snapshot
data=image.read_bytes()
files=snapshot(data)[1]
assert data[:2048*512]==raw[:2048*512]
assert files.keys()==original.keys() | parts.keys()
assert files[startup][2]==after and all(files[p][2]==v for p,v in parts.items())
assert all(files[p]==v for p,v in original.items() if p!=startup)
report.update(result='pass',base_sha256=hashlib.sha256(raw).hexdigest(),
              candidate_sha256=hashlib.sha256(data).hexdigest(),partition=list(parts))
(out/'packaging.json').write_text(json.dumps(report,indent=2)+'\n')
