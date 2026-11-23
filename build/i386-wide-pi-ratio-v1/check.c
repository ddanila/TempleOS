/* Prototype for binary64 inputs other than NaNs. The candidate uses
 * 64-bit words so the i386 backend can emit the same operations. */
#include <assert.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

static uint64_t normalize(uint64_t value, int *exponent)
{
    uint64_t mantissa = value & UINT64_C(0x000fffffffffffff);
    *exponent = (int)((value >> 52) & 2047);
    if (*exponent) {
        mantissa |= UINT64_C(1) << 52;
    } else {
        *exponent = 1;
        while (mantissa < (UINT64_C(1) << 52)) {
            mantissa <<= 1;
            --*exponent;
        }
    }
    *exponent -= 1023;
    return mantissa;
}

static uint64_t round_extended(uint64_t value, uint64_t remainder,
                               uint64_t half, int *exponent)
{
    if (remainder > half || (remainder == half && (value & 1))) {
        if (++value == 0) {
            value = UINT64_C(1) << 63;
            ++*exponent;
        }
    }
    return value;
}

static uint64_t pack_double(uint64_t mantissa, int exponent, uint64_t sign)
{
    uint64_t guard = mantissa >> 8 | ((mantissa & 255) != 0);
    exponent += 1023;
    if (exponent < 1) {
        int distance = 1 - exponent;
        guard = distance >= 64 ? (guard != 0) :
            (guard >> distance) | ((guard << (64 - distance)) != 0);
        exponent = 1;
    }
    uint64_t rounded = guard >> 3;
    uint64_t tail = guard & 7;
    if (tail > 4 || (tail == 4 && (rounded & 1))) {
        ++rounded;
    }
    if (rounded == (UINT64_C(1) << 53)) {
        rounded >>= 1;
        ++exponent;
    }
    if (exponent >= 2047) {
        return sign | UINT64_C(0x7ff0000000000000);
    }
    if (exponent == 1 && rounded < (UINT64_C(1) << 52)) {
        exponent = 0;
    }
    return sign | ((uint64_t)exponent << 52) |
        (rounded & UINT64_C(0x000fffffffffffff));
}

static uint64_t wide_pi_ratio(uint64_t numerator, uint64_t divisor)
{
    const uint64_t infinity = UINT64_C(0x7ff0000000000000);
    uint64_t sign = (numerator ^ divisor) & (UINT64_C(1) << 63);
    uint64_t a = numerator & (UINT64_MAX >> 1);
    uint64_t b = divisor & (UINT64_MAX >> 1);
    assert(a <= infinity && b <= infinity);
    if ((!a && !b) || (a == infinity && b == infinity)) {
        return UINT64_C(0xfff8000000000000);
    }
    if (a == infinity || !b) {
        return sign | infinity;
    }
    if (!a || b == infinity) {
        return sign;
    }
    int exponent, divisor_exponent;
    uint64_t mantissa = normalize(numerator, &exponent);
    uint64_t denominator = normalize(divisor, &divisor_exponent) << 11;
    const uint64_t pi = UINT64_C(0xc90fdaa22168c235);
    uint64_t low_product = (uint32_t)mantissa * (uint64_t)(uint32_t)pi;
    uint64_t middle = (mantissa >> 32) * (uint32_t)pi +
        (uint32_t)mantissa * (pi >> 32) + (low_product >> 32);
    uint64_t high = (mantissa >> 32) * (pi >> 32) + (middle >> 32);
    uint64_t low = (uint32_t)low_product | (middle << 32);
    int shift = 52 + (int)(high >> 52);
    exponent += 1 + shift - 52;
    uint64_t half = UINT64_C(1) << (shift - 1);
    uint64_t remainder = low & ((half << 1) - 1);
    mantissa = (high << (64 - shift)) | (low >> shift);
    mantissa = round_extended(mantissa, remainder, half, &exponent);

    exponent -= divisor_exponent;
    if (mantissa < denominator) {
        /* The normalized quotient is at least one. Subtract the divisor
           now so the doubled mantissa can wrap harmlessly. */
        mantissa = (mantissa << 1) - denominator;
        --exponent;
    } else {
        mantissa -= denominator;
    }
    uint64_t quotient = 1;
    for (int i = 0; i < 63; ++i) {
        int carry = (int)(mantissa >> 63);
        mantissa <<= 1;
        quotient <<= 1;
        if (carry || mantissa >= denominator) {
            mantissa -= denominator;
            quotient |= 1;
        }
    }
    quotient = round_extended(quotient, mantissa, denominator >> 1, &exponent);
    return pack_double(quotient, exponent, sign);
}

static uint64_t x87_pi_ratio(uint64_t numerator, uint64_t divisor)
{
    uint64_t result;
    __asm__ volatile("fldpi; fmull %1; fdivl %2; fstpl %0"
                     : "=m"(result) : "m"(numerator), "m"(divisor) : "st");
    return result;
}

static uint64_t next_bits(void)
{
    static uint64_t state = UINT64_C(0x243f6a8885a308d3);
    state ^= state << 13;
    state ^= state >> 7;
    state ^= state << 17;
    return state;
}

static void compare(uint64_t numerator, uint64_t divisor)
{
    assert(wide_pi_ratio(numerator, divisor) == x87_pi_ratio(numerator, divisor));
}

static void vector(uint64_t a, uint64_t b)
{
    printf("%016" PRIx64 " %016" PRIx64 " %016" PRIx64 "\n",
           a, b, x87_pi_ratio(a, b));
}

int main(int argc, char **argv)
{
    uint16_t control;
    __asm__ volatile("fnstcw %0" : "=m"(control));
    assert((control & UINT16_C(0x0f3f)) == UINT16_C(0x033f));

    const uint64_t edge[] = {
        UINT64_C(1), UINT64_C(0x000fffffffffffff), UINT64_C(0x0010000000000000),
        UINT64_C(0x0010000000000001), UINT64_C(0x3ff0000000000000),
        UINT64_C(0x403e000000000000), UINT64_C(0xc04e000000000000),
        UINT64_C(0x4066800000000000), UINT64_C(0x7fefffffffffffff),
        0, UINT64_C(0x8000000000000000), UINT64_C(0x7ff0000000000000),
        UINT64_C(0xfff0000000000000)
    };
    int vectors = argc == 2 && strcmp(argv[1], "--vectors") == 0;
    for (unsigned i = 0; i < sizeof(edge) / sizeof(edge[0]); ++i) {
        for (unsigned j = 0; j < sizeof(edge) / sizeof(edge[0]); ++j) {
            if (vectors) vector(edge[i], edge[j]);
            else compare(edge[i], edge[j]);
        }
    }
    for (unsigned i = 0; i < (vectors ? 128U : 100000U); ++i) {
        uint64_t a, b;
        do {
            a = next_bits();
            b = next_bits();
        } while (!(a << 1) || !(b << 1) || ((a >> 52) & 2047) == 2047 ||
                 ((b >> 52) & 2047) == 2047);
        if (vectors) vector(a, b);
        else compare(a, b);
    }
    if (vectors) return 0;
    assert(wide_pi_ratio(edge[5], edge[7]) == UINT64_C(0x3fe0c152382d7366));
    assert(wide_pi_ratio(edge[6], edge[7]) == UINT64_C(0xbff0c152382d7366));
    printf("%zu binary64 pairs matched the x87 FLDPI pipeline\n",
           100000 + (sizeof(edge) / sizeof(edge[0])) * (sizeof(edge) / sizeof(edge[0])));
    return 0;
}
