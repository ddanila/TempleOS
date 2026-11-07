U0 PFLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
CHashFun *PFDefineTyped(U8 *return_type,U8 *name,U8 *body)
{
  U8 *source=MStrPrint("%s %s%s",return_type,name,body);
  ExePutS(source);Free(source);
  return HashFind(name,Fs->hash_table,HTT_FUN);
}
CHashFun *PFDefine(U8 *name,U8 *body){return PFDefineTyped("I64",name,body);}
U0 PFCheck()
{
  I64 *r=CAlloc(14*8);U8 *s;CHashFun *fun;
  I64 (*binary)(I64 a,I64 b),(*unary)(I64 a);
  fun=PFDefine("PFArithmetic","(I64 a,I64 b=5){return a*3+b;}");
  r[0]=fun && fun->arg_cnt==2;binary=fun->exe_addr;r[7]=(*binary)(7,5);
  fun=PFDefine("PFLoop","(I64 count){I64 noreg sum=0;I64 noreg i;for(i=0;i<count;i++){if(i==3)goto skip;sum+=i;skip:if(sum>20)break;}return sum;}");
  r[1]=fun && fun->arg_cnt==1;unary=fun->exe_addr;r[8]=(*unary)(8);
  fun=PFDefine("PFNested","(I64 a){return PFArithmetic(a)+PFArithmetic(2,3);}");
  r[2]=fun && fun->arg_cnt==1;unary=fun->exe_addr;r[9]=(*unary)(4);
  fun=PFDefine("PFArray","(I64 a){I64 noreg values[3];values[0]=a;values[1]=a+1;values[2]=a+2;return values[0]+values[1]*2+values[2];}");
  r[3]=fun && fun->arg_cnt==1;unary=fun->exe_addr;r[10]=(*unary)(4);
  fun=PFDefine("PFSwitch","(I64 a){switch(a){case 2:return 7;case 3:return 9;default:return 11;}}");
  r[4]=fun && fun->arg_cnt==1;unary=fun->exe_addr;r[11]=(*unary)(3);
  fun=PFDefine("PFLocal","(I64 a){I64 value=a+2;I64 other=value*3;return other-value;}");
  r[5]=fun && fun->arg_cnt==1;unary=fun->exe_addr;r[12]=(*unary)(4);
  fun=PFDefineTyped("F64","PFFloat","(F64 a){F64 value=a*2.0;return value+0.5;}");
  F64 (*floating)(F64 a);
  r[6]=fun && fun->arg_cnt==1 && fun->return_class->raw_type==RT_F64;floating=fun->exe_addr;r[13](F64)=(*floating)(1.5);
  s=MStrPrint("EXPORT public-functions.bin %X 70\n",r);PFLog(s);Free(s);
  PFLog("PUBLIC FUNCTIONS DONE\n");Sleep(1000);
}
PFCheck;
