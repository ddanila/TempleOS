U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 trace=0;
Bool KeyA(I64 ch,I64 sc){trace=trace*10+1;return TRUE;}
Bool KeyB(I64 ch,I64 sc){trace=trace*10+2;return sc&SCF_KEY_DESC;}
Bool KeyC(I64 ch,I64 sc){trace=trace*10+3;return FALSE;}
Bool KeyD(I64 ch,I64 sc){trace=trace*10+4;return TRUE;}
Bool StringB(U8 *s){trace=trace*10+5;return FALSE;}
Bool StringD(U8 *s){trace=trace*10+6;return TRUE;}
U0 CaptureKeyDev()
{
  I64 *v=CAlloc(12*sizeof(I64));
  Bool old_silent=LBtr(&Fs->display_flags,DISPLAYf_SILENT);
  CKeyDevEntry *a=KeyDevAdd(&KeyA,NULL,30,FALSE),
    *b=KeyDevAdd(&KeyB,&StringB,20,TRUE),
    *c=KeyDevAdd(&KeyC,NULL,10,FALSE),*d;
  U8 *line;
  trace=0;PutKey('a',0);v[0]=trace;
  trace=0;PutKey('c',SCF_KEY_DESC|0x2E);v[1]=trace;
  trace=0;PutS("ab");v[2]=trace;
  LBts(&Fs->display_flags,DISPLAYf_SILENT);
  trace=0;PutKey('s',0);v[3]=trace;
  trace=0;PutS("ab");v[4]=trace;
  LBtr(&Fs->display_flags,DISPLAYf_SILENT);
  trace=0;PutChars(0x420041);v[5]=trace;
  trace=0;PutKey(0,0);v[6]=trace;
  trace=0;PutS(NULL);v[7]=trace;
  d=KeyDevAdd(&KeyD,&StringD,10,FALSE);
  trace=0;PutKey('d',0);v[8]=trace;
  trace=0;PutS("ab");v[10]=trace;
  trace=0;PutKey('c',SCF_KEY_DESC|0x2E);v[11]=trace;
  KeyDevRem(d);
  trace=0;PutKey('a',0);v[9]=trace;
  KeyDevRem(a);KeyDevRem(b);
  LBEqu(&Fs->display_flags,DISPLAYf_SILENT,old_silent);
  line=MStrPrint("EXPORT keydev.bin %X %X\n",v,12*sizeof(I64));
  Report(line);Free(line);
}
CaptureKeyDev;
Report("DONE original output hook contract\n");
