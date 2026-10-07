"""Independent Decimal Arg oracle using half-angle reduction and Taylor sums."""
from decimal import Decimal, localcontext
import random
import struct
from i386_trig_oracle import decimal_pi, to_bits
SIGN = 1 << 63
MASK = SIGN-1
INF = 0x7ff0000000000000


def rounded_arg(xb, yb, precision):
    ax, ay = xb & MASK, yb & MASK
    if ax > INF or ay > INF:
        raise ValueError('NaN payload parity is a separate original-reference gate')
    with localcontext() as ctx:
        ctx.prec = precision
        pi = decimal_pi(precision)
        if not ay:
            return to_bits(-pi if yb & SIGN else pi) if xb & SIGN else yb
        if not ax or ay == INF and ax != INF:
            z = pi/2
        elif ax == INF:
            z = (3*pi/4 if xb & SIGN else pi/4) if ay == INF else (pi if xb & SIGN else Decimal(0))
        else:
            x = Decimal.from_float(struct.unpack('<d', struct.pack('<Q', ax))[0])
            y = Decimal.from_float(struct.unpack('<d', struct.pack('<Q', ay))[0])
            ratio = y/x
            reciprocal = ratio > 1
            if reciprocal:
                ratio = 1/ratio
            factor = 1
            while ratio > Decimal('0.125'):
                ratio /= 1+(1+ratio*ratio).sqrt()
                factor *= 2
            term = total = ratio
            square = ratio*ratio
            index = 1
            while True:
                term *= -square
                updated = total+term/(2*index+1)
                if updated == total:
                    break
                total = updated
                index += 1
            z = total*factor
            if reciprocal:
                z = pi/2-z
            if xb & SIGN:
                z = pi-z
        return to_bits(z) ^ (yb & SIGN)


def vectors():
    edge = [0, SIGN, 1, SIGN|1, 0x000fffffffffffff, 0x0010000000000000,
            0x3ff0000000000000, 0xbff0000000000000, 0x7fefffffffffffff,
            0xffefffffffffffff, INF, SIGN|INF]
    pairs = [(x,y) for x in edge for y in edge]
    for value in (0.4375,0.6875,1.1875,2.4375):
        bits = to_bits(value)
        pairs += [(to_bits(1), b|s) for b in (bits-1,bits,bits+1) for s in (0,SIGN)]
    rng = random.Random(386)
    while len(pairs) < 1024:
        x,y = rng.getrandbits(64),rng.getrandbits(64)
        if (x&MASK) < INF and (y&MASK) < INF:
            pairs.append((x,y))
    result = []
    for x,y in pairs:
        expected = rounded_arg(x,y,400)
        if expected != rounded_arg(x,y,480):
            raise ValueError('Arg rounding unstable at two precisions')
        result.append((x,y,expected))
    return result
