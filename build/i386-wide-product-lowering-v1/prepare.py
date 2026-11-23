import argparse
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument('--shared-multiply', action='store_true')
parser.add_argument('--primary-minimum', action='store_true')
args = parser.parse_args()
if args.primary_minimum and not args.shared_multiply:
    parser.error('--primary-minimum requires --shared-multiply')
if args.primary_minimum:
    attempt = root / 'cross-primary-minimum'
    overlay = attempt / 'overlay'
elif args.shared_multiply:
    attempt = root / 'cross-shared-multiply'
    overlay = attempt / 'overlay'
else:
    attempt = root / 'cross-explicit-branch'
    overlay = root / 'overlay'
attempt.mkdir(exist_ok=True)
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
source = Path(soft).read_bytes()
if args.shared_multiply:
    declaration = source.index(b'public U64 I386F64Mul(')
    start = source.index(b'  exp=a>>52; other=b>>52;', declaration)
    end = source.index(b'  x=(high<<15)', start)
    product = source[start:end]
    shared = b'''I64 I386F64Product(U64 a,U64 b,U64 *lower,U64 *upper)
{
  U64 frac=0x000FFFFFFFFFFFFF,x,y,low,middle,high;
  I64 exp,other;
''' + product + b'''  *lower=low;
  *upper=high;
  return exp;
}

'''
    mul = source[declaration:start].replace(
        b'quiet=0x0008000000000000,frac=0x000FFFFFFFFFFFFF;',
        b'quiet=0x0008000000000000;')
    mul = mul.replace(b'x,y,low,middle,high;', b'x,low,high;').replace(
        b'I64 exp,other;', b'I64 exp;')
    source = source[:declaration] + shared + mul + b'  exp=I386F64Product(a,b,&low,&high);\n' + source[end:]
    start = helper.index(b'  exp_a=a>>52;')
    end = helper.index(b'  significand=', start)
    helper = helper[:start] + b'''  exponent=I386F64Product(a,b,&low,&high)-1023;
  shift=41+(high>>41);
  exponent+=shift-41;
''' + helper[end:]
    helper = helper.replace(b'  U64 fraction=0x000FFFFFFFFFFFFF,implicit=0x0010000000000000;\n', b'')
    helper = helper.replace(b'x,y,low,middle,high,', b'low,high,').replace(
        b'I64 exp_a,exp_b,exponent,shift;', b'I64 exponent,shift;')
sources[soft] = source + b'\n' + helper

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

if args.primary_minimum:
    backing = 'Kernel/I386/MemoryBacking.HC'
    edit(backing, '\n  if(!I386MemBackingFits(source,request))source=pool->heap;',
         """
  if(!I386MemBackingFits(source,request)) {
    source=pool->heap;
    if(pool->fallback && pool->owned_count && size!=minimum &&
        I386MemBackingFits(source,minimum+sizeof(CI386BackingRegion)+511)) {
      size=minimum;request=size+sizeof(CI386BackingRegion)+511;
    }
  }""")
    edit(backing, '  if(pool->owned_count && size==I386_NATIVE_BACKING_QUANTUM)region=I386HeapAllocHigh(source,request);',
         """  if(pool->owned_count && (size==I386_NATIVE_BACKING_QUANTUM ||
      pool->fallback && source==pool->heap && size<I386_NATIVE_BACKING_QUANTUM))
    region=I386HeapAllocHigh(source,request);""")

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
