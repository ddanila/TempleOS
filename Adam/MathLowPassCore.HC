F64 LowPass1(F64 a,F64 y0,F64 y,F64 dt=1.0)
{//First order low pass filter
  dt=Exp(-a*dt);
  return y0*dt+y*(1.0-dt);
}
