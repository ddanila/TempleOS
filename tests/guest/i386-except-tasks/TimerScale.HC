I64 TimerScaleTest()
{
  CI386Timer sample;
  I64 divisors[6],guard[3],i,j,k,total;
  U8 *bytes=&sample;
  divisors[0]=2; divisors[1]=1193; divisors[2]=11932;
  divisors[3]=32768; divisors[4]=65535; divisors[5]=65536;
  guard[0]=0x123456789ABCDEF0; guard[2]=0xFEDCBA9876543210;
  for(i=0;i<6;i++) {
    for(k=0;k<sizeof(CI386Timer);k++) bytes[k]=0;
    guard[1]=37;
    if(I386TimerInit(&sample,1,&guard[1]) || guard[1]!=37 ||
        !I386TimerInit(&sample,divisors[i],&guard[1]) || guard[1]) return 90;
    for(j=1;j<=257;j++) {
      total=j*divisors[i]*1000;
      if(!I386TimerStep(&sample) || sample.ticks!=j ||
          guard[1]!=total/1193182 || sample.jiffy_remainder!=total%1193182 ||
          guard[0]!=0x123456789ABCDEF0 || guard[2]!=0xFEDCBA9876543210) return 91;
    }
  }
  //Check accumulated fractional carry over a longer interval and a wide carry.
  for(k=0;k<sizeof(CI386Timer);k++) bytes[k]=0;
  if(!I386TimerInit(&sample,1193,&guard[1])) return 92;
  for(j=0;j<10007;j++) if(!I386TimerStep(&sample)) return 93;
  if(guard[1]!=10007*1193*1000/1193182 ||
      sample.jiffy_remainder!=10007*1193*1000%1193182) return 94;
  guard[1]=0xFFFFFFFF;
  total=(sample.jiffy_remainder+1193000)/1193182;
  if(!I386TimerStep(&sample) || guard[1]!=0xFFFFFFFF+total) return 95;
  for(k=0;k<sizeof(CI386Timer);k++) bytes[k]=0;
  if(!I386TimerInit(&sample,65536,&guard[1])) return 96;
  sample.ticks=0xFFFFFFFFFFFFFFFF; guard[1]=0xFFFFFFFFFFFFFFF0;
  if(!I386TimerStep(&sample) || sample.ticks || guard[1]!=38) return 97;
  return 0;
}
