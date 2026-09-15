#include "/Compiler/I386/Backend.HH"
#include "/Compiler/I386/EmitCore.HC"
I64 I386Size(CHashClass *c)
{
  if (!c) return 0;
  c=OptClassFwd(c);
  if (c->ptr_stars_cnt) return 4;
  return c->size;
}
U0 I386Normalize(CI386Out *out,CHashClass *c)
{//Normalize EDX:EAX to the target scalar width.
  if (!c) return;
  c=OptClassFwd(c);
  if (c->ptr_stars_cnt) {
    I386Bytes(out,"\x31\xD2",2);
    return;
  }
  switch (c->raw_type) {
    case RT_I8: I386Bytes(out,"\x0F\xBE\xC0\x99",4); break;
    case RT_U8: I386Bytes(out,"\x0F\xB6\xC0\x31\xD2",5); break;
    case RT_I16: I386Bytes(out,"\x0F\xBF\xC0\x99",4); break;
    case RT_U16: I386Bytes(out,"\x0F\xB7\xC0\x31\xD2",5); break;
    case RT_I32: I386Byte(out,0x99); break;
    case RT_U32: I386Bytes(out,"\x31\xD2",2); break;
    case RT_I64:
    case RT_U64:
    case RT_F64: break;
    default: throw('Compiler');
  }
}
U0 I386Load(CI386Out *out,CHashClass *c)
{//Dereference target address EAX; result EDX:EAX.
  if (I386Size(c)==8)
    I386Bytes(out,"\x8B\x50\x04\x8B\x00",5);
  else if (I386Size(c)==4)
    I386Bytes(out,"\x8B\x00",2);
  else if (I386Size(c)==2)
    I386Bytes(out,"\x0F\xB7\x00",3);
  else if (I386Size(c)==1)
    I386Bytes(out,"\x0F\xB6\x00",3);
  else throw('Compiler');
  I386Normalize(out,c);
}
U0 I386Store(CI386Out *out,CHashClass *c)
{//Store normalized EDX:EAX through target address ECX.
  I386Normalize(out,c);
  switch (I386Size(c)) {
    case 8: I386Bytes(out,"\x89\x51\x04\x89\x01",5); break;
    case 4: I386Bytes(out,"\x89\x01",2); break;
    case 2: I386Bytes(out,"\x66\x89\x01",3); break;
    case 1: I386Bytes(out,"\x88\x01",2); break;
    default: throw('Compiler');
  }
}

U0 I386Binary(CI386Out *out,I64 op)
{//EDX:EAX op EBX:ECX, with ESI/EDI scratch.
  switch (op) {
    case IC_ADD: I386Bytes(out,"\x01\xC8\x11\xDA",4); break;
    case IC_SUB: I386Bytes(out,"\x29\xC8\x19\xDA",4); break;
    case IC_AND: I386Bytes(out,"\x21\xC8\x21\xDA",4); break;
    case IC_OR: I386Bytes(out,"\x09\xC8\x09\xDA",4); break;
    case IC_XOR: I386Bytes(out,"\x31\xC8\x31\xDA",4); break;
    case IC_MUL:
      I386Bytes(out,"\x89\xC6\x89\xD7\x0F\xAF\xF9\x0F\xAF\xDE"
        "\xF7\xE1\x01\xFA\x01\xDA",16); break;
  }
}

U0 I386Shift(CI386Out *out,Bool left,Bool is_unsigned)
{//EDX:EAX shifted by ECX modulo 64, including the 32-bit boundary.
  I386Bytes(out,"\x83\xE1\x3F\xF6\xC1\x20",6);
  if (left)
    I386Bytes(out,"\x74\x08\x89\xC2\x31\xC0\xD3\xE2\xEB\x05"
      "\x0F\xA5\xC2\xD3\xE0",15);
  else if (is_unsigned)
    I386Bytes(out,"\x74\x08\x89\xD0\xD3\xE8\x31\xD2\xEB\x05"
      "\x0F\xAD\xD0\xD3\xEA",15);
  else
    I386Bytes(out,"\x74\x09\x89\xD0\xD3\xF8\xC1\xFA\x1F\xEB\x05"
      "\x0F\xAD\xD0\xD3\xFA",16);
}

U0 I386Compare(CI386Out *out,I64 op,Bool is_unsigned)
{//Compare EDX:EAX with EBX:ECX; high words first, low words unsigned.
  U8 low_cc,high_cc;
  switch (op) {
    case IC_EQU_EQU: low_cc=high_cc=0x94; break;
    case IC_NOT_EQU: low_cc=high_cc=0x95; break;
    case IC_LESS: low_cc=0x92; high_cc=0x9C; break;
    case IC_GREATER_EQU: low_cc=0x93; high_cc=0x9D; break;
    case IC_GREATER: low_cc=0x97; high_cc=0x9F; break;
    case IC_LESS_EQU: low_cc=0x96; high_cc=0x9E; break;
    default: throw('Compiler');
  }
  if (is_unsigned) high_cc=low_cc;
  I386Bytes(out,"\x39\xDA\x75\x07\x39\xC8\x0F",7);
  I386Byte(out,low_cc); I386Byte(out,0xC0);
  I386Bytes(out,"\xEB\x03\x0F",3);
  I386Byte(out,high_cc); I386Byte(out,0xC0);
  I386Bytes(out,"\x0F\xB6\xC0\x31\xD2",5);
}

Bool I386IsF64(CHashClass *c)
{
  if(c) c=OptClassFwd(c);
  return c && !c->ptr_stars_cnt && c->raw_type==RT_F64;
}

CHashClass *I386ValueClass(CI386Backend *backend,CIntermediateCode *ic)
{
  if (ic->ic_flags&ICF_RES_TO_F64) return backend->types[RT_F64];
  if (ic->ic_flags&ICF_RES_TO_INT) return backend->types[RT_I64];
  if (ic->ic_code==IC_NOT || ic->ic_code==IC_AND_AND ||
      ic->ic_code==IC_OR_OR || ic->ic_code==IC_XOR_XOR ||
      IC_EQU_EQU<=ic->ic_code<=IC_LESS_EQU)
    return backend->types[RT_I64];
  if(ic->ic_class) return OptClassFwd(ic->ic_class);
  return 0;
}

