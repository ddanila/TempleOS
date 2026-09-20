//Intrinsic declarations own metadata, not code; execute through fresh controls.
#include "/Compiler/I386/Intrinsic.HC"
_intern 0x17 U8 *ProbeNativeGs();
U0 ProbeIntrinsics(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CI386Task *task=I386TaskSelf;
  CI386TaskSymbols *scope=task->symbol_state;
  CI386TaskStorage *old_storage=scope->storage;
  CCmpCtrl *cc;
  CPrsSymbolServices *symbols;
  CHashSrcSym *roots[40],*entry;
  CHashFun *fun,*sqrt_fun,*input_fun,*bool_fun,*length_fun;
  CHashClass *return_type,*argument_type,*sqrt_type,*input_type,*length_type;
  U8 *source,*code;
  I64 i,kind,count=0,type,commands=0,value,expected,before_used,before_allocations;
  I64 used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  U32 flags=GetRFlags;
  source=
      "_intern 0x15 U8i *ProbeFs();"
      "_intern 0x17 U8i *ProbeGs();"
      "_intern 0x77 Bool Bt( U8i *bit_field,I64i bit);"
      "_intern 0x7A Bool Btc( U8i *bit_field,I64i bit);"
      "_intern 0x79 Bool Btr( U8i *bit_field,I64i bit);"
      "_intern 0x78 Bool Bts( U8i *bit_field,I64i bit);"
      "_intern 0x7D Bool LBtc( U8i *bit_field,I64i bit);"
      "_intern 0x7C Bool LBtr( U8i *bit_field,I64i bit);"
      "_intern 0x7B Bool LBts( U8i *bit_field,I64i bit);"
      "_intern 0x1E I64i ToUpper(U8i ch);"
      "_intern 0x84 I64i StrLen(U8i *st);"
      "_intern 0x67 U16i InU16(I64i port);"
      "_intern 0x68 U32i InU32(I64i port);"
      "_intern 0x66 U8i InU8(I64i port);"
      "_intern 0x6A U0 OutU16(I64i port, I64i val);"
      "_intern 0x6B U0 OutU32(I64i port, I64i val);"
      "_intern 0x69 U0 OutU8(I64i port, I64i val);"
      "_intern 0xB3 F64 Abs(F64 d);"
      "_intern 0xA9 I64i AbsI64(I64i i);"
      "_intern 0xAD I64i MaxI64(I64i n1,I64i n2);"
      "_intern 0xAE U64i MaxU64(U64i n1,U64i n2);"
      "_intern 0xAB I64i MinI64(I64i n1,I64i n2);"
      "_intern 0xAC U64i MinU64(U64i n1,U64i n2);"
      "_intern 0xAF U64i ModU64(U64i *q,U64i d);"
      "_intern 0xAA I64i SignI64(I64i i);"
      "_intern 0xB2 F64 Sqr(F64 d);"
      "_intern 0xB0 I64i SqrI64(I64i i);"
      "_intern 0xB1 U64i SqrU64(U64i i);"
      "_intern 0xB4 F64 Sqrt(F64 d);"
      "_intern 0x1D Bool ToBool(I64i i);"
      "_intern 0x1C F64 ToF64(I64i i);"
      "_intern 0x1B I64i ToI64(F64 d);"
      "_intern 0x71 U8i *GetRBP();"
      "_intern 0x6C I64i GetRFlags();"
      "_intern 0x6E U0 SetRFlags(I64i d);";
  cc=probe->files->control_new(source,CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/Intrinsics.HC");
  if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
  symbols=probe->compiler->frontend(heap,cc,probe->internal_types,probe->disk_include);
  if(!symbols) KernelStop;
  symbols->declarations->expression->lex(symbols->declarations->expression->context,cc);
  while(cc->token!=TK_EOF) {
    if(++commands>40) KernelStop;
    code=probe->compiler->command(heap,cc,symbols,&type);
    if(code) KernelStop;
  }
  for(i=0;i<=cc->htc.glbl_hash_table->mask;i++)
    for(entry=cc->htc.glbl_hash_table->body[i];entry;entry=entry->next) {
      if(count>=40 || !(entry->type&HTT_FUN)) KernelStop;
      roots[count++]=entry;
    }
  if(count!=35) KernelStop;
  for(i=0;i<count;i++) {
    fun=roots[i];
    if(!I386IntrinsicValid(fun)) {
      KernelLog("INTRINSIC INVALID "); KernelLog(fun->str); KernelLog(" ");
      KernelHex(fun->flags); KernelLog(" "); KernelHex(fun->return_class->raw_type);
      KernelLog(" "); KernelHex(fun->arg_cnt); KernelLog("\n"); KernelStop;
    }
  }
  fun=ProbeSymbolFind(0,"ProbeFs",cc->htc.glbl_hash_table,HTT_FUN);
  sqrt_fun=ProbeSymbolFind(0,"Sqrt",cc->htc.glbl_hash_table,HTT_FUN);
  input_fun=ProbeSymbolFind(0,"InU8",cc->htc.glbl_hash_table,HTT_FUN);
  bool_fun=ProbeSymbolFind(0,"ToBool",cc->htc.glbl_hash_table,HTT_FUN);
  length_fun=ProbeSymbolFind(0,"StrLen",cc->htc.glbl_hash_table,HTT_FUN);
  if(!fun || !sqrt_fun || !input_fun || !bool_fun || !length_fun) KernelStop;
  return_type=fun->return_class; sqrt_type=sqrt_fun->return_class;
  input_type=input_fun->return_class; argument_type=bool_fun->member_lst_and_root->member_class;
  length_type=length_fun->member_lst_and_root->member_class;
  for(kind=0;kind<15;kind++) {
    switch(kind) {
      case 0: fun->exe_addr=IC_ADD; break;
      case 1: fun->return_class=probe->i64_type; break;
      case 2: fun->arg_cnt=1; break;
      case 3: fun->flags|=1<<Ff_DOT_DOT_DOT; break;
      case 4: fun->flags|=1<<Ff_NOARGPOP; break;
      case 5: fun->flags|=1<<Cf_EXTERN; break;
      case 6: fun->type|=HTF_IMPORT; break;
      case 7: fun->ie_lst=1; break;
      case 8: fun->exe_addr=0; break;
      case 9: sqrt_fun->return_class=probe->i64_type; break;
      case 10: input_fun->return_class=probe->i64_type; break;
      case 11: bool_fun->member_lst_and_root->member_class=probe->i64_type+1; break;
      case 12: length_fun->member_lst_and_root->member_class=length_type-1; break;
      case 13: length_fun->member_lst_and_root->member_class=length_type+1; break;
      case 14: length_fun->return_class=probe->i64_type+1; break;
    }
    before_used=heap->used; before_allocations=heap->allocations;
    if(probe->compiler->publish(heap,cc,symbols) || heap->used!=before_used ||
        heap->allocations!=before_allocations || scope->storage!=old_storage) KernelStop;
    fun->exe_addr=IC_FS; fun->return_class=return_type; fun->arg_cnt=0;
    fun->flags&=~(1<<Ff_DOT_DOT_DOT|1<<Ff_NOARGPOP|1<<Cf_EXTERN);
    fun->type&=~HTF_IMPORT; fun->ie_lst=0;
    sqrt_fun->return_class=sqrt_type; input_fun->return_class=input_type;
    bool_fun->member_lst_and_root->member_class=argument_type;
    length_fun->member_lst_and_root->member_class=length_type;
    length_fun->return_class=probe->i64_type;
    KernelLog("INTRINSIC REJECT "); KernelHex(probe->phase); KernelLog(" "); KernelHex(kind); KernelLog("\n");
  }
  if(!probe->compiler->publish(heap,cc,symbols) || scope->storage!=old_storage ||
      !probe->compiler->control_unwind(task,outer)) { KernelLog("INTRINSIC PUBLICATION REJECT\n"); KernelStop; }
  for(kind=0;kind<18;kind++) {
    expected=42;
    switch(kind) {
      case 0: source="ProbeFs;"; expected=(task+0)(U64); break;
      case 1: source="ProbeGs;"; expected=(ProbeNativeGs+0)(U64); break;
      case 2: source="GetRBP;"; break;
      case 3: source="GetRFlags&0x200;"; expected=flags&0x200; break;
      case 4: source="SetRFlags(GetRFlags);42;"; break;
      case 5: source="ToI64(ToF64(41)+1.0);"; break;
      case 6: source="ToBool(0)+ToBool(0x100000000)*42;"; break;
      case 7: source="ToI64(Sqrt(Sqr(6.0))+Abs(-36.0));"; break;
      case 8: source="AbsI64(-20)+SignI64(42)+SqrI64(3)+MinI64(12,20);"; break;
      case 9: source="MaxU64(0x8000000000000000,1)-0x8000000000000000+SqrU64(6)+MinU64(6,8);"; break;
      case 10: source="U64i q=85;I64i r=ModU64(&q,2);r+q-1;"; break;
      case 11: source="U64i b=0;Bts(&b,35);I64i seen=Bt(&b,35);I64i old=Btc(&b,35);seen*40+old*2;"; break;
      case 12: source="U64i b=0;LBts(&b,63);LBtc(&b,63);Bts(&b,3);Btr(&b,3);LBts(&b,2);LBtr(&b,2);b+42;"; break;
      case 13: source="ToUpper('a');"; expected='A'; break;
      case 14: source="StrLen(\"\");"; expected=0; break;
      case 15: source="StrLen(\"VGA\")+StrLen(\"adapter\"+2);"; expected=8; break;
      case 16: source="U8i s[4];s[0]=128;s[1]=255;s[2]=0;s[3]=1;StrLen(s);"; expected=2; break;
      case 17: source="U8i s[3];s[0]=65;s[1]=66;s[2]=0;U8i *p=s;StrLen(p++)*10+(p-s);"; expected=21; break;
    }
    KernelLog("INTRINSIC RUN "); KernelHex(kind); KernelLog(" "); KernelLog(source); KernelLog("\n");
    value=ProbeProgramUse(probe,heap,outer,source);
    KernelLog("INTRINSIC VALUE "); KernelHex(value); KernelLog("\n");
    if(kind==2) {
      if(!task->stk || value<((&task->stk->stk_base)(U8 *)+0)(U64) || value>=((&task->stk->stk_base)(U8 *)+0)(U64)+task->stk->stk_size) KernelStop;
    } else if(value!=expected) KernelStop;
  }
  for(i=0;i<count;i++)
    if(!ProbePublishedRemove(task->hash_table,roots[i]) || !I386HashDel(heap,roots[i])) KernelStop;
  if(scope->storage!=old_storage || task->last_cc!=outer || task->active_controls!=1 ||
      task->lifetime_refs!=refs || task->except_top || heap->used!=used || heap->allocations!=allocations ||
      !I386HeapValid(heap) || (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
  KernelLog("INTRINSIC CASE "); KernelHex(probe->phase); KernelLog(" "); KernelHex(count); KernelLog("\n");
}
