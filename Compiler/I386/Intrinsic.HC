//Published native intrinsics carry an IR opcode, never an executable address.
#include "/Compiler/PrsFunctionFlags.HH"
Bool I386IntrinsicType(CHashClass *type,I64 raw,I64 pointers=0)
{
  CHashClass *base;
  if(!type) return FALSE;
  while(type->fwd_class) type=type->fwd_class;
  //RT_PTR shares RT_I64's value; pointer shape is a separate contract.
  if(pointers<0) return type->ptr_stars_cnt!=0;
  if(type->ptr_stars_cnt!=pointers) return FALSE;
  base=type-pointers;
  while(base->fwd_class) base=base->fwd_class;
  return base->raw_type==raw;
}
Bool I386IntrinsicValid(CHashFun *fun)
{
  CMemberLst *arg;
  I64 code,count=1,result=RT_I64,first=RT_I64,second=RT_I64;
  I64 first_pointers=0,result_pointers=0;
  if(!fun || !(fun->type&HTT_FUN) || !Bt(&fun->flags,Ff_INTERNAL) ||
      Bt(&fun->flags,Cf_EXTERN) || fun->flags&(FSG_FUN_FLAGS1|1<<Ff_DOT_DOT_DOT) ||
      fun->type&HTF_IMPORT || fun->ie_lst || fun->ext_lst) return FALSE;
  code=(fun->exe_addr+0)(U64);
  switch(code) {
    case IC_FS: case IC_GS: case IC_GET_RBP: case IC_GET_RSP: count=0; result_pointers=-1; break;
    case IC_GET_RFLAGS: count=0; break;
    case IC_SET_RFLAGS: result=RT_U0; break;
    case IC_IN_U8: result=RT_U8; break;
    case IC_IN_U16: result=RT_U16; break;
    case IC_IN_U32: result=RT_U32; break;
    case IC_OUT_U8: case IC_OUT_U16: case IC_OUT_U32: count=2; result=RT_U0; break;
    case IC_BT: case IC_BTS: case IC_BTR: case IC_BTC:
    case IC_LBTS: case IC_LBTR: case IC_LBTC:
      count=2; result=RT_I8; first=RT_U8; first_pointers=1; break;
    case IC_TOUPPER: first=RT_U8; break;
    case IC_TO_BOOL: result=RT_I8; break;
    case IC_TO_F64: result=RT_F64; break;
    case IC_TO_I64: first=RT_F64; break;
    case IC_ABS_I64: case IC_SIGN_I64: case IC_SQR_I64: break;
    case IC_SQR_U64: result=first=RT_U64; break;
    case IC_MIN_I64: case IC_MAX_I64: count=2; break;
    case IC_MIN_U64: case IC_MAX_U64: count=2; result=first=second=RT_U64; break;
    case IC_MOD_U64: count=2; result=first=second=RT_U64; first_pointers=1; break;
    case IC_SQR: case IC_ABS: case IC_SQRT: result=first=RT_F64; break;
    default: return FALSE;
  }
  if(fun->arg_cnt!=count || !I386IntrinsicType(fun->return_class,result,result_pointers)) return FALSE;
  arg=fun->member_lst_and_root;
  if(count) {
    if(!arg || arg->dim.next || !I386IntrinsicType(arg->member_class,first,first_pointers)) return FALSE;
    arg=arg->next;
  }
  if(count==2) {
    if(!arg || arg->dim.next || !I386IntrinsicType(arg->member_class,second)) return FALSE;
    arg=arg->next;
  }
  return arg==0;
}
