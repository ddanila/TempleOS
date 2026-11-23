from pathlib import Path
import subprocess

root = Path(__file__).resolve().parent
attempt = root / 'cross-explicit-branch'
attempt.mkdir(exist_ok=True)
overlay = root / 'overlay'
sources = {}

def edit(name, old, new):
    source = sources.get(name, Path(name).read_bytes())
    old, new = old.encode(), new.encode()
    if source.count(old) != 1:
        raise ValueError(f'Expected one edit location in {name}: {old!r}')
    sources[name] = source.replace(old, new)

soft = 'Kernel/I386/SoftF64.HC'
helper = Path('build/grmodels-ball-reference-v1/WideProduct.HC').read_bytes()
helper = helper.replace(
    b'I64 BallWideMultiplyToI64(F64 left,F64 right)\n{\n  U64 a=left(U64),b=right(U64),negative=(a^b)>>63;',
    b'public I64 I386F64MulToI64(U64 a,U64 b)\n{\n  U64 negative=(a^b)>>63;')
sources[soft] = Path(soft).read_bytes() + b'\n' + helper

header = 'Kernel/I386/SoftF64.HH'
edit(header, 'public extern I64 I386F64ToI64(U64 value);',
     'public extern I64 I386F64ToI64(U64 value);\npublic extern I64 I386F64MulToI64(U64 a,U64 b);')

frontend = 'Compiler/I386/Frontend.HC'
edit(frontend, 'CHashFun functions[10];\n  CMemberLst arguments[20];\n  U8 *addresses[10];',
     'CHashFun functions[11];\n  CMemberLst arguments[22];\n  U8 *addresses[11];')
edit(frontend, r'I386F64ToI64\0I386F64Compare";', r'I386F64ToI64\0I386F64Compare\0I386F64MulToI64";')
edit(frontend, 'for(i=0;i<10;i++,name+=StrLen(name)+1)',
     'bound->addresses[10]=&I386F64MulToI64;\n  for(i=0;i<11;i++,name+=StrLen(name)+1)')
edit(frontend, 'bound->has_helpers && i<10', 'bound->has_helpers && i<11')

backend = 'Compiler/I386/BackendCore.HC'
edit(backend, '    case IC_MUL: name="I386F64Mul"; break;',
     '    case IC_MUL: name="I386F64Mul"; break;\n    case I386_WIDE_PRODUCT: name="I386F64MulToI64"; return_type=RT_I64; break;')
edit(backend, 'U0 I386F64Runtime(', '#define I386_WIDE_PRODUCT -1\nU0 I386F64Runtime(')
edit(backend, '              I386F64Runtime(backend,out,ic->ic_code,pass);\n            else if(c',
     '''              if (ic->ic_code==IC_MUL && (ic->ic_flags&ICF_RES_TO_INT))
                I386F64Runtime(backend,out,I386_WIDE_PRODUCT,pass);
              else
                I386F64Runtime(backend,out,ic->ic_code,pass);
            else if(c''')
edit(backend, '        if (ic->ic_flags&(ICF_RES_TO_F64|ICF_RES_TO_INT)) {',
     '''        if ((ic->ic_flags&(ICF_RES_TO_F64|ICF_RES_TO_INT)) &&
            !(ic->ic_code==IC_MUL && I386IsF64(c) && (ic->ic_flags&ICF_RES_TO_INT))) {''')

math = 'Kernel/I386/MathPublic.HC'
source = Path(math).read_bytes().replace(b'[27]', b'[28]').replace(b'i<27', b'i<28')
source = source.replace(rb'_EXP\0"', rb'_EXP\0I386F64MulToI64\0"')
source = source.replace(b'  addresses[26]=&Exp;', b'  addresses[26]=&Exp;\n  addresses[27]=&I386F64MulToI64;')
sources[math] = source

for name, source in sources.items():
    output = overlay / name
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(source)

subprocess.run(['python3', 'tools/build-iso.py',
                '--overlay', 'build/span-production-v1/bootstrap/overlay',
                '--overlay', 'tools/guest/i386-kernel', '--overlay', str(overlay),
                '--output', str(attempt/'compiler.iso')], check=True)
subprocess.run(['python3', 'tools/guest-run.py', str(attempt/'compiler.iso'),
                '--qmp-stdio', '--timeout', '240', '--out', str(attempt/'exports')], check=True)
