import hashlib
import json
from pathlib import Path
import runpy
import sys

image, out = (Path(arg).resolve() for arg in sys.argv[1:])
out.mkdir()
mask = (1 << 64) - 1
wide = (
    (0, mask), (1, mask), (mask, 1), (mask, mask),
    (0xffffffff, 0xffffffff), (1 << 32, 1 << 32),
    (1 << 63, 1 << 63), (0x123456789abcdef, 0x1000001),
    (0xfedcba9876543210, 0x89abcdef01234567),
)
narrow = ((0, 255), (2, 7), (127, 128), (255, 255), (128, 255))


def original_byte_product(left, right):
    accumulator = left << 8
    for _ in range(8):
        carry = accumulator >> 15
        accumulator = (accumulator << 1) & 0xffff
        if carry:
            accumulator = (accumulator & 0xff00) | ((accumulator + right) & 0xff)
    return accumulator


lines = ['#include "C:/Demo/Asm/MulByHand.HC"', '''
U64 MulRegisters(U32 left,U32 right)
{
  U64 product;
  asm {
    MOV EAX,U32 &left[EBP]
    MOV ECX,U32 &right[EBP]
    MUL ECX
    MOV U32 &product[EBP],EAX
    MOV U32 &product+4[EBP],EDX
  }
  return product;
}
U0 TestMultiply()
{
  U128 product;
  if(MulRegisters(0xFFFFFFFF,0xFFFFFFFF)!=0xFFFFFFFE00000001)
    throw('Multiply',TRUE);
''']
for left, right in narrow:
    expected = original_byte_product(left, right)
    lines.append(f"  if(MulU8({left},{right})!={expected})throw('Multiply',TRUE);")
for left, right in wide:
    expected = left * right
    lines.extend([
        f'  MulU64(0x{left:X},0x{right:X},&product);',
        f"  if(product.lo!=0x{expected & mask:X} || product.hi!=0x{expected >> 64:X})throw('Multiply',TRUE);",
    ])
lines.extend(['}', 'TestMultiply;', ''])
fixture = '\n'.join(lines).encode()
(out/'fixture.HC').write_bytes(fixture)

def sha(data):
    return hashlib.sha256(data).hexdigest()

original = sha(image.read_bytes())
report = dict(result='fail', disk_sha256=original, fixture_sha256=sha(fixture),
              wide_vectors=len(wide), narrow_vectors=len(narrow), register_vectors=1)
try:
    working = out/'working.img'
    runpy.run_path('tools/package-i386-native-image.py')['package'](
        image, working, additions={'/Probe/MulVectors.HC': fixture})
    Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest = Guest(working, out/'guest', True)
    try:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Probe/MulVectors.HC"')
        guest.command('6*7;')
        report['arithmetic_pixels'] = guest.result_pixels()
    finally:
        guest.close()
    report['result'] = 'pass'
finally:
    report['inputs_unchanged'] = sha(image.read_bytes()) == original
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    assert report['inputs_unchanged']
