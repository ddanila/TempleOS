U64 model_angle_samples[32];
I64 model_degrees[4]={-60,-30,30,60};
F64 ModelRadians(F64 degrees)
{
  return degrees*ã/180.0;
}
U0 ModelAngleProbe()
{
  I64 i;
  F64 angle,cosine,sine;
  U8 msg[128],*p;
  for(i=0;i<4;i++) {
    angle=ModelRadians(model_degrees[i]);
    cosine=Cos(angle);
    sine=Sin(angle);
    model_angle_samples[7*i]=angle(U64);
    model_angle_samples[7*i+1]=cosine(U64);
    model_angle_samples[7*i+2]=sine(U64);
    model_angle_samples[7*i+3]=cosine*(1<<32);
    model_angle_samples[7*i+4]=sine*(1<<32);
    model_angle_samples[7*i+5]=Cos(model_degrees[i]*ã/180.0)(U64);
    model_angle_samples[7*i+6]=Sin(model_degrees[i]*ã/180.0)(U64);
  }
  angle=180.0;
  model_angle_samples[28]=angle(U64);
  angle=Pow10I64(-1);
  model_angle_samples[29]=angle(U64);
  angle=60.0*ã;
  model_angle_samples[30]=angle(U64);
  angle=ModelRadians(60.0);
  model_angle_samples[31]=angle(U64);
  StrPrint(msg,"EXPORT ManAngles.bin %X 100\n",model_angle_samples);
  for(p=msg;*p;p++) OutU8(0xE9,*p);
  StrPrint(msg,"EXPORT ManRadiansCode.bin %X 80\n",&ModelRadians);
  for(p=msg;*p;p++) OutU8(0xE9,*p);
  Sleep(2000);
  for(p="MAN angles ready\n";*p;p++) OutU8(0xE9,*p);
}
ModelAngleProbe;
