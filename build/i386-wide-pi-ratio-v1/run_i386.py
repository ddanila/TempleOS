"""Compare the integer HolyC prototype with the x87 oracle in check.c."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess
import tempfile


def vectors(root, production):
    with tempfile.TemporaryDirectory() as tmp:
        executable = Path(tmp)/'check'
        subprocess.run(['cc','-std=c11','-O2','-Wall','-Wextra','-Werror',
                        str(root/'check.c'),'-o',str(executable)],check=True)
        option = '--production-vectors' if production else '--vectors'
        output = subprocess.check_output([str(executable),option])
    return [tuple(int(word,16) for word in line.split()) for line in output.splitlines()]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--production',action='store_true')
    args=parser.parse_args()
    out=args.out.resolve()
    out.mkdir()
    root=Path(__file__).resolve().parent
    samples=vectors(root,args.production)
    inputs=',\n'.join(f'  0x{a:016X},0x{b:016X}' for a,b,_ in samples)
    output_count=len(samples)
    extra_checks=''
    if args.production:
        output_count=2*len(samples)+3
        extra_checks=f'''
  for(i=0;i<{len(samples)};i++)
    ratio_results[{len(samples)}+i]=PiRatioOtherOrder(ratio_inputs[2*i],ratio_inputs[2*i+1]);
  ratio_results[{2*len(samples)}]=PiRatioStored(30.0,180.0);
  ratio_results[{2*len(samples)+1}]=PiRatioVariable(30.0,pi,180.0);
  ratio_results[{2*len(samples)+2}]=PiRatioCall(60.0);
'''
    test=f'''\nU64 ratio_inputs[{2*len(samples)}]={{
{inputs}
}};
U64 ratio_results[{output_count}];
U0 PiRatioProbe()
{{
  I64 i;
  U8 msg[128],*p;
  for(i=0;i<{len(samples)};i++)
    ratio_results[i]=PiRatio(ratio_inputs[2*i],ratio_inputs[2*i+1]);
{extra_checks}
  StrPrint(msg,"EXPORT PiRatio.bin %X {8*output_count:X}\\n",ratio_results);
  for(p=msg;*p;p++) OutU8(0xE9,*p);
  Sleep(2000);
  for(p="PI RATIO ready\\n";*p;p++) OutU8(0xE9,*p);
}}
PiRatioProbe;
'''
    ground_truth=b''.join(struct.pack('<Q', value) for _,_,value in samples)
    if args.production:
        lowering = b'''U64 PiRatio(U64 a,U64 b)
{
  F64 lhs=a(F64),rhs=b(F64),value=lhs*pi/rhs;
  return value(U64);
}
U64 PiRatioOtherOrder(U64 a,U64 b)
{
  F64 lhs=a(F64),rhs=b(F64),value=pi*lhs/rhs;
  return value(U64);
}
U64 PiRatioStored(F64 a,F64 b)
{
  F64 product=a*pi,value=product/b;
  return value(U64);
}
U64 PiRatioVariable(F64 a,F64 scale,F64 b)
{
  F64 value=a*scale/b;
  return value(U64);
}
F64 PiRatioDenominator()
{
  return 180.0;
}
U64 PiRatioCall(F64 degrees)
{
  F64 value=degrees*pi/PiRatioDenominator;
  return value(U64);
}
'''
        ground_truth=ground_truth*2+struct.pack(
            '<3Q',0x3FE0C152382D7365,0x3FE0C152382D7365,0x3FF0C152382D7366)
    else:
        lowering = (root/'PiRatio.HC').read_bytes()
    fixture=lowering+test.encode('ascii')
    image=out/'working.img'
    pack=runpy.run_path('tools/package-i386-native-image.py')['package']
    report={'samples':output_count,'production':args.production,
            'fixture_sha256':hashlib.sha256(fixture).hexdigest(),
            'package':pack(args.disk,image,additions={'/PiRatio.HC':fixture})}
    Guest=runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest=Guest(image,out/'guest',True)
    try:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/PiRatio.HC"')
        guest.wait('PI RATIO ready\n',90)
        actual=(guest.out/'PiRatio.bin').read_bytes()
        if actual!=ground_truth:
            raise ValueError('Native PiRatio results differ from the x87 oracle')
        report.update(result='pass',sample_sha256=hashlib.sha256(actual).hexdigest())
    except Exception as error:
        report.update(result='fail',error=str(error))
        raise
    finally:
        guest.close()
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':
    main()
