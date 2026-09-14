#ifndef I386_FLOAT_MATH_INCLUDED
#define I386_FLOAT_MATH_INCLUDED
//Public numerical operations implemented without an FPU.
public extern F64 Round(F64 value);
public extern F64 Trunc(F64 value);
public extern F64 Floor(F64 value);
public extern F64 Ceil(F64 value);
public extern F64 Pow10I64(I64 exponent);
public extern F64 Ln(F64 x);
public extern F64 Log10(F64 x);
#endif