U0 I386F64Runtime(CI386Backend *backend,CI386Out *out,I64 op,I64 pass)
{//First operand EDX:EAX, optional second EBX:ECX; integer runtime ABI.
  CCmpCtrl *cc=backend->cc;
  U8 *name;
  CHashFun *fun;
  CHashClass *type=0;
  CMemberLst *arg;
  CExternUsage *usage;
  CAOTImportExport *import_rec;
  I64 i,return_type=RT_U64,arg_type=RT_U64,arg_count=2;
  U8 condition=0x94,compare_value=0;
  switch (op) {
    case IC_SQRT: name="I386F64Sqrt"; arg_count=1; break;
    case IC_ABS: name="I386F64Abs"; arg_count=1; break;
    case IC_ADD: name="I386F64Add"; break;
    case IC_SUB: name="I386F64Sub"; break;
    case IC_MUL: name="I386F64Mul"; break;
    case IC_DIV: name="I386F64Div"; break;
    case IC_MOD: name="I386F64Mod"; break;
    case IC_TO_F64:
      name="I386F64FromI64"; arg_type=RT_I64; arg_count=1; break;
    case IC_TO_I64:
      name="I386F64ToI64"; return_type=RT_I64; arg_count=1; break;
    case IC_EQU_EQU...IC_LESS_EQU:
      name="I386F64Compare"; return_type=RT_I64; break;
    default: throw('Compiler');
  }
  fun=HashFind(name,cc->htc.hash_table_lst,HTT_FUN);
  if (fun && fun->return_class) type=OptClassFwd(fun->return_class);
  if (!fun || fun->arg_cnt!=arg_count || !type || type->ptr_stars_cnt ||
      type->raw_type!=return_type || I386Size(type)!=8 ||
      Bt(&fun->flags,Ff_INTERNAL) || Bt(&fun->flags,Ff_DOT_DOT_DOT) ||
      Bt(&fun->flags,Ff_NOARGPOP)) {
    (*backend->report)(backend->context,1,0,name);
    throw('Compiler');
  }
  arg=fun->member_lst_and_root;
  for (i=0;i<arg_count;i++,arg=arg->next) {
    if (!arg || !arg->member_class || arg->dim.next) throw('Compiler');
    type=OptClassFwd(arg->member_class);
    if (type->ptr_stars_cnt || type->raw_type!=arg_type || I386Size(type)!=8)
      throw('Compiler');
  }
  if (arg_count==2) I386Bytes(out,"\x53\x51",2);
  I386Bytes(out,"\x52\x50\xE8",3);
  if (fun->type&HTF_IMPORT) {
    if (pass) {
      import_rec=(*backend->allocate)(backend->context,sizeof(CAOTImportExport));
      import_rec->type=IET_REL_I32;
      import_rec->rip=cc->aotc->rip+out->count;
      import_rec->next=fun->ie_lst; fun->ie_lst=import_rec;
    }
    I386Dword(out,0);
  } else if (Bt(&fun->flags,Cf_EXTERN)) {
    if (pass) {
      usage=(*backend->allocate)(backend->context,sizeof(CExternUsage));
      usage->next=fun->ext_lst; fun->ext_lst=usage;
      usage->rip=cc->aotc->rip+out->count;
    }
    I386Dword(out,0);
  } else {
    if ((fun->exe_addr+0)(U64)>=cc->aotc->rip(U64)) {
      (*backend->report)(backend->context,2,0,name);
      throw('Compiler');
    }
    I386Dword(out,(fun->exe_addr+0)(I64)-(cc->aotc->rip+out->count+4));
  }
  if (op>=IC_EQU_EQU && op<=IC_LESS_EQU) {
    //Unordered is 2: equality is false, inequality true, ordered relations false.
    switch (op) {
      case IC_EQU_EQU: break;
      case IC_NOT_EQU: condition=0x95; break;
      case IC_LESS: compare_value=0xFF; break;
      case IC_GREATER: compare_value=1; break;
      case IC_LESS_EQU: condition=0x9E; break;
      case IC_GREATER_EQU: compare_value=1; condition=0x96; break;
    }
    I386Bytes(out,"\x83\xF8",2); I386Byte(out,compare_value);
    I386Byte(out,0x0F); I386Byte(out,condition); I386Byte(out,0xC0);
    I386Bytes(out,"\x0F\xB6\xC0\x31\xD2",5);
  }

}

U0 I386F64Update(CI386Backend *backend,CI386Out *out,I64 op,I64 pass,Bool integer_left)
{//The caller keeps the destination address below the evaluation operands.
  if (integer_left) {
    I386Bytes(out,"\x53\x51",2);
    I386F64Runtime(backend,out,IC_TO_F64,pass);
    I386Bytes(out,"\x59\x5B",2);
  }
  I386F64Runtime(backend,out,op,pass);
  if (integer_left) I386F64Runtime(backend,out,IC_TO_I64,pass);
}

U0 I386BranchLogic(CI386Backend *backend,CIntermediateCode *ic)
{
  CI386Logic *logic;
  if(ic->ic_code==IC_NOT) I386BranchLogic(backend,ic->t.arg1_tree);
  if(ic->ic_code==IC_AND_AND || ic->ic_code==IC_OR_OR) {
    logic=(*backend->allocate)(backend->context,sizeof(CI386Logic));
    logic->next=backend->logics; backend->logics=logic;
    logic->left=ic->t.arg1_tree; logic->end=ic;
    I386BranchLogic(backend,ic->t.arg1_tree);
    I386BranchLogic(backend,ic->t.arg2_tree);
  }
}
U0 I386Bool(CI386Out *out)
{//Normalize the top evaluation slot to zero or one.
  I386Bytes(out,"\x58\x5A\x09\xD0\x0F\x95\xC0\x0F\xB6\xC0"
    "\x31\xD2\x52\x50",14);
}

