// Target backend entered by the normal HolyC function compiler.
#include "/Compiler/I386/Emit.HC"
#include "/Compiler/I386/Divide.HC"

I64 I386Size(CHashClass *c)
{
  if (!c) return 0;
  if (c->ptr_stars_cnt) return 4;
  return c->size;
}
U0 I386Normalize(CI386Out *out,CHashClass *c)
{//Normalize EDX:EAX to the target scalar width.
  if (!c) return;
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
    case RT_U64: break;
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

U8 *I386HostConstant(CCmpCtrl *cc,I64 *_size,I64 *_type)
{//Array bounds/defaults are evaluated by the running x86-64 compiler.
 //Accept only an integer constant after target-aware folding, never target code.
  CIntermediateCode *ic;
  I64 count=0,value=0;
  U8 *res;
  if (cc->flags&CCF_EXE_BLK) throw('Compiler');
  cc->pass=0;
  OptPass012(cc);
  for (ic=cc->coc.coc_head.next;ic!=&cc->coc.coc_head;ic=ic->next) {
    switch (ic->ic_code) {
      case IC_NOP1:
      case IC_NOP2:
      case IC_RETURN_VAL:
      case IC_RETURN_VAL2:
      case IC_RET: break;
      case IC_IMM_I64:
        if (++count!=1 || ic->ic_class->ptr_stars_cnt) throw('Compiler');
        value=ic->ic_data;
        break;
      default:
        PrintErr("i386 host evaluation requires a folded integer constant\n");
        throw('Compiler');
    }
  }
  if (count!=1) throw('Compiler');
  res=MAlloc(11,Fs->code_heap);
  res[0]=0x48; res[1]=0xB8; //Host MOV RAX,imm64; RET.
  MemCpy(res+2,&value,8); res[10]=0xC3;
  if (_size) *_size=11;
  if (_type) *_type=RT_I64;
  COCDel(cc,&cc->coc);
  return res;
}

class CI386Logic
{
  CI386Logic *next;
  CIntermediateCode *left,*end;
  I64 address;
};
U0 I386Bool(CI386Out *out)
{//Normalize the top evaluation slot to zero or one.
  I386Bytes(out,"\x58\x5A\x09\xD0\x0F\x95\xC0\x0F\xB6\xC0"
    "\x31\xD2\x52\x50",14);
}

class CI386Call
{
  CI386Call *next;
  CHashFun *fun;
  I64 depth;
  Bool called;
};

U8 *I386COCCompile(CCmpCtrl *cc,I64 *_size,CDbgInfo **_dbg,I64 *_type)
{
  CI386Out out;
  CIntermediateCode *ic;
  CCodeMisc *label;
  CI386Call *calls=NULL,*call;
  CI386Logic *logics=NULL,*logic;
  CExternUsage *usage;
  CAOTImportExport *import_rec;
  CMemberLst *arg;
  I64 arg_index,arg_offset;
  I64 depth,pass,stack_size=0,args=0;
  U8 *result=NULL;
  CHashClass *c;
  if (_dbg) *_dbg=NULL;
  if (_type) *_type=RT_I64;
  if (_size) *_size=0;
  MemSet(&out,0,sizeof(out));
  if (!(cc->flags&CCF_AOT_COMPILE) || cc->flags&CCF_EXE_BLK)
    throw('Compiler');
  if (cc->flags&CCF_TARGET_HOST_CONST)
    return I386HostConstant(cc,_size,_type);
  if (!cc->htc.fun || cc->coc.coc_head.next->ic_code!=IC_ENTER)
    throw('Compiler');
  if (cc->htc.fun) {
    stack_size=-cc->htc.fun->size;
    args=cc->htc.fun->arg_cnt*8;
    if (Bt(&cc->htc.fun->flags,Ff_DOT_DOT_DOT) || args>65535)
      throw('Compiler');
  }
  cc->pass=0;
  OptPass012(cc);
  try {
    for (ic=cc->coc.coc_head.next;ic!=&cc->coc.coc_head;ic=ic->next)
      if (ic->ic_code==IC_AND_AND || ic->ic_code==IC_OR_OR) {
        logic=CAlloc(sizeof(CI386Logic));
        logic->next=logics; logics=logic;
        logic->left=ic->t.arg1_tree; logic->end=ic;
      }
    // First pass determines label offsets; second resolves near branches.
    for (pass=0;pass<2;pass++) {
      out.count=0;
      depth=0;
      for (ic=cc->coc.coc_head.next;ic!=&cc->coc.coc_head;ic=ic->next) {
        c=ic->ic_class;
        if (c && !c->ptr_stars_cnt && c->raw_type==RT_F64) throw('Compiler');
        if (ic->ic_flags&(ICF_PUSH_CMP|ICF_POP_CMP)) throw('Compiler');
        switch (ic->ic_code) {
          case IC_NOP1:
          case IC_NOP2: break;
          case IC_CALL_START:
            call=CAlloc(sizeof(CI386Call));
            call->next=calls;
            calls=call;
            call->fun=ic->ic_data;
            call->depth=depth;
            if (Bt(&call->fun->flags,Ff_DOT_DOT_DOT) ||
                Bt(&call->fun->flags,Ff_NOARGPOP)) throw('Compiler');
            break;
          case IC_CALL:
          case IC_CALL_EXTERN:
          case IC_CALL_IMPORT:
            if (!calls || calls->called ||
                depth!=calls->depth+calls->fun->arg_cnt) throw('Compiler');
            arg=calls->fun->member_lst_and_root;
            for (arg_index=0;arg_index<calls->fun->arg_cnt;arg_index++) {
              c=arg->member_class;
              if (arg->dim.next) c=cmp.internal_types[RT_U8]+1;
              if (c->raw_type==RT_F64 && !c->ptr_stars_cnt) throw('Compiler');
              if (I386Size(c)<8) {
                arg_offset=arg_index*8;
                I386Bytes(&out,"\x8B\x84\x24",3); I386Dword(&out,arg_offset);
                I386Bytes(&out,"\x8B\x94\x24",3); I386Dword(&out,arg_offset+4);
                I386Normalize(&out,c);
                I386Bytes(&out,"\x89\x84\x24",3); I386Dword(&out,arg_offset);
                I386Bytes(&out,"\x89\x94\x24",3); I386Dword(&out,arg_offset+4);
              }
              arg=arg->next;
            }
            I386Byte(&out,0xE8);
            if (ic->ic_code==IC_CALL) {
              I386Dword(&out,ic->ic_data-(cc->aotc->rip+out.count+4));
            } else if (ic->ic_code==IC_CALL_IMPORT) {
              if (pass) {
                import_rec=CAlloc(sizeof(CAOTImportExport));
                import_rec->type=IET_REL_I32;
                import_rec->rip=cc->aotc->rip+out.count;
                import_rec->next=calls->fun->ie_lst;
                calls->fun->ie_lst=import_rec;
              }
              I386Dword(&out,0);
            } else {
              if (pass) {
                usage=CAlloc(sizeof(CExternUsage));
                usage->next=calls->fun->ext_lst;
                calls->fun->ext_lst=usage;
                usage->rip=cc->aotc->rip+out.count;
              }
              I386Dword(&out,0);
            }
            depth=calls->depth;
            calls->called=TRUE;
            break;
          case IC_ADD_RSP1:
          case IC_ADD_RSP:
            if (!calls || !calls->called ||
                ic->ic_data!=calls->fun->arg_cnt*8) throw('Compiler');
            //Fixed-arity i386 callees have already removed argument slots.
            break;
          case IC_CALL_END:
            if (!calls || !calls->called || calls->fun!=ic->ic_data)
              throw('Compiler');
            if (I386Size(calls->fun->return_class))
              I386Normalize(&out,calls->fun->return_class);
            else I386Bytes(&out,"\x31\xC0\x31\xD2",4);
            I386Bytes(&out,"\x52\x50",2);
            depth++;
            call=calls; calls=call->next; Free(call);
            break;
          case IC_AND_AND:
          case IC_OR_OR:
            if (depth<1) throw('Compiler');
            I386Bool(&out);
            for (logic=logics;logic;logic=logic->next)
              if (logic->end==ic && !pass) logic->address=out.count;
            break;
          case IC_XOR_XOR:
            if (depth<2) throw('Compiler');
            I386Bytes(&out,"\x59\x5B\x58\x5A\x09\xD0\x0F\x95\xC0"
              "\x09\xD9\x0F\x95\xC1\x30\xC8\x0F\xB6\xC0\x31\xD2\x52\x50",23);
            depth--;
            break;
          case IC_ENTER:
            I386Bytes(&out,"\x55\x89\xE5\x81\xEC",5);
            I386Dword(&out,stack_size);
            I386Bytes(&out,"\x53\x56\x57",3);
            break;
          case IC_IMM_I64:
          case IC_TYPE:
            I386Byte(&out,0x68); I386Dword(&out,ic->ic_data.u32[1]);
            I386Byte(&out,0x68); I386Dword(&out,ic->ic_data.u32[0]);
            depth++;
            break;
          case IC_RBP:
            I386Bytes(&out,"\x6A\x00\x55",3);
            depth++;
            break;
          case IC_DEREF:
            if (depth<1) throw('Compiler');
            I386Bytes(&out,"\x58\x5A",2);
            I386Load(&out,c);
            I386Bytes(&out,"\x52\x50",2);
            break;
          case IC_ADDR:
          case IC_HOLYC_TYPECAST:
            if (depth<1) throw('Compiler');
            I386Bytes(&out,"\x58\x5A",2);
            I386Normalize(&out,c);
            I386Bytes(&out,"\x52\x50",2);
            break;
          case IC_UNARY_MINUS:
          case IC_COM:
          case IC_NOT:
            if (depth<1) throw('Compiler');
            I386Bytes(&out,"\x58\x5A",2);
            if (ic->ic_code==IC_UNARY_MINUS)
              I386Bytes(&out,"\xF7\xD8\x83\xD2\x00\xF7\xDA",7);
            else if (ic->ic_code==IC_COM)
              I386Bytes(&out,"\xF7\xD0\xF7\xD2",4);
            else
              I386Bytes(&out,"\x09\xD0\x0F\x94\xC0\x0F\xB6\xC0\x31\xD2",10);
            I386Bytes(&out,"\x52\x50",2);
            break;
          case IC_EQU_EQU...IC_LESS_EQU:
            if (depth<2) throw('Compiler');
            I386Bytes(&out,"\x59\x5B\x58\x5A",4);
            I386Compare(&out,ic->ic_code,ToBool(ic->ic_flags&ICF_USE_UNSIGNED));
            I386Bytes(&out,"\x52\x50",2);
            depth--;
            break;
          case IC_BR_ZERO:
          case IC_BR_NOT_ZERO:
            if (depth!=1) throw('Compiler');
            I386Bytes(&out,"\x58\x5A\x09\xD0\x0F",5);
            if (ic->ic_code==IC_BR_ZERO) I386Byte(&out,0x84);
            else I386Byte(&out,0x85);
            label=OptLabelFwd(ic->ic_data);
            I386Dword(&out,label->addr-out.count-4);
            depth--;
            break;
          case IC__PP:
          case IC__MM:
          case IC_PP_:
          case IC_MM_:
            if (depth<1) throw('Compiler');
            I386Bytes(&out,"\x58\x5A\x89\xC1",4);
            I386Load(&out,c);
            I386Bytes(&out,"\x89\xC6\x89\xD7",4);
            if (ic->ic_code==IC__PP || ic->ic_code==IC_PP_) {
              I386Byte(&out,0x05);
              if (c->ptr_stars_cnt) I386Dword(&out,I386Size(c-1));
              else I386Dword(&out,1);
              I386Bytes(&out,"\x83\xD2\x00",3);
            } else {
              I386Byte(&out,0x2D);
              if (c->ptr_stars_cnt) I386Dword(&out,I386Size(c-1));
              else I386Dword(&out,1);
              I386Bytes(&out,"\x83\xDA\x00",3);
            }
            I386Store(&out,c);
            if (ic->ic_code==IC__PP || ic->ic_code==IC__MM)
              I386Bytes(&out,"\x89\xF0\x89\xFA",4);
            I386Bytes(&out,"\x52\x50",2);
            break;
          case IC_ADD_EQU:
          case IC_SUB_EQU:
          case IC_MUL_EQU:
          case IC_AND_EQU:
          case IC_OR_EQU:
          case IC_XOR_EQU:
            if (depth<2) throw('Compiler');
            I386Bytes(&out,"\x59\x5B\x58\x5A\x50",5);
            c=ic->t.arg1_class-1;
            I386Load(&out,c);
            switch (ic->ic_code) {
              case IC_ADD_EQU: I386Binary(&out,IC_ADD); break;
              case IC_SUB_EQU: I386Binary(&out,IC_SUB); break;
              case IC_MUL_EQU: I386Binary(&out,IC_MUL); break;
              case IC_AND_EQU: I386Binary(&out,IC_AND); break;
              case IC_OR_EQU: I386Binary(&out,IC_OR); break;
              case IC_XOR_EQU: I386Binary(&out,IC_XOR); break;
            }
            I386Byte(&out,0x59);
            I386Store(&out,c);
            I386Bytes(&out,"\x52\x50",2);
            depth--;
            break;
          case IC_SHL:
          case IC_SHR:
            if (depth<2) throw('Compiler');
            I386Bytes(&out,"\x59\x5B\x58\x5A",4);
            I386Shift(&out,ic->ic_code==IC_SHL,
              ToBool(ic->t.arg1_class->raw_type&RTF_UNSIGNED));
            I386Bytes(&out,"\x52\x50",2);
            depth--;
            break;
          case IC_SHL_CONST:
          case IC_SHR_CONST:
            if (depth<1) throw('Compiler');
            I386Bytes(&out,"\x58\x5A\xB9",3);
            I386Dword(&out,ic->ic_data);
            I386Shift(&out,ic->ic_code==IC_SHL_CONST,
              ToBool(ic->t.arg1_class->raw_type&RTF_UNSIGNED));
            I386Bytes(&out,"\x52\x50",2);
            break;
          case IC_SHL_EQU:
          case IC_SHR_EQU:
            if (depth<2) throw('Compiler');
            I386Bytes(&out,"\x59\x5B\x58\x5A\x50",5);
            c=ic->t.arg1_class-1;
            I386Load(&out,c);
            I386Shift(&out,ic->ic_code==IC_SHL_EQU,
              ToBool(c->raw_type&RTF_UNSIGNED));
            I386Byte(&out,0x59);
            I386Store(&out,c);
            I386Bytes(&out,"\x52\x50",2);
            depth--;
            break;
          case IC_DIV:
          case IC_MOD:
          case IC_DIV_EQU:
          case IC_MOD_EQU:
            if (depth<2) throw('Compiler');
            I386Bytes(&out,"\x59\x5B\x58\x5A",4);
            if (ic->ic_code==IC_DIV_EQU || ic->ic_code==IC_MOD_EQU) {
              I386Byte(&out,0x50);
              c=ic->t.arg1_class-1;
              I386Load(&out,c);
            } else c=ic->t.arg1_class;
            I386Byte(&out,0xBE);
            I386Dword(&out,!ToBool((c->raw_type|ic->t.arg2_class->raw_type)&RTF_UNSIGNED) |
              2*ToBool(ic->ic_code==IC_MOD || ic->ic_code==IC_MOD_EQU));
            I386Bytes(&out,i386_div_begin,i386_div_end-i386_div_begin);
            if (ic->ic_code==IC_DIV_EQU || ic->ic_code==IC_MOD_EQU) {
              I386Byte(&out,0x59);
              I386Store(&out,c);
            }
            I386Bytes(&out,"\x52\x50",2);
            depth--;
            break;
          case IC_ASSIGN:
            if (depth<2) throw('Compiler');
            I386Bytes(&out,"\x58\x5A\x59\x5B",4);
            I386Store(&out,ic->t.arg1_class-1);
            I386Bytes(&out,"\x52\x50",2);
            depth--;
            break;
          case IC_ADD:
          case IC_SUB:
          case IC_MUL:
          case IC_AND:
          case IC_OR:
          case IC_XOR:
            if (depth<2) throw('Compiler');
            I386Bytes(&out,"\x59\x5B\x58\x5A",4);
            I386Binary(&out,ic->ic_code);
            if (c && c->ptr_stars_cnt) I386Normalize(&out,c);
            I386Bytes(&out,"\x52\x50",2);
            depth--;
            break;
          case IC_END_EXP:
            if (depth!=1) throw('Compiler');
            I386Bytes(&out,"\x83\xC4\x08",3);
            depth--;
            break;
          case IC_RETURN_VAL:
          case IC_RETURN_VAL2:
            if (depth!=1) throw('Compiler');
            I386Bytes(&out,"\x58\x5A",2);
            I386Normalize(&out,c);
            depth--;
            break;
          case IC_LABEL:
            label=ic->ic_data;
            if (!pass) label->addr=out.count;
            break;
          case IC_JMP:
            if (depth) throw('Compiler');
            label=OptLabelFwd(ic->ic_data);
            I386Byte(&out,0xE9);
            I386Dword(&out,label->addr-out.count-4);
            break;
          case IC_LEAVE:
            if (depth) throw('Compiler');
            I386Bytes(&out,"\x5F\x5E\x5B\x89\xEC\x5D\xC2",7);
            I386Byte(&out,args&255); I386Byte(&out,args>>8);
            break;
          case IC_RET:
            I386Byte(&out,0xC3);
            break;
          default:
            PrintErr("i386 COC opcode %X not implemented\n",ic->ic_code);
            throw('Compiler');
        }
        for (logic=logics;logic;logic=logic->next) {
          if (logic->left==ic) {
            if (depth<1) throw('Compiler');
            I386Bool(&out);
            I386Bytes(&out,"\x85\xC0\x0F",3);
            if (logic->end->ic_code==IC_AND_AND) I386Byte(&out,0x84);
            else I386Byte(&out,0x85);
            I386Dword(&out,logic->address-out.count-4);
            I386Bytes(&out,"\x83\xC4\x08",3);
            depth--;
          }
        }
      }
      if (calls) throw('Compiler');
    }
  } catch {
    LinkedLstDel(calls);
    LinkedLstDel(logics);
    Free(out.data);
    //Leave catch_except false so the original exception propagates.
  }
  LinkedLstDel(logics);
  // CMain appends U64 units; include zero padding without reading past allocation.
  result=CAlloc((out.count+7)&~7);
  MemCpy(result,out.data,out.count);
  if (_size) *_size=out.count;
  Free(out.data);
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
