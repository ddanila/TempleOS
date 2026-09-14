//Target backend entered by the normal HolyC function compiler.
#include "/Compiler/I386/Emit.HC"
#include "/Compiler/I386/Asm.HC"
#include "/Compiler/I386/Divide.HC"
#include "/Compiler/I386/BackendCore.HC"
#include "/Compiler/I386/AsmCore.HC"
U8 *I386HostBackendAlloc(U8 *context,I64 bytes) { return CAlloc(bytes); }
U0 I386HostBackendFree(U8 *context,U8 *allocation) { Free(allocation); }
U0 I386HostBackendFold(U8 *context,CCmpCtrl *cc) { OptPass012(cc); }
U0 I386HostBackendAsm(U8 *context,CCmpCtrl *cc,CI386Out *out,CAOT *aot,I64 pass)
{ I386AsmCore(context,cc,out,aot,pass); }
U0 I386HostBackendReport(U8 *context,I64 reason,CIntermediateCode *ic,U8 *name)
{
  switch(reason) {
    case 1: PrintErr("i386 requires matching runtime declaration %s\n",name); break;
    case 2: PrintErr("i386 runtime definition is outside this module: %s\n",name); break;
    case 3: PrintErr("i386 requires a function body (first opcode %X)\n",ic->ic_code); break;
    case 4:
      PrintErr("i386 float op %X: result %X, operands %X/%X, flags %X/%X\n",
        ic->ic_code,ic->ic_class->raw_type,ic->t.arg1_tree->ic_code,ic->t.arg2_tree->ic_code,
        ic->t.arg1_tree->ic_flags,ic->t.arg2_tree->ic_flags); break;
    case 5: PrintErr("i386 COC opcode %X not implemented\n",ic->ic_code); break;
    case 6: PrintErr("i386 inline asm absolute/storage relocation not supported\n"); break;
    case 7: PrintErr("i386 inline asm relocation not supported\n"); break;
  }
}
U8 *I386HostConstant(CCmpCtrl *cc,I64 *_size,I64 *_type)
{//Array bounds/defaults are evaluated by the running x86-64 compiler.
 //Accept only an integer constant after target-aware folding, never target code.
  CIntermediateCode *ic;
  I64 count=0,value=0;
  U8 *res;
  if (cc->flags&CCF_EXE_BLK) throw('Compiler');
  cc->pass=0;
  OptPass012(cc);
  //The first pass resolves pointer-scaling placeholders even in integer sums.
  //Fold again after those producer rewrites, as the native backend does.
  OptPass012(cc);
  for (ic=cc->coc.coc_head.next;ic!=&cc->coc.coc_head;ic=ic->next) {
    switch (ic->ic_code) {
      case IC_NOP1:
      case IC_NOP2:
      case IC_RETURN_VAL:
      case IC_RETURN_VAL2:
      case IC_RET: break;
      case IC_IMM_I64:
        if (++count!=1 || ic->ic_class->ptr_stars_cnt) {
          PrintErr("i386 host constant has non-integer or multiple values: count %d, pointer depth %d, value %X\n",
            count,ic->ic_class->ptr_stars_cnt,ic->ic_data);
          throw('Compiler');
        }
        value=ic->ic_data;
        break;
      default:
        PrintErr("i386 host evaluation requires a folded integer constant\n");
        throw('Compiler');
    }
  }
  if (count!=1) { PrintErr("i386 host constant has no value\n"); throw('Compiler'); }
  res=MAlloc(11,Fs->code_heap);
  res[0]=0x48; res[1]=0xB8; //Host MOV RAX,imm64; RET.
  MemCpy(res+2,&value,8); res[10]=0xC3;
  if (_size) *_size=11;
  if (_type) *_type=RT_I64;
  COCDel(cc,&cc->coc);
  return res;
}

U8 *I386COCCompile(CCmpCtrl *cc,I64 *_size,CDbgInfo **_dbg,I64 *_type)
{
  CI386Out out;
  CI386Backend backend;
  CIntermediateCode *ic;
  U8 *result;
  if(_dbg) *_dbg=0;
  if(_type) *_type=RT_I64;
  if(_size) *_size=0;
  if(cc->flags&CCF_TARGET_HOST_CONST) {
    if(cc->flags&CCF_ASM_EXPRESSIONS) return I386AsmExpression(cc,_size,_type);
    return I386HostConstant(cc,_size,_type);
  }
  I386OutInit(&out);
  MemSet(&backend,0,sizeof(backend));
  backend.cc=cc; backend.out=&out; backend.types=cmp.internal_types; backend.context=&backend;
  backend.allocate=&I386HostBackendAlloc; backend.release=&I386HostBackendFree;
  backend.fold=&I386HostBackendFold; backend.assembly=&I386HostBackendAsm; backend.report=&I386HostBackendReport;
  try { I386BackendCore(&backend); }
  catch {
    if(Fs->except_ch=='Compiler' && backend.current)
      PrintErr("i386 COC failure at opcode %X, depth %d, pass %d\n",
        backend.current->ic_code,backend.depth,backend.pass);
    LinkedLstDel(backend.calls); LinkedLstDel(backend.logics); LinkedLstDel(backend.chains);
    Free(out.data);
  }
  LinkedLstDel(backend.logics); LinkedLstDel(backend.chains);
  result=CAlloc((out.count+7)&~7);
  MemCpy(result,out.data,out.count);
  if(_size) *_size=out.count;
  Free(out.data);
  for(ic=cc->coc.coc_head.next;ic!=&cc->coc.coc_head;ic=ic->next)
    if(ic->ic_code==IC_ASM) I386AsmFree(ic->ic_data);
  COCDel(cc,&cc->coc);
  return result;
}

public CAOT *CmpI386Buf(U8 *buf,I64 *error_cnt=NULL)
{
  CCmpCtrl *cc=CmpCtrlNew(buf,CCF_DONT_FREE_BUF|CCF_AOT_COMPILE|CCF_TARGET_I386);
  CAOT *res;
  QueIns(cc,Fs->last_cc);
  res=CmpJoin(cc,CMPF_LEX_FIRST);
  if (error_cnt) *error_cnt=cc->error_cnt;
  QueRem(cc);
  if (res) CmpCtrlDel(cc); //Follow CmpBuf error-path ownership.
  return res;
}