U0 I386BackendCore(CI386Backend *backend)
{
  CCmpCtrl *cc=backend->cc;
  CI386Out *out=backend->out;
  CIntermediateCode *ic;
  CCodeMisc *label,*switch_table,*asm_label;
  CI386Call *call;
  CI386Logic *logic;
  CI386Chain *chain;
  CExternUsage *usage;
  CAOTImportExport *import_rec;
  CMemberLst *arg;
  I64 arg_index,arg_offset,pool_start,switch_base,switch_index;
  I64 depth,pass,stack_size=0,args=0;
  CHashClass *c;
  CHashFun *addr_fun;
  if (!(cc->flags&CCF_AOT_COMPILE) || cc->flags&CCF_EXE_BLK)
    throw('Compiler');
  if (!cc->htc.fun || cc->coc.coc_head.next->ic_code!=IC_ENTER) {
    (*backend->report)(backend->context,3,cc->coc.coc_head.next,0);
    throw('Compiler');
  }
  if (cc->htc.fun) {
    stack_size=-cc->htc.fun->size;
    args=cc->htc.fun->arg_cnt*8;
    if (Bt(&cc->htc.fun->flags,Ff_DOT_DOT_DOT)) args=0;
    if (args>65535) throw('Compiler');
  }
  //Nested assembler parsing creates its own label records. Join a prior HolyC
  //goto placeholder to the definition before native branch offsets are assigned.
  for(asm_label=cc->coc.coc_next_misc;asm_label!=&cc->coc.coc_next_misc;asm_label=asm_label->next)
    if(asm_label->type==CMT_ASM_LABEL && asm_label->flags&CMF_DEFINED)
      for(label=cc->coc.coc_next_misc;label!=&cc->coc.coc_next_misc;label=label->next)
        if(label->type==CMT_GOTO_LABEL && !(label->flags&CMF_DEFINED) &&
            !StrCmp(label->str,asm_label->str)) {
          label->flags|=CMF_DEFINED; label->fwd=asm_label;
        }
  //Logical results are integer booleans, regardless of operand precision metadata.
  for (ic=cc->coc.coc_head.next;ic!=&cc->coc.coc_head;ic=ic->next)
    if (ic->ic_code==IC_NOT || ic->ic_code==IC_AND_AND ||
        ic->ic_code==IC_OR_OR || ic->ic_code==IC_XOR_XOR)
      ic->ic_class=ic->ic_class2=backend->types[RT_I64];
  if(backend->status) { backend->status->node=cc->coc.coc_head.next; backend->status->pass=-1; }
  cc->pass=0;
  (*backend->fold)(backend->context,cc);
  //Refresh operand links after constant/intrinsic rewrites replace producer nodes.
  (*backend->fold)(backend->context,cc);
  {
    for (ic=cc->coc.coc_head.next;ic!=&cc->coc.coc_head;ic=ic->next)
      if (ic->ic_code==IC_PUSH_CMP) {
        chain=(*backend->allocate)(backend->context,sizeof(CI386Chain));
        chain->next=backend->chains; backend->chains=chain;
        chain->push=ic;
        chain->comparison=OptLag(ic);
        if (chain->comparison && chain->comparison->ic_code==IC_AND_AND)
          chain->comparison=OptLag(chain->comparison);
        if (!chain->comparison ||
            !(chain->comparison->ic_flags&ICF_PUSH_CMP) ||
            !(IC_EQU_EQU<=chain->comparison->ic_code<=IC_LESS_EQU))
          throw('Compiler');
        stack_size=(stack_size+7)&~7;
        stack_size+=8; chain->slot=-stack_size;
      }
    for (ic=cc->coc.coc_head.next;ic!=&cc->coc.coc_head;ic=ic->next)
      if (ic->ic_code==IC_BR_ZERO || ic->ic_code==IC_BR_NOT_ZERO)
        I386BranchLogic(backend,ic->t.arg1_tree);
    // First pass determines label offsets; second resolves near branches.
    for (pass=0;pass<2;pass++) {
      out->count=0;
      depth=0;
      for (ic=cc->coc.coc_head.next;ic!=&cc->coc.coc_head;ic=ic->next) {
        backend->current=ic; backend->depth=depth; backend->pass=pass;
        if(backend->status) {
          backend->status->node=ic; backend->status->depth=depth; backend->status->pass=pass;
        }
        c=ic->ic_class;
        if(c) c=OptClassFwd(c);
        if (ic->ic_code==IC_NOT || ic->ic_code==IC_AND_AND ||
            ic->ic_code==IC_OR_OR || ic->ic_code==IC_XOR_XOR)
          c=backend->types[RT_I64];
        if ((ic->ic_flags&(ICF_RES_TO_F64|ICF_RES_TO_INT))==
            (ICF_RES_TO_F64|ICF_RES_TO_INT)) throw('Compiler');
        if (I386IsF64(c) ||
            (intermediate_code_table[ic->ic_code].arg_cnt==IS_1_ARG && I386IsF64(I386ValueClass(backend,ic->t.arg1_tree))) ||
            (intermediate_code_table[ic->ic_code].arg_cnt==IS_2_ARG &&
             (I386IsF64(I386ValueClass(backend,ic->t.arg1_tree)) || I386IsF64(I386ValueClass(backend,ic->t.arg2_tree))))) {
          switch (ic->ic_code) {
            //HolyC conditions test raw bits, including the F64 sign bit.
            case IC_NOT: case IC_AND_AND: case IC_OR_OR: case IC_XOR_XOR:
            case IC_BR_ZERO: case IC_BR_NOT_ZERO:
            case IC_SQR: case IC_ABS: case IC_SQRT:
            case IC_TO_F64: case IC_TO_I64: case IC_TO_BOOL:
            //An explicit bitwise cast can retain an I64 immediate opcode with F64 type.
            case IC_NOP1: case IC_NOP2: case IC_IMM_I64: case IC_IMM_F64: case IC_PUSH_CMP:
            case IC_SHL_CONST: case IC_SHR_CONST:
            case IC_DEREF: case IC_ADDR: case IC_HOLYC_TYPECAST:
            case IC_CALL: case IC_CALL_EXTERN: case IC_CALL_IMPORT:
            case IC_CALL_INDIRECT: case IC_LEAVE:
            case IC_ADD_RSP: case IC_ADD_RSP1:
            case IC_CALL_START: case IC_PUSH_REGS: case IC_SET_RAX:
            case IC_ENTER: case IC_RET: case IC_LABEL: case IC_JMP:
            case IC_CALL_END: case IC_RETURN_VAL: case IC_RETURN_VAL2:
            case IC_END_EXP: break;
            case IC_EQU_EQU...IC_LESS_EQU:
              if (!I386IsF64(I386ValueClass(backend,ic->t.arg1_tree)) || !I386IsF64(I386ValueClass(backend,ic->t.arg2_tree)))
                throw('Compiler');
              break;
            case IC_ADD_EQU: case IC_SUB_EQU: case IC_MUL_EQU: case IC_DIV_EQU: case IC_MOD_EQU:
              if (!I386IsF64(I386ValueClass(backend,ic->t.arg2_tree)) || c->ptr_stars_cnt ||
                  I386Size(c)<1 || I386Size(c)>8) throw('Compiler');
              break;
            case IC_AND_EQU: case IC_OR_EQU: case IC_XOR_EQU:
            case IC_SHL_EQU: case IC_SHR_EQU:
              //These operate on stored bits; an integer destination stays integer.
              if (c->ptr_stars_cnt || I386Size(c)<1 || I386Size(c)>8) throw('Compiler');
              break;
            case IC_ASSIGN:
              if (!I386IsF64(c) || !I386IsF64(I386ValueClass(backend,ic->t.arg2_tree))) throw('Compiler');
              break;
            case IC__PP: case IC__MM: case IC_PP_: case IC_MM_:
            case IC_UNARY_MINUS:
              if (!I386IsF64(c)) throw('Compiler');
              break;
            case IC_AND: case IC_OR: case IC_XOR: case IC_SHL: case IC_SHR:
            case IC_ADD: case IC_SUB: case IC_MUL: case IC_DIV: case IC_MOD:
              if (!I386IsF64(c) || !I386IsF64(I386ValueClass(backend,ic->t.arg1_tree)) ||
                  !I386IsF64(I386ValueClass(backend,ic->t.arg2_tree))) {
                (*backend->report)(backend->context,4,ic,0);
                throw('Compiler');
              }
              break;
            default: throw('Compiler');
          }
        }
        if (ic->ic_flags&(ICF_PUSH_CMP|ICF_POP_CMP) &&
            !(IC_EQU_EQU<=ic->ic_code<=IC_LESS_EQU) &&
            ic->ic_code!=IC_AND_AND) throw('Compiler');
        switch (ic->ic_code) {
          case IC_NOP1:
          case IC_NOP2: break;
          case IC_CALL_START:
            call=(*backend->allocate)(backend->context,sizeof(CI386Call));
            call->next=backend->calls;
            backend->calls=call;
            call->fun=ic->ic_data;
            call->depth=depth;
            if (!call->fun || Bt(&call->fun->flags,Ff_NOARGPOP)) throw('Compiler');
            call->slots=call->fun->arg_cnt;
            break;
          case IC_SET_RAX:
            //PrsFunCall stages an indirect target before CALL_START.
            //Keep it in its evaluation slot until IC_PUSH_REGS marks it.
            if (depth<1 || ic->next->ic_code!=IC_NOP2 ||
                ic->next->next->ic_code!=IC_CALL_START) throw('Compiler');
            break;
          case IC_PUSH_REGS:
            //The expression stack already holds the function pointer pair.
            if (!backend->calls || backend->calls->called || backend->calls->indirect ||
                ic->ic_data!=1<<REG_RAX || depth<1) throw('Compiler');
            backend->calls->indirect=TRUE;
            backend->calls->depth--;
            break;
          case IC_SQR:
          case IC_ABS:
          case IC_SQRT:
            //Template intrinsics have no CALL_START/CALL_END nodes.
            if (depth<1 || !I386IsF64(c) ||
                !I386IsF64(I386ValueClass(backend,ic->t.arg1_tree))) throw('Compiler');
            I386Bytes(out,"\x58\x5A",2);
            if (ic->ic_code==IC_SQR) {
              I386Bytes(out,"\x89\xC1\x89\xD3",4);
              I386F64Runtime(backend,out,IC_MUL,pass);
            } else I386F64Runtime(backend,out,ic->ic_code,pass);
            I386Bytes(out,"\x52\x50",2);
            break;
          case IC_TOUPPER:
            if (!backend->calls || backend->calls->called || backend->calls->indirect ||
                !Bt(&backend->calls->fun->flags,Ff_INTERNAL) ||
                backend->calls->fun->exe_addr!=ic->ic_code || backend->calls->fun->arg_cnt!=1 ||
                depth!=backend->calls->depth+1) throw('Compiler');
            //Match ICToUpper: only I64 values 'a' through 'z' change.
            //The legacy intrinsic preserves wider arguments despite its U8 signature.
            I386Bytes(out,"\x58\x5A\x85\xD2\x75\x0D\x83\xF8\x61\x72\x08\x83\xF8\x7A\x77\x03\x83\xE8\x20",19);
            depth=backend->calls->depth;
            backend->calls->called=TRUE;
            break;
          case IC_BT: case IC_BTS: case IC_BTR: case IC_BTC:
          case IC_LBTS: case IC_LBTR: case IC_LBTC:
            if (!backend->calls || backend->calls->called || backend->calls->indirect ||
                !Bt(&backend->calls->fun->flags,Ff_INTERNAL) ||
                backend->calls->fun->exe_addr!=ic->ic_code || backend->calls->fun->arg_cnt!=2 ||
                depth!=backend->calls->depth+2) throw('Compiler');
            //EAX=base, EBX:ECX=signed I64 bit offset. Fold the full offset
            //into a target-width dword address; ESI selects its low five bits.
            I386Bytes(out,"\x58\x5A\x59\x5B\x89\xCE\x83\xE6\x1F"
              "\x0F\xAC\xD9\x05\xC1\xE1\x02\x01\xC8",18);
            if (IC_LBTS<=ic->ic_code<=IC_LBTC) I386Byte(out,0xF0);
            I386Byte(out,0x0F);
            if (ic->ic_code==IC_BT) I386Byte(out,0xA3);
            else if (ic->ic_code==IC_BTS || ic->ic_code==IC_LBTS) I386Byte(out,0xAB);
            else if (ic->ic_code==IC_BTR || ic->ic_code==IC_LBTR) I386Byte(out,0xB3);
            else I386Byte(out,0xBB);
            I386Bytes(out,"\x30\x0F\x92\xC0\x0F\xB6\xC0\x31\xD2",9);
            depth=backend->calls->depth;
            backend->calls->called=TRUE;
            break;
          case IC_BSF: case IC_BSR:
            if (!backend->calls || backend->calls->called || backend->calls->indirect ||
                !Bt(&backend->calls->fun->flags,Ff_INTERNAL) ||
                backend->calls->fun->exe_addr!=ic->ic_code || backend->calls->fun->arg_cnt!=1 ||
                depth!=backend->calls->depth+1) throw('Compiler');
            I386Bytes(out,"\x58\x5A",2);
            //Scan both halves; test zero explicitly because BSF/BSR leave
            //the destination undefined for zero. CDQ widens the -1 sentinel.
            if (ic->ic_code==IC_BSF)
              I386Bytes(out,"\x85\xC0\x75\x0C\x85\xD2\x74\x0D\x0F\xBC\xC2\x83\xC0\x20\xEB\x0A\x0F\xBC\xC0\xEB\x05\xB8\xFF\xFF\xFF\xFF\x99",27);
            else I386Bytes(out,"\x85\xD2\x74\x08\x0F\xBD\xC2\x83\xC0\x20\xEB\x0E\x85\xC0\x74\x05\x0F\xBD\xC0\xEB\x05\xB8\xFF\xFF\xFF\xFF\x99",27);
            depth=backend->calls->depth;
            backend->calls->called=TRUE;
            break;
          case IC_MOD_U64:
            if (!backend->calls || backend->calls->called || backend->calls->indirect ||
                !Bt(&backend->calls->fun->flags,Ff_INTERNAL) ||
                backend->calls->fun->exe_addr!=ic->ic_code || backend->calls->fun->arg_cnt!=2 ||
                depth!=backend->calls->depth+2) throw('Compiler');
            //Save the destination while the single division produces both results.
            I386Bytes(out,"\x58\x5A\x59\x5B\x50",5);
            I386Load(out,backend->types[RT_U64]);
            I386Byte(out,0xBE); I386Dword(out,4);
            I386Bytes(out,&I386DivBegin,(&I386DivEnd)(U8 *)-(&I386DivBegin)(U8 *));
            I386Byte(out,0x59);
            I386Store(out,backend->types[RT_U64]);
            I386Bytes(out,"\x89\xF0\x89\xFA",4);
            depth=backend->calls->depth;
            backend->calls->called=TRUE;
            break;
          case IC_ABS_I64: case IC_SIGN_I64:
          case IC_SQR_I64: case IC_SQR_U64:
          case IC_MIN_I64: case IC_MIN_U64: case IC_MAX_I64: case IC_MAX_U64:
            arg_index=1;
            if (IC_MIN_I64<=ic->ic_code<=IC_MAX_U64) arg_index=2;
            if (!backend->calls || backend->calls->called || backend->calls->indirect ||
                !Bt(&backend->calls->fun->flags,Ff_INTERNAL) ||
                backend->calls->fun->exe_addr!=ic->ic_code || backend->calls->fun->arg_cnt!=arg_index ||
                depth!=backend->calls->depth+arg_index) throw('Compiler');
            I386Bytes(out,"\x58\x5A",2);
            if (arg_index==2) {
              I386Bytes(out,"\x59\x5B\x89\xC6\x89\xD7",6);
              if (ic->ic_code==IC_MIN_I64 || ic->ic_code==IC_MIN_U64)
                I386Compare(out,IC_LESS,ic->ic_code==IC_MIN_U64);
              else I386Compare(out,IC_GREATER,ic->ic_code==IC_MAX_U64);
              I386Bytes(out,"\x85\xC0\x74\x06\x89\xF0\x89\xFA"
                "\xEB\x04\x89\xC8\x89\xDA",14);
            } else if (ic->ic_code==IC_ABS_I64)
              I386Bytes(out,"\x85\xD2\x79\x07\xF7\xD8\x83\xD2\x00\xF7\xDA",11);
            else if (ic->ic_code==IC_SIGN_I64)
              I386Bytes(out,"\x89\xC1\x09\xD1\x0F\x95\xC0\x0F\xB6\xC0"
                "\xC1\xFA\x1F\x09\xD0",15);
            else {
              I386Bytes(out,"\x89\xC1\x89\xD3",4);
              I386Binary(out,IC_MUL);
            }
            depth=backend->calls->depth;
            backend->calls->called=TRUE;
            break;
          case IC_TO_F64:
          case IC_TO_I64:
          case IC_TO_BOOL:
            if (!backend->calls || backend->calls->called || backend->calls->indirect ||
                !Bt(&backend->calls->fun->flags,Ff_INTERNAL) ||
                backend->calls->fun->exe_addr!=ic->ic_code || backend->calls->fun->arg_cnt!=1 ||
                depth!=backend->calls->depth+1) throw('Compiler');
            I386Bytes(out,"\x58\x5A",2);
            if ((ic->ic_code==IC_TO_I64 && I386IsF64(I386ValueClass(backend,ic->t.arg1_tree))) ||
                (ic->ic_code==IC_TO_F64 && !I386IsF64(I386ValueClass(backend,ic->t.arg1_tree))))
              I386F64Runtime(backend,out,ic->ic_code,pass);
            if (ic->ic_code==IC_TO_BOOL)
              I386Bytes(out,"\x09\xD0\x0F\x95\xC0\x0F\xB6\xC0\x31\xD2",10);
            depth=backend->calls->depth;
            backend->calls->called=TRUE;
            break;
          case IC_FS:
          case IC_GS:
            if (!backend->calls || backend->calls->called || backend->calls->indirect ||
                !Bt(&backend->calls->fun->flags,Ff_INTERNAL) ||
                backend->calls->fun->exe_addr!=ic->ic_code || backend->calls->fun->arg_cnt ||
                depth!=backend->calls->depth) throw('Compiler');
            //The first native pointer in each segment record is its flat self address.
            if (ic->ic_code==IC_FS) I386Byte(out,0x64);
            else I386Byte(out,0x65);
            I386Byte(out,0xA1); I386Dword(out,0);
            I386Bytes(out,"\x31\xD2",2);
            backend->calls->called=TRUE;
            break;
          case IC_GET_RBP:
          case IC_GET_RSP:
            if (!backend->calls || backend->calls->called || backend->calls->indirect ||
                !Bt(&backend->calls->fun->flags,Ff_INTERNAL) ||
                backend->calls->fun->exe_addr!=ic->ic_code || backend->calls->fun->arg_cnt ||
                depth!=backend->calls->depth) throw('Compiler');
            if(ic->ic_code==IC_GET_RSP) I386Bytes(out,"\x89\xE0\x31\xD2",4);
            else I386Bytes(out,"\x89\xE8\x31\xD2",4);
            backend->calls->called=TRUE;
            break;
          case IC_GET_RFLAGS:
          case IC_SET_RFLAGS:
            arg_index=0;
            if (ic->ic_code==IC_SET_RFLAGS) arg_index=1;
            if (!backend->calls || backend->calls->called || backend->calls->indirect ||
                !Bt(&backend->calls->fun->flags,Ff_INTERNAL) ||
                backend->calls->fun->exe_addr!=ic->ic_code ||
                backend->calls->fun->arg_cnt!=arg_index ||
                depth!=backend->calls->depth+arg_index) throw('Compiler');
            if (!arg_index)
              I386Bytes(out,"\x9C\x58\x31\xD2",4); //PUSHFD; POP EAX; zero high half.
            else
              I386Bytes(out,"\x58\x59\x50\x9D",4); //Consume I64; POPFD uses low 32 bits.
            depth=backend->calls->depth;
            backend->calls->called=TRUE;
            break;
          case IC_IN_U8:
          case IC_IN_U16:
          case IC_IN_U32:
          case IC_OUT_U8:
          case IC_OUT_U16:
          case IC_OUT_U32:
            arg_index=1;
            if (ic->ic_code>=IC_OUT_U8) arg_index=2;
            if (!backend->calls || backend->calls->called || backend->calls->indirect ||
                !Bt(&backend->calls->fun->flags,Ff_INTERNAL) ||
                backend->calls->fun->exe_addr!=ic->ic_code ||
                backend->calls->fun->arg_cnt!=arg_index ||
                depth!=backend->calls->depth+arg_index) throw('Compiler');
            //Arguments retain eight-byte slots; hardware consumes DX and AL/AX/EAX.
            if (arg_index==1) {
              I386Bytes(out,"\x5A\x59\x31\xC0",4);
              if (ic->ic_code==IC_IN_U16) I386Byte(out,0x66);
              if (ic->ic_code==IC_IN_U8) I386Byte(out,0xEC);
              else I386Byte(out,0xED);
              I386Bytes(out,"\x31\xD2",2);
            } else {
              I386Bytes(out,"\x5A\x59\x58\x59",4);
              if (ic->ic_code==IC_OUT_U16) I386Byte(out,0x66);
              if (ic->ic_code==IC_OUT_U8) I386Byte(out,0xEE);
              else I386Byte(out,0xEF);
            }
            depth=backend->calls->depth;
            backend->calls->called=TRUE;
            break;
          case IC_CALL_INDIRECT:
          case IC_CALL:
          case IC_CALL_EXTERN:
          case IC_CALL_IMPORT:
            if (!backend->calls || backend->calls->called ||
                backend->calls->indirect!=(ic->ic_code==IC_CALL_INDIRECT)) throw('Compiler');
            backend->calls->slots=depth-backend->calls->depth-backend->calls->indirect;
            if (Bt(&backend->calls->fun->flags,Ff_DOT_DOT_DOT)) {
              if (backend->calls->slots<backend->calls->fun->arg_cnt+1) throw('Compiler');
            } else if (backend->calls->slots!=backend->calls->fun->arg_cnt) throw('Compiler');
            arg=backend->calls->fun->member_lst_and_root;
            for (arg_index=0;arg_index<backend->calls->fun->arg_cnt;arg_index++) {
              c=arg->member_class;
              if (arg->dim.next) c=backend->types[RT_U8]+1;
              if (I386Size(c)<8) {
                arg_offset=arg_index*8;
                I386Bytes(out,"\x8B\x84\x24",3); I386Dword(out,arg_offset);
                I386Bytes(out,"\x8B\x94\x24",3); I386Dword(out,arg_offset+4);
                I386Normalize(out,c);
                I386Bytes(out,"\x89\x84\x24",3); I386Dword(out,arg_offset);
                I386Bytes(out,"\x89\x94\x24",3); I386Dword(out,arg_offset+4);
              }
              arg=arg->next;
            }
            if (backend->calls->indirect) {
              if (ic->ic_data!=backend->calls->slots*8) throw('Compiler');
              I386Bytes(out,"\xFF\x94\x24",3);
              I386Dword(out,ic->ic_data);
            } else {
              I386Byte(out,0xE8);
              if (ic->ic_code==IC_CALL) {
                I386Dword(out,ic->ic_data-(cc->aotc->rip+out->count+4));
              } else if (ic->ic_code==IC_CALL_IMPORT) {
                if (pass) {
                  import_rec=(*backend->allocate)(backend->context,sizeof(CAOTImportExport));
                  import_rec->type=IET_REL_I32;
                  import_rec->rip=cc->aotc->rip+out->count;
                  import_rec->next=backend->calls->fun->ie_lst;
                  backend->calls->fun->ie_lst=import_rec;
                }
                I386Dword(out,0);
              } else {
                if (pass) {
                  usage=(*backend->allocate)(backend->context,sizeof(CExternUsage));
                  usage->next=backend->calls->fun->ext_lst;
                  backend->calls->fun->ext_lst=usage;
                  usage->rip=cc->aotc->rip+out->count;
                }
                I386Dword(out,0);
              }
            }
            //Variadic callees leave fixed slots, argc and all argv values to the caller.
            if (Bt(&backend->calls->fun->flags,Ff_DOT_DOT_DOT)) {
              I386Bytes(out,"\x81\xC4",2); I386Dword(out,backend->calls->slots*8);
            }
            if (backend->calls->indirect) I386Bytes(out,"\x83\xC4\x08",3);
            depth=backend->calls->depth;
            backend->calls->called=TRUE;
            break;
          case IC_ADD_RSP1:
          case IC_ADD_RSP:
            if (!backend->calls || !backend->calls->called) throw('Compiler');
            if (backend->calls->indirect && ic->ic_code==IC_ADD_RSP) {
              if (ic->ic_data!=8 && ic->ic_data!=(backend->calls->slots+1)*8)
                throw('Compiler');
            } else if (ic->ic_data!=backend->calls->slots*8) throw('Compiler');
            //Argument and saved-target cleanup was handled with the call.
            break;
          case IC_CALL_END:
            if (!backend->calls || !backend->calls->called || backend->calls->fun!=ic->ic_data)
              throw('Compiler');
            if (I386Size(backend->calls->fun->return_class))
              I386Normalize(out,backend->calls->fun->return_class);
            else I386Bytes(out,"\x31\xC0\x31\xD2",4);
            I386Bytes(out,"\x52\x50",2);
            depth++;
            call=backend->calls; backend->calls=call->next; (*backend->release)(backend->context,call);
            break;
          case IC_AND_AND:
          case IC_OR_OR:
            for (logic=backend->logics;logic;logic=logic->next)
              if (logic->end==ic) break;
            if (logic) {
              if (depth<1) throw('Compiler');
              I386Bool(out);
              if (!pass) logic->address=out->count;
              break;
            }
          case IC_XOR_XOR:
            if (depth<2) throw('Compiler');
            I386Bytes(out,"\x59\x5B\x58\x5A\x09\xD0\x0F\x95\xC0"
              "\x09\xD9\x0F\x95\xC1",14);
            if (ic->ic_code==IC_AND_AND) I386Byte(out,0x20);
            else if (ic->ic_code==IC_OR_OR) I386Byte(out,0x08);
            else I386Byte(out,0x30);
            I386Bytes(out,"\xC8\x0F\xB6\xC0\x31\xD2\x52\x50",8);
            depth--;
            break;
          case IC_ENTER:
            I386Bytes(out,"\x55\x89\xE5\x81\xEC",5);
            I386Dword(out,stack_size);
            I386Bytes(out,"\x53\x56\x57",3);
            break;
          case IC_IMM_I64:
          case IC_IMM_F64:
          case IC_TYPE:
            I386Byte(out,0x68); I386Dword(out,ic->ic_data.u32[1]);
            I386Byte(out,0x68); I386Dword(out,ic->ic_data.u32[0]);
            depth++;
            break;
          case IC_GET_LABEL:
            label=OptLabelFwd(ic->ic_data);
            if(!label) throw('Compiler');
            I386Byte(out,0xE8); I386Dword(out,0);
            arg_offset=out->count;
            I386Bytes(out,"\x58\x05",2);
            I386Dword(out,label->addr-arg_offset);
            I386Bytes(out,"\x31\xD2\x52\x50",4);
            depth++;
            break;
          case IC_STR_CONST:
            label=ic->ic_data;
            if (!label || label->type!=CMT_STR_CONST || !label->str || label->st_len<1)
              throw('Compiler');
            I386Byte(out,0xE8); I386Dword(out,0);
            arg_offset=out->count;
            I386Bytes(out,"\x58\x05",2);
            I386Dword(out,label->addr-arg_offset);
            I386Bytes(out,"\x31\xD2\x52\x50",4);
            depth++;
            break;
          case IC_ADDR_IMPORT:
            addr_fun=ic->ic_data;
            if (!(addr_fun->type&HTT_FUN) && !(addr_fun->type&HTF_IMPORT))
              throw('Compiler');
            //Use the ordinary forward REL32 fixup at ADD's immediate.
            //The saved PC plus nine equals the end of that immediate.
            I386Byte(out,0xE8); I386Dword(out,0);
            I386Bytes(out,"\x58\x83\xC0\x09\x05",5);
            if (pass) {
              if (addr_fun->type&HTF_IMPORT) {
                import_rec=(*backend->allocate)(backend->context,sizeof(CAOTImportExport));
                import_rec->type=IET_I386_REL32_ADDR;
                import_rec->rip=cc->aotc->rip+out->count;
                import_rec->next=addr_fun->ie_lst;
                addr_fun->ie_lst=import_rec;
              } else {
                usage=(*backend->allocate)(backend->context,sizeof(CExternUsage));
                usage->next=addr_fun->ext_lst;
                addr_fun->ext_lst=usage;
                usage->rip=cc->aotc->rip+out->count;
              }
            }
            I386Dword(out,0);
            I386Bytes(out,"\x31\xD2\x52\x50",4);
            depth++;
            break;
          case IC_ABS_ADDR:
            //Materialize a module-relative address without a load-address fixup.
            I386Byte(out,0xE8); I386Dword(out,0);
            arg_offset=cc->aotc->rip+out->count;
            I386Bytes(out,"\x58\x05",2);
            I386Dword(out,ic->ic_data-arg_offset);
            I386Bytes(out,"\x31\xD2\x52\x50",4);
            depth++;
            break;
          case IC_RBP:
            I386Bytes(out,"\x6A\x00\x55",3);
            depth++;
            break;
          case IC_DEREF:
            if (depth<1) throw('Compiler');
            I386Bytes(out,"\x58\x5A",2);
            I386Load(out,c);
            I386Bytes(out,"\x52\x50",2);
            break;
          case IC_ADDR:
          case IC_HOLYC_TYPECAST:
            if (depth<1) throw('Compiler');
            I386Bytes(out,"\x58\x5A",2);
            I386Normalize(out,c);
            I386Bytes(out,"\x52\x50",2);
            break;
          case IC_UNARY_MINUS:
          case IC_COM:
          case IC_NOT:
            if (depth<1) throw('Compiler');
            I386Bytes(out,"\x58\x5A",2);
            if (ic->ic_code==IC_UNARY_MINUS && I386IsF64(c))
              I386Bytes(out,"\x81\xF2\x00\x00\x00\x80",6);
            else if (ic->ic_code==IC_UNARY_MINUS)
              I386Bytes(out,"\xF7\xD8\x83\xD2\x00\xF7\xDA",7);
            else if (ic->ic_code==IC_COM)
              I386Bytes(out,"\xF7\xD0\xF7\xD2",4);
            else
              I386Bytes(out,"\x09\xD0\x0F\x94\xC0\x0F\xB6\xC0\x31\xD2",10);
            I386Bytes(out,"\x52\x50",2);
            break;
          case IC_PUSH_CMP:
            for (chain=backend->chains;chain;chain=chain->next)
              if (chain->push==ic) break;
            if (!chain) throw('Compiler');
            I386Bytes(out,"\xFF\xB5",2); I386Dword(out,chain->slot+4);
            I386Bytes(out,"\xFF\xB5",2); I386Dword(out,chain->slot);
            depth++;
            break;
          case IC_EQU_EQU...IC_LESS_EQU:
            if (depth<2) throw('Compiler');
            I386Bytes(out,"\x59\x5B\x58\x5A",4);
            if (ic->ic_flags&ICF_PUSH_CMP) {
              for (chain=backend->chains;chain;chain=chain->next)
                if (chain->comparison==ic) break;
              if (!chain) throw('Compiler');
              //Retain the middle operand once, independently of branch stack depth.
              I386Bytes(out,"\x89\x8D",2); I386Dword(out,chain->slot);
              I386Bytes(out,"\x89\x9D",2); I386Dword(out,chain->slot+4);
            }
            if (I386IsF64(I386ValueClass(backend,ic->t.arg1_tree)))
              I386F64Runtime(backend,out,ic->ic_code,pass);
            else I386Compare(out,ic->ic_code,ToBool(ic->ic_flags&ICF_USE_UNSIGNED));
            I386Bytes(out,"\x52\x50",2);
            depth--;
            break;
          case IC_BR_ZERO:
          case IC_BR_NOT_ZERO:
            if (depth!=1) throw('Compiler');
            I386Bytes(out,"\x58\x5A\x09\xD0\x0F",5);
            if (ic->ic_code==IC_BR_ZERO) I386Byte(out,0x84);
            else I386Byte(out,0x85);
            label=OptLabelFwd(ic->ic_data);
            I386Dword(out,label->addr-out->count-4);
            depth--;
            break;
          case IC__PP:
          case IC__MM:
          case IC_PP_:
          case IC_MM_:
            if (depth<1) throw('Compiler');
            I386Bytes(out,"\x58\x5A\x89\xC1",4);
            I386Load(out,c);
            I386Bytes(out,"\x89\xC6\x89\xD7",4);
            if (I386IsF64(c)) {
              I386Bytes(out,"\x51\x31\xC9\xBB",4);
              I386Dword(out,0x3FF00000); //Right operand is binary64 1.0.
              if (ic->ic_code==IC__PP || ic->ic_code==IC_PP_)
                I386F64Runtime(backend,out,IC_ADD,pass);
              else I386F64Runtime(backend,out,IC_SUB,pass);
              I386Byte(out,0x59);
            } else if (ic->ic_code==IC__PP || ic->ic_code==IC_PP_) {
              I386Byte(out,0x05);
              if (c->ptr_stars_cnt) I386Dword(out,I386Size(c-1));
              else I386Dword(out,1);
              I386Bytes(out,"\x83\xD2\x00",3);
            } else {
              I386Byte(out,0x2D);
              if (c->ptr_stars_cnt) I386Dword(out,I386Size(c-1));
              else I386Dword(out,1);
              I386Bytes(out,"\x83\xDA\x00",3);
            }
            I386Store(out,c);
            if (ic->ic_code==IC__PP || ic->ic_code==IC__MM)
              I386Bytes(out,"\x89\xF0\x89\xFA",4);
            I386Bytes(out,"\x52\x50",2);
            break;
          case IC_ADD_EQU:
          case IC_SUB_EQU:
          case IC_MUL_EQU:
          case IC_AND_EQU:
          case IC_OR_EQU:
          case IC_XOR_EQU:
            if (depth<2) throw('Compiler');
            I386Bytes(out,"\x59\x5B\x58\x5A\x50",5);
            I386Load(out,c);
            switch (ic->ic_code) {
              case IC_ADD_EQU:
                if (I386IsF64(c) || I386IsF64(I386ValueClass(backend,ic->t.arg2_tree)))
                  I386F64Update(backend,out,IC_ADD,pass,!I386IsF64(c));
                else I386Binary(out,IC_ADD);
                break;
              case IC_SUB_EQU:
                if (I386IsF64(c) || I386IsF64(I386ValueClass(backend,ic->t.arg2_tree)))
                  I386F64Update(backend,out,IC_SUB,pass,!I386IsF64(c));
                else I386Binary(out,IC_SUB);
                break;
              case IC_MUL_EQU:
                if (I386IsF64(c) || I386IsF64(I386ValueClass(backend,ic->t.arg2_tree)))
                  I386F64Update(backend,out,IC_MUL,pass,!I386IsF64(c));
                else I386Binary(out,IC_MUL);
                break;
              case IC_AND_EQU: I386Binary(out,IC_AND); break;
              case IC_OR_EQU: I386Binary(out,IC_OR); break;
              case IC_XOR_EQU: I386Binary(out,IC_XOR); break;
            }
            I386Byte(out,0x59);
            I386Store(out,c);
            I386Bytes(out,"\x52\x50",2);
            depth--;
            break;
          case IC_SHL:
          case IC_SHR:
            if (depth<2) throw('Compiler');
            I386Bytes(out,"\x59\x5B\x58\x5A",4);
            I386Shift(out,ic->ic_code==IC_SHL,
              ToBool(I386ValueClass(backend,ic->t.arg1_tree)->raw_type&RTF_UNSIGNED));
            I386Bytes(out,"\x52\x50",2);
            depth--;
            break;
          case IC_SHL_CONST:
          case IC_SHR_CONST:
            if (depth<1) throw('Compiler');
            I386Bytes(out,"\x58\x5A\xB9",3);
            I386Dword(out,ic->ic_data);
            I386Shift(out,ic->ic_code==IC_SHL_CONST,
              ToBool(I386ValueClass(backend,ic->t.arg1_tree)->raw_type&RTF_UNSIGNED));
            I386Bytes(out,"\x52\x50",2);
            break;
          case IC_SHL_EQU:
          case IC_SHR_EQU:
            if (depth<2) throw('Compiler');
            I386Bytes(out,"\x59\x5B\x58\x5A\x50",5);
            I386Load(out,c);
            I386Shift(out,ic->ic_code==IC_SHL_EQU,
              ToBool(c->raw_type&RTF_UNSIGNED));
            I386Byte(out,0x59);
            I386Store(out,c);
            I386Bytes(out,"\x52\x50",2);
            depth--;
            break;
          case IC_DIV:
          case IC_MOD:
          case IC_DIV_EQU:
          case IC_MOD_EQU:
            if (depth<2) throw('Compiler');
            I386Bytes(out,"\x59\x5B\x58\x5A",4);
            if (ic->ic_code==IC_DIV_EQU || ic->ic_code==IC_MOD_EQU) {
              I386Byte(out,0x50);
              I386Load(out,c);
            } else c=I386ValueClass(backend,ic->t.arg1_tree);
            if (I386IsF64(c) || ((ic->ic_code==IC_DIV_EQU || ic->ic_code==IC_MOD_EQU) &&
                I386IsF64(I386ValueClass(backend,ic->t.arg2_tree)))) {
              if (ic->ic_code==IC_MOD || ic->ic_code==IC_MOD_EQU)
                I386F64Update(backend,out,IC_MOD,pass,!I386IsF64(c));
              else I386F64Update(backend,out,IC_DIV,pass,!I386IsF64(c));
              if (ic->ic_code==IC_DIV_EQU || ic->ic_code==IC_MOD_EQU) {
                I386Byte(out,0x59);
                I386Store(out,c);
              }
              I386Bytes(out,"\x52\x50",2);
              depth--;
              break;
            }
            I386Byte(out,0xBE);
            I386Dword(out,!ToBool((c->raw_type|ic->t.arg2_class->raw_type)&RTF_UNSIGNED) |
              2*ToBool(ic->ic_code==IC_MOD || ic->ic_code==IC_MOD_EQU));
            I386Bytes(out,&I386DivBegin,(&I386DivEnd)(U8 *)-(&I386DivBegin)(U8 *));
            if (ic->ic_code==IC_DIV_EQU || ic->ic_code==IC_MOD_EQU) {
              I386Byte(out,0x59);
              I386Store(out,c);
            }
            I386Bytes(out,"\x52\x50",2);
            depth--;
            break;
          case IC_ASSIGN:
            if (depth<2) throw('Compiler');
            I386Bytes(out,"\x58\x5A\x59\x5B",4);
            I386Store(out,c);
            I386Bytes(out,"\x52\x50",2);
            depth--;
            break;
          case IC_ADD:
          case IC_SUB:
          case IC_MUL:
          case IC_AND:
          case IC_OR:
          case IC_XOR:
            if (depth<2) throw('Compiler');
            I386Bytes(out,"\x59\x5B\x58\x5A",4);
            if (I386IsF64(c) && (ic->ic_code==IC_ADD || ic->ic_code==IC_SUB || ic->ic_code==IC_MUL))
              I386F64Runtime(backend,out,ic->ic_code,pass);
            else I386Binary(out,ic->ic_code);
            if (c && c->ptr_stars_cnt) I386Normalize(out,c);
            I386Bytes(out,"\x52\x50",2);
            depth--;
            break;
          case IC_END_EXP:
            if (depth!=1) throw('Compiler');
            if(ic->ic_flags&ICF_RES_NOT_USED) I386Bytes(out,"\x83\xC4\x08",3);
            else I386Bytes(out,"\x58\x5A",2);
            depth--;
            break;
          case IC_RETURN_VAL2:
            //LexStmt2Bin preserves the previous result; this opcode has no operand.
            if(depth) throw('Compiler');
            break;
          case IC_RETURN_VAL:
            if (depth!=1) throw('Compiler');
            I386Bytes(out,"\x58\x5A",2);
            if (I386IsF64(c)!=I386IsF64(I386ValueClass(backend,ic->t.arg1_tree))) {
              if (I386IsF64(c)) I386F64Runtime(backend,out,IC_TO_F64,pass);
              else I386F64Runtime(backend,out,IC_TO_I64,pass);
            }
            I386Normalize(out,c);
            depth--;
            break;
          case IC_SWITCH:
          case IC_NOBOUND_SWITCH:
            if (depth!=2) throw('Compiler');
            switch_table=ic->ic_data;
            if (!switch_table || switch_table->type!=CMT_JMP_TABLE ||
                switch_table->range<1 || switch_table->range>0xFFFF ||
                !switch_table->jmp_table || !switch_table->dft) throw('Compiler');
            I386Bytes(out,"\x59\x5B\x58\x5A",4);
            if (ic->ic_code==IC_SWITCH) {
              label=OptLabelFwd(switch_table->dft);
              I386Bytes(out,"\x85\xD2\x0F\x85",4);
              I386Dword(out,label->addr-out->count-4);
              I386Byte(out,0x3D); I386Dword(out,switch_table->range);
              I386Bytes(out,"\x0F\x83",2);
              I386Dword(out,label->addr-out->count-4);
            }
            //Entries are signed offsets from the table's position-independent base.
            I386Bytes(out,"\xE8\x00\x00\x00\x00",5); switch_base=out->count;
            I386Bytes(out,"\x59\x81\xC1",3);
            I386Dword(out,switch_table->addr-switch_base);
            I386Bytes(out,"\x8B\x04\x81\x01\xC8\xFF\xE0",7);
            depth-=2;
            break;
          case IC_SUB_CALL:
            if (depth) throw('Compiler');
            label=OptLabelFwd(ic->ic_data);
            I386Byte(out,0xE8);
            I386Dword(out,label->addr-out->count-4);
            break;
          case IC_ASM:
            if(depth || backend->calls) throw('Compiler');
            (*backend->assembly)(backend->context,cc,out,ic->ic_data,pass);
            break;
          case IC_LABEL:
            label=ic->ic_data;
            if (!pass) {
              label->addr=out->count;
              if(label->type==CMT_ASM_LABEL) label->addr+=label->rip;
            }
            break;
          case IC_JMP:
            if (depth) throw('Compiler');
            label=OptLabelFwd(ic->ic_data);
            I386Byte(out,0xE9);
            I386Dword(out,label->addr-out->count-4);
            break;
          case IC_LEAVE:
            if (depth) throw('Compiler');
            //A return inside a switch start block discards local sub-call returns.
            I386Bytes(out,"\x8D\xA5",2); I386Dword(out,-stack_size-12);
            I386Bytes(out,"\x5F\x5E\x5B\x89\xEC\x5D\xC2",7);
            I386Byte(out,args&255); I386Byte(out,args>>8);
            break;
          case IC_RET:
            I386Byte(out,0xC3);
            break;
          default:
            (*backend->report)(backend->context,5,ic,0);
            throw('Compiler');
        }
        if (ic->ic_flags&(ICF_RES_TO_F64|ICF_RES_TO_INT)) {
          if (depth<1 || !intermediate_code_table[ic->ic_code].res_cnt) throw('Compiler');
          I386Bytes(out,"\x58\x5A",2);
          if (ic->ic_flags&ICF_RES_TO_F64) I386F64Runtime(backend,out,IC_TO_F64,pass);
          else I386F64Runtime(backend,out,IC_TO_I64,pass);
          I386Bytes(out,"\x52\x50",2);
        }
        for (logic=backend->logics;logic;logic=logic->next) {
          if (logic->left==ic) {
            if (depth<1) throw('Compiler');
            I386Bool(out);
            I386Bytes(out,"\x85\xC0\x0F",3);
            if (logic->end->ic_code==IC_AND_AND) I386Byte(out,0x84);
            else I386Byte(out,0x85);
            I386Dword(out,logic->address-out->count-4);
            I386Bytes(out,"\x83\xC4\x08",3);
            depth--;
          }
        }
      }
      if (backend->calls) throw('Compiler');
      //Keep literal bytes after the function's return, separate from executable ranges.
      pool_start=out->count;
      for (ic=cc->coc.coc_head.next;ic!=&cc->coc.coc_head;ic=ic->next)
        if (ic->ic_code==IC_STR_CONST) {
          label=ic->ic_data;
          if (!pass) label->addr=out->count;
          I386Bytes(out,label->str,label->st_len);
        }
      for (ic=cc->coc.coc_head.next;ic!=&cc->coc.coc_head;ic=ic->next)
        if (ic->ic_code==IC_SWITCH || ic->ic_code==IC_NOBOUND_SWITCH) {
          switch_table=ic->ic_data;
          while (out->count&3) I386Byte(out,0);
          if (!pass) switch_table->addr=out->count;
          for (switch_index=0;switch_index<switch_table->range;switch_index++) {
            label=OptLabelFwd(switch_table->jmp_table[switch_index]);
            I386Dword(out,label->addr-switch_table->addr);
          }
        }
      if (pass && out->count>pool_start) {
        import_rec=(*backend->allocate)(backend->context,sizeof(CAOTImportExport));
        import_rec->type=IET_I386_DATA;
        import_rec->rip=cc->aotc->rip+pool_start;
        import_rec->flags=out->count-pool_start;
        import_rec->next=&cc->aot->next_ie; import_rec->last=cc->aot->last_ie;
        import_rec->last->next=import_rec; cc->aot->last_ie=import_rec;
      }
    }
  }
}
