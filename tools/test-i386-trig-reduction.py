#!/usr/bin/env python3
"""Run the HolyC reducer against independently generated Decimal remainders."""
import argparse
from decimal import Decimal, ROUND_HALF_EVEN, localcontext
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import sys
from i386_trig_oracle import decimal_pi, trig_inputs, MASK, INF, to_bits

ROOT = Path(__file__).resolve().parents[1]


def reference_rows():
    rows = []
    with localcontext() as context:
        context.prec = 480
        half_pi = decimal_pi(480)/2
        for bits in trig_inputs():
            if bits & MASK >= INF:
                continue
            if bits & MASK <= 0x3FE921FB54442D18:
                rows.append((bits, 0, bits, 0))
                continue
            value = struct.unpack('<d', struct.pack('<Q', bits))[0]
            exact = Decimal.from_float(value)
            quotient = (exact/half_pi).to_integral_value(rounding=ROUND_HALF_EVEN)
            remainder = exact-quotient*half_pi
            head = float(remainder)
            tail = float(remainder-Decimal.from_float(head))
            rows.append((bits, int(quotient) % 4, to_bits(head), to_bits(tail)))
    return rows


def check_source(rows):
    data = b''.join(struct.pack('<4Q', *row) for row in rows)
    source = 'U64 *tr_vectors=\n'
    for start in range(0, len(data), 32):
        source += '  "'+''.join(f'\\x{x:02X}' for x in data[start:start+32])+'"\n'
    source += ';\nI64 TrigReductionCheck()\n{\n'
    source += '  I64 i,q;F64 head,tail,wanted_head,wanted_tail,error;\n'
    source += f'  for(i=0;i<{len(rows)};i++) {{\n'
    source += '''    q=I386TrigReduce(tr_vectors[i*4](F64),&head,&tail);
    wanted_head=tr_vectors[i*4+2](F64);wanted_tail=tr_vectors[i*4+3](F64);
    if(i==5) {
      U8 *line=MStrPrint("OBS reducer q %d expected %d head %X expected %X tail %X expected %X\\n",q,tr_vectors[i*4+1],head(U64),tr_vectors[i*4+2],tail(U64),tr_vectors[i*4+3]),*scan=line;
      while(*scan)OutU8(0xE9,*scan++);Free(line);
    }
    if(q!=tr_vectors[i*4+1])return i+1;
    if((tr_vectors[i*4]&0x7FFFFFFFFFFFFFFF)<=0x3FE921FB54442D18) {
      if(head(U64)!=tr_vectors[i*4+2] || tail(U64))return i+1;
    } else {
      error=Abs((head-wanted_head)+(tail-wanted_tail));
      if(error>Abs(wanted_head)*2.0e-31)return i+1;
    }
  }
  return 0;
}
'''
    return source, data


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    out = args.out.resolve()
    out.mkdir(parents=True)
    paths = [Path(__file__).resolve(), ROOT/'tools/i386_trig_oracle.py',
             ROOT/'Kernel/I386/FloatTrigReduction.HC', ROOT/'tools/build-iso.py',
             ROOT/'tools/guest-run.py',
             ROOT/'build/rebuild-test/overlay/0000Boot/0000Kernel.BIN.C',
             ROOT/'build/rebuild-test/overlay/Compiler/Compiler.BIN']
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in paths}
    source, data = check_source(reference_rows())
    report = dict(result='running', input_sha256=pins, count=len(data)//32,
                  scope='HolyC reducer executed in original x64 OS; native no-FPU remains pending',
                  vector_sha256=hashlib.sha256(data).hexdigest())
    (out/'vectors.bin').write_bytes(data)
    try:
        overlay = out/'overlay'
        overlay.mkdir()
        source = '#include "/Kernel/I386/FloatTrigReduction.HC"\n'+source
        source += '''U0 TrReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 tr_error=TrigReductionCheck();
U8 *tr_line=MStrPrint("OBS HolyC reduction error %d\\n",tr_error);
TrReport(tr_line);Free(tr_line);
if(!tr_error)TrReport("PASS HolyC trig reduction\\n");else TrReport("FAIL HolyC trig reduction\\n");
TrReport("DONE HolyC trig reduction\\n");
'''
        (overlay/'Once.HC').write_text(source)
        iso = out/'original.iso'
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay', 'build/rebuild-test/overlay',
                        '--overlay', str(overlay), '--output', str(iso)], cwd=ROOT, check=True)
        subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out', str(out/'behavior'),
                        '--timeout', '90', '--qmp-stdio'], cwd=ROOT, check=True)
        log = (out/'behavior/debug.log').read_text()
        if 'OBS HolyC reduction error 0\n' not in log or 'PASS HolyC trig reduction\n' not in log:
            raise AssertionError('HolyC reducer did not pass all inputs')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        changed = [p for p, value in pins.items() if sha(Path(p)) != value]
        if changed:
            report.update(result='fail', error='Inputs changed', changed_inputs=changed)
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise RuntimeError(report['error'])


if __name__ == '__main__':
    main()
