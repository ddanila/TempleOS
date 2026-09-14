#define TRUE 1
#define NULL 0
#include "/Compiler/PrsType.HH"
class CDimProbe {
  I64 before;
  CArrayDim root,nodes[3];
  I64 after,index,count,allocated;
  I64 tokens[10],values[3];
};
I64 DimProbeLex(U8 *context,CCmpCtrl *cc)
{
  CDimProbe *probe=context;
  if(probe->index>=9) while(TRUE) {}
  return cc->token=probe->tokens[++probe->index];
}
U0 DimProbeError(U8 *context,CCmpCtrl *cc,I64 kind,U8 *message)
{ while(TRUE) {} }
I64 DimProbeInteger(U8 *context,CCmpCtrl *cc)
{
  CDimProbe *probe=context;
  I64 value=probe->values[probe->allocated];
  DimProbeLex(context,cc);
  return value;
}
U8 *DimProbeAllocate(U8 *context,I64 bytes)
{
  CDimProbe *probe=context;
  if(bytes!=sizeof(CArrayDim) || probe->allocated>=3) while(TRUE) {}
  return &probe->nodes[probe->allocated++];
}
I64 DimProbe(I64 count,I64 empty_first)
{
  CDimProbe probe;
  CCmpCtrl cc;
  CPrsTypeServices services;
  I64 i,position=0,expected=1;
  CArrayDim *node;
  probe.before=0x13579BDF2468ACE0; probe.after=0xFEDCBA9876543210;
  probe.index=0; probe.allocated=0;
  for(i=0;i<count;i++) {
    probe.tokens[position++]='[';
    if(i || !empty_first) probe.tokens[position++]=TK_I64;
    probe.tokens[position++]=']';
    probe.values[i]=i+2;
    if(i || !empty_first) expected*=i+2;
    else expected=-1;
  }
  probe.tokens[position]=';';
  cc.flags=CCF_TARGET_I386; cc.token=probe.tokens[0];
  services.context=&probe; services.lex=&DimProbeLex; services.report=&DimProbeError;
  services.integer_expression=&DimProbeInteger; services.allocate=&DimProbeAllocate;
  PrsArrayDimsCore(&services,&cc,PRS1_NULL,&probe.root);
  if(probe.before!=0x13579BDF2468ACE0 || probe.after!=0xFEDCBA9876543210 ||
      probe.index!=position || cc.token!=';' || probe.allocated!=count ||
      probe.root.cnt || probe.root.total_cnt!=expected) return -1;
  node=probe.root.next;
  for(i=0;i<count;i++) {
    if(node!=&probe.nodes[i]) return -2;
    if(!i && empty_first) { if(node->cnt!=-1) return -3; }
    else if(node->cnt!=i+2) return -4;
    expected=1;
    if(i+1<count) expected*=i+3;
    if(i+2<count) expected*=i+4;
    if(node->total_cnt!=expected) return -5;
    node=node->next;
  }
  if(node) return -6;
  return 1;
}
#include "/Compiler/PrsArrayDimsCore.HC"
