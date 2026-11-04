I64 CESZero(){return 0x12345678ABCDEF01;}
I64 CESOne(I64 a){return a^0xFEDCBA9876543210;}
I64 CESThree(I64 a,I64 b,I64 c){return a+3*b+7*c;}
I64 CESPointer(U8 *s,I64 n){return s[0]+n;}
I64 CESNested(I64 n){return CallExtStr("CESOne",n)+CallExtStr("CESZero");}
I64 CESThrow(I64 n){throw('CES',TRUE);return n;}
class CESNullExport:CHashSrcSym {I64 val;U32 kind;};
I64 CESMany(I64 a,I64 b,I64 c,I64 d,I64 e,I64 f,I64 g,I64 h,I64 i,I64 j)
{return a+2*b+3*c+4*d+5*e+6*f+7*g+8*h+9*i+10*j;}
U0 CallExtStrContract()
{
  I64 observed[4];
  I64 i,a=0x1234567800000001,b=0x1122334400000002,c=0x1020304000000003;
  Bool caught=FALSE;CESNullExport *null_hook;I64 null_result;
  null_hook=CAlloc(sizeof(CESNullExport));null_hook->str=StrNew("CESNullExport");
  null_hook->type=HTT_EXPORT_SYS_SYM;null_hook->kind=1;HashAdd(null_hook,Fs->hash_table);
  null_result=CallExtStr("CESNullExport",7);
  if(!HashRemDel(null_hook,Fs->hash_table))throw('CESN',TRUE);
  if(CallExtStr("CESMissing",1,2,3)||null_result)throw('CES1',TRUE);
  observed[0]=CallExtStr("CESZero");observed[1]=CESZero;observed[2]=(&CESZero)(I64);observed[3]=0x12345678ABCDEF01;
  if(observed[0]!=observed[1]){FileWrite("C:/call-ext-observed.DATA",observed,32);throw('CES2',TRUE);}
  if(CallExtStr("CESOne",a)!=CESOne(a))throw('CES3',TRUE);
  if(CallExtStr("CESThree",a,b,c)!=CESThree(a,b,c))throw('CES4',TRUE);
  if(CallExtStr("CESPointer","Q",a)!=a+81)throw('CES5',TRUE);
  if(CallExtStr("CESMany",a,b,c,4,5,6,7,8,9,10)!=CESMany(a,b,c,4,5,6,7,8,9,10))throw('CES6',TRUE);
  if(CallExtStr("CESNested",a)!=CESNested(a))throw('CES7',TRUE);
  if(CallExtStr("_STRICMP","B","a")<=0)throw('CES8',TRUE);
  if(CallExtStr("_MAX",1.25,2.5)!=0x4004000000000000)throw('CESF',TRUE);
  try CallExtStr("CESThrow",7);
  catch {caught=TRUE;Fs->catch_except=TRUE;}
  if(!caught)throw('CES9',TRUE);
  for(i=0;i<100;i++)if(CallExtStr("CESOne",i)!=CESOne(i))throw('CESA',TRUE);
}
