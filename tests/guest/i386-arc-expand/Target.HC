#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/ArcExpand.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Ports.HH"
public extern I64 ExpansionTest();
public extern I64 OwnedExpandTest();
I64 Main(I64 a,I64 b) { I64 result=ExpansionTest; if(result) return result; return OwnedExpandTest; }
U8 archive_vectors[131072];
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Arc.HC"
#include "/Kernel/I386/ArcExpand.HC"
I64 fault_reads;
I64 FaultRead(U8 *context,CArcCtrl *c)
{
  if(fault_reads++) return -42;
  return I386ArcReadCode(c);
}
I64 ExpansionTest()
{
  CI386Heap heap;
  CArcCtrl *c;
  CArcCompress *arc;
  U8 *buffer,*ptr,bits[3];
  U32 random;
  I64 v,offset=8,pattern,packed,size,pass,i,limit,expected,j,width;
  if(!I386HeapInit(&heap,0x60000,131072)) return 21;
  if((archive_vectors+0)(I64 *)[0]!=6) return 22;
  for(v=0;v<6;v++) {
    if(offset>131072-33) return 2;
    pattern=(archive_vectors+offset)(I64 *)[0]; packed=(archive_vectors+offset)(I64 *)[1];
    if(packed<18 || packed>131072-offset-16) return 3;
    arc=archive_vectors+offset+16; size=arc->expanded_size;
    if(pattern!=v%3 || arc->compression_type!=CT_7_BIT+v/3 ||
        (pattern==2 && size!=1) || (pattern!=2 && size!=32768) ||
        (pattern==1 && packed<=8192)) return 19;
    if(arc->compressed_size!=packed || size<1 || size>32768 ||
        (arc->compression_type!=CT_7_BIT && arc->compression_type!=CT_8_BIT)) return 4;
    for(pass=0;pass<3;pass++) {
      c=I386ArcCtrlNew(&heap,TRUE,arc->compression_type);
      buffer=I386HeapAlloc(&heap,size+2,FALSE); if(!c || !buffer) return 5;
      for(i=0;i<size+2;i++) buffer[i]=0xA5;
      c->src_buf=arc; c->src_pos=17<<3; c->src_size=packed<<3; c->dst_buf=buffer+1;
      limit=0;
      if(pass==2) {
        c->src_size=c->src_pos+c->next_bits_in_use; c->dst_size=size;
        if(!I386ArcExpandBuf(c) || c->dst_pos!=1) return 6;
        c->src_size=packed<<3;
      }
      while(limit<size) {
        if(pass==1) limit+=1+(limit%257);
        else limit=size;
        if(limit>size) limit=size;
        c->dst_size=limit;
        if(!I386ArcExpandBuf(c) || c->dst_pos!=limit || buffer[0]!=0xA5 || buffer[size+1]!=0xA5) return 7;
      }
      random=0x12345678;
      for(i=0;i<size;i++) {
        random=random*1664525+1013904223;
        expected=random>>24; if(pattern==0) expected='Q';
        if(arc->compression_type==CT_7_BIT) expected&=127;
        if(buffer[i+1]!=expected) return 8;
      }
      if(pattern==1 && c->next_bits_in_use!=12) return 20;
      if(c->stk_ptr!=c->stk_base || c->src_pos>c->src_size ||
          !I386ArcCtrlDel(&heap,c) || !I386HeapFree(&heap,buffer) || heap.used || heap.allocations) return 9;
    }
    offset+=16+packed;
  }
  //Bit reader uses only the requested field and leaves cursor advancement to the shared loop.
  c=I386ArcCtrlNew(&heap,TRUE,CT_7_BIT); buffer=I386HeapAlloc(&heap,8,TRUE);
  if(!c || !buffer) return 10;
  bits[0]=0xA5; bits[1]=0x73; bits[2]=0xD9;
  c->src_buf=bits; c->src_size=24; c->dst_buf=buffer;
  for(width=8;width<=12;width++) for(i=0;i<8;i++) {
    c->src_pos=i; c->next_bits_in_use=width; expected=0;
    for(j=0;j<width;j++) if(bits[(i+j)>>3]&(1<<((i+j)&7))) expected|=1<<j;
    if(I386ArcReadCode(c)!=expected || c->src_pos!=i) return 11;
    c->src_size=i+width-1;
    if(I386ArcReadCode(c)!=-1 || c->src_pos!=i) return 12;
    c->src_size=24;
  }
  c->src_pos=0; c->src_size=7; c->next_bits_in_use=8; c->dst_size=1;
  if(I386ArcExpandBuf(c) || c->src_pos || c->dst_pos || buffer[0]) return 13;
  c->src_size=24; c->src_buf=0xFFFFFFFE;
  if(I386ArcExpandBuf(c) || c->src_pos || c->dst_pos || buffer[0] || I386ArcExpandBuf(0)) return 14;
  if(!I386ArcCtrlDel(&heap,c)) return 15;
  c=I386ArcCtrlNew(&heap,TRUE,CT_7_BIT); if(!c) return 16;
  ptr=archive_vectors+24; arc=ptr;
  c->src_buf=arc; c->src_pos=17<<3; c->src_size=arc->compressed_size<<3;
  c->dst_buf=buffer; c->dst_size=8; fault_reads=0;
  OutU8(0x21,255); OutU8(0xA1,255); SetRFlags(GetRFlags|0x200);
  if(ArcExpandStep(c,&FaultRead,&I386ArcEntryGet) || c->dst_pos!=1 || buffer[0]!='Q' ||
      c->src_pos!=(17<<3)+8 || fault_reads!=2 || !(GetRFlags&0x200)) return 17;
  if(!I386ArcCtrlDel(&heap,c) || !I386HeapFree(&heap,buffer) ||
      heap.used || heap.allocations || !I386HeapValid(&heap)) return 18;
  SetRFlags(GetRFlags&~0x200);
  return 0;
}

#include "/Kernel/I386/Expand.HC"
#include "T:/Owned.HC"
