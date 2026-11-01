#include "/Kernel/MinClampCore.HC"

#include "/Kernel/MaxCore.HC"

F64 Pow10I64(I64 i)
{//F64 int powers of ten.
  if (i>308)
    return ì;
  else if (i<-308)
    return 0.0;
  else
    return pow10_I64[i+308];
}

#include "/Kernel/KMathInt.HC"

//See $LK,"::/Doc/Credits.DD"$.
#define LIN_CONGRUE_A	6364136223846793005
#define LIN_CONGRUE_C	1442695040888963407

#include "/Kernel/RandFamilyCore.HC"
