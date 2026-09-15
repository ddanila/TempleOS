//Scalar answer formatting, independent of x87 and pointer-sized arithmetic.
U0 ConsoleUnsigned(U64 value,U64 radix=10)
{
  U8 buffer[65],*digits="0123456789ABCDEF";
  I64 count=0;
  do { buffer[count++]=digits[value%radix]; value/=radix; } while(value);
  while(count) I386TextPut(&console_text,buffer[--count]);
}
U0 ConsoleSigned(I64 value)
{
  U64 magnitude=value;
  if(value<0) { I386TextPut(&console_text,'-'); magnitude=0-magnitude; }
  ConsoleUnsigned(magnitude);
}
U0 ConsoleFloat(U64 bits)
{//Exact decimal expansion, then nearest-even rounding to 17 significant digits.
  U8 digits[1100],leading[17];
  U64 mantissa=bits&0xFFFFFFFFFFFFF;
  I64 power=(bits>>52)&0x7FF,length=0,scale=0,factor,steps,i,j,carry,exponent,count;
  Bool round_up=FALSE,tail=FALSE;
  if(bits>>63) I386TextPut(&console_text,'-');
  if(power==0x7FF) {
    if(mantissa) I386TextWrite(&console_text,"NaN"); else I386TextWrite(&console_text,"Inf");
    return;
  }
  if(power) { mantissa|=0x10000000000000; power-=1075; } else power=-1074;
  if(!mantissa) { I386TextPut(&console_text,'0'); return; }
  do { digits[length++]=mantissa%10; mantissa/=10; } while(mantissa);
  factor=2; steps=power;
  if(power<0) { factor=5; steps=-power; scale=steps; }
  while(steps--) {
    carry=0;
    for(i=0;i<length;i++) { carry+=digits[i]*factor; digits[i]=carry%10; carry/=10; }
    while(carry) { digits[length++]=carry%10; carry/=10; }
  }
  exponent=length-scale-1;
  for(i=0;i<17;i++) { leading[i]=0; if(i<length) leading[i]=digits[length-1-i]; }
  if(length>17) {
    for(i=0;i<length-18;i++) if(digits[i]) tail=TRUE;
    j=digits[length-18]; round_up=j>5 || j==5 && (tail || leading[16]&1);
  }
  if(round_up) {
    i=16;
    while(i>=0 && leading[i]==9) { leading[i]=0; i--; }
    if(i>=0) leading[i]++;
    else { leading[0]=1; exponent++; }
  }
  count=17; while(count>1 && !leading[count-1]) count--;
  if(exponent>=-4 && exponent<17) {
    if(exponent<0) {
      I386TextWrite(&console_text,"0.");
      for(i=0;i<-exponent-1;i++) I386TextPut(&console_text,'0');
      for(i=0;i<count;i++) I386TextPut(&console_text,'0'+leading[i]);
    } else {
      for(i=0;i<=exponent;i++) I386TextPut(&console_text,'0'+leading[i]);
      if(count>exponent+1) {
        I386TextPut(&console_text,'.');
        for(i=exponent+1;i<count;i++) I386TextPut(&console_text,'0'+leading[i]);
      }
    }
  } else {
    I386TextPut(&console_text,'0'+leading[0]);
    if(count>1) {
      I386TextPut(&console_text,'.');
      for(i=1;i<count;i++) I386TextPut(&console_text,'0'+leading[i]);
    }
    I386TextPut(&console_text,'e');
    if(exponent>=0) I386TextPut(&console_text,'+');
    ConsoleSigned(exponent);
  }
}
