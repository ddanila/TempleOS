#include "/Compiler/CodeCtrl.HC"
CIntermediateCode *ICAdd(CCmpCtrl *cc,
   I64 opcode_and_precedence,I64 arg,CHashClass *c,I64 flags=0)
{
  CIntermediateCode *node=MAlloc(sizeof(CIntermediateCode));
  ICSeed(cc,node,opcode_and_precedence,arg,c,flags);
  return node;
}
U0 COCInit(CCmpCtrl *cc) { COCSeed(&cc->coc); }

U0 COCPush(CCmpCtrl *cc)
{
  CCodeCtrl *tmpcbh=MAlloc(sizeof(CCodeCtrl));
  COCSave(cc,tmpcbh);
}

CCmpCtrl *COCPopNoFree(CCmpCtrl *cc)
{
  return COCRestore(cc);
}

U0 COCPop(CCmpCtrl *cc)
{
  Free(COCPopNoFree(cc));
}

U0 COCAppend(CCmpCtrl *cc, CCodeCtrl *tmpcbh)
{
  COCJoin(cc,tmpcbh);
  Free(tmpcbh);
}

CCodeMisc *COCMiscNew(CCmpCtrl *cc,I64 ty)
{
  CCodeMisc *res=CAlloc(sizeof(CCodeMisc));
  COCMiscSeed(cc,res,ty);
  return res;
}

U0 COCSystemFree(U8 *context,U8 *allocation) { Free(allocation); }
U0 COCSystemLabel(U8 *context,CCmpCtrl *cc,U8 *name,Bool undefined)
{
  if(undefined) PrintErr("Undefined goto label %s\n",name);
  else {
    PrintWarn("Unused label %s\n",name);
    LexWarn(cc,"Unused label at ");
  }
}
U0 COCDel(CCmpCtrl *cc,CCodeCtrl *coc)
{
  CSymbolRelease owner;
  owner.context=0; owner.release=&COCSystemFree;
  if(COCRelease(cc,coc,&owner,&COCSystemLabel))
    LexExcept(cc,"Undefined goto label at ");
}

