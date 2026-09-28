//Full shared statement/function/initializer grammar with one private native owner.
#include "/Compiler/PrsInitializerCore.HC"
#include "/Compiler/PrsGlobalCore.HC"
#include "/Compiler/PrsFunctionCore.HC"
#include "/Compiler/PrsStatementCore.HC"
U0 I386FrontendCopy(U8 *context,U8 *destination,U8 *source,I64 bytes)
{
  I64 i;
  if(bytes<0) I386FrontendUnavailable(context);
  for(i=0;i<bytes;i++) destination[i]=source[i];
}
U0 I386FrontendSet(U8 *context,U8 *destination,U8 value,I64 bytes)
{
  I64 i;
  if(bytes<0) I386FrontendUnavailable(context);
  for(i=0;i<bytes;i++) destination[i]=value;
}
U0 I386FrontendStack(U8 *context,CCmpCtrl *cc)
{
  CI386Frontend *state=context;
  if(cc!=state->cc || !I386CmpCodeOwner(state->heap,cc) || !I386ParserStackCheck(cc))
    I386FrontendUnavailable(state);
}
Bool I386FrontendStatementCall(U8 *context,CCmpCtrl *cc,I64 count,CCodeMisc *label,I64 flags)
{
  CI386Frontend *state=context;
  return PrsStmtCore(&state->statements,cc,count,label,flags);
}
U8 *I386FrontendFunctionCode(U8 *context,CCmpCtrl *cc,I64 *bytes,CDbgInfo **debug,I64 *raw_type)
{
  CI386Frontend *state=context;
  CI386FrontendCode *result;
  CHashClass *type;
  CCodeMisc *label;
  if(cc->flags&CCF_MODULE_SOURCE) KernelLog("MODULE FUNCTION BODY DONE\n");
  I386FrontendStack(state,cc);
  if(!cc->htc.fun || !(type=OptClassFwd(cc->htc.fun->return_class))) I386FrontendUnavailable(state);
  for(label=cc->coc.coc_next_misc;label!=&cc->coc.coc_next_misc;label=label->next)
    if(label->type==CMT_GOTO_LABEL && !(label->flags&CMF_DEFINED)) I386FrontendUnavailable(state);
  result=I386FrontendOutput(state,cc,type,cc->flags&CCF_HAS_MISC_DATA);
  if(cc->flags&CCF_MODULE_SOURCE) KernelLog("MODULE FUNCTION OUTPUT DONE\n");
  if(bytes) *bytes=result->bytes;
  if(debug) *debug=0;
  if(raw_type) *raw_type=result->raw_type;
  return result->code;
}
U0 I386FrontendFunction(U8 *context,CCmpCtrl *cc,CHashClass *type,U8 *name,I64 flags)
{
  CI386Frontend *state=context;
  if(cc->flags&CCF_MODULE_SOURCE) {
    KernelLog("MODULE FUNCTION START "); if(name) KernelLog(name); KernelLog("\n");
  }
  I386FrontendStack(state,cc);
  if(cc->flags&CCF_AOT_COMPILE || cc->htc.fun) I386FrontendUnavailable(state);
  PrsFunCore(&state->functions,cc,type,name,flags);
  if(cc->flags&CCF_MODULE_SOURCE) KernelLog("MODULE FUNCTION DONE\n");
}
U0 I386FrontendResolve(U8 *context,CCmpCtrl *cc,U8 *name)
{
  CI386Frontend *state=context;
  CHash *symbol=I386FrontendSingleFind(state,name,state->table,HTT_FUN|HTT_GLBL_VAR);
  CI386FrontendFixup **link=&state->fixups,*fixup;
  CHashFun *fun;
  CMemberLst *member;
  CI386FrontendCode *code;
  I64 i;
  if(!symbol || cc->htc.glbl_hash_table!=state->table) I386FrontendUnavailable(state);
  if(!(symbol->type&HTT_FUN)) {
    if(symbol(CHashGlblVar *)->flags&GVF_ALIAS)
      I386FrontendResidentBind(state,symbol,(symbol(CHashGlblVar *)->data_addr+0)(U64));
    return;
  }
  fun=symbol;
  if(fun->ie_lst || fun->ext_lst || !fun->exe_addr || fun->type&HTF_IMPORT) I386FrontendUnavailable(state);
  for(code=state->codes;code && code->code!=fun->exe_addr;code=code->next);
  if(!code) I386FrontendResidentBind(state,fun,(fun->exe_addr+0)(U64));
  //The shared function parser calls resolve before clearing Cf_EXTERN.
  while(fixup=*link) {
    if(fixup->function==fun) {
      if(fixup->argument_count!=fun->arg_cnt || I386FrontendClassView(state,fixup->result_type)!=I386FrontendClassView(state,fun->return_class) ||
          fixup->flags!=(fun->flags&(FSG_FUN_FLAGS1|1<<Ff_DOT_DOT_DOT))) I386FrontendUnavailable(state);
      member=fun->member_lst_and_root;
      for(i=0;i<fun->arg_cnt;i++) {
        if(!member || I386FrontendClassView(state,member->member_class)!=I386FrontendClassView(state,fixup->arguments[i])) I386FrontendUnavailable(state);
        member=member->next;
      }
      for(code=state->codes;code && code->code!=fixup->code;code=code->next);
      if(!code || fixup->offset<0 || fixup->offset>code->bytes-4) I386FrontendUnavailable(state);
      (code->code+fixup->offset)(U32 *)[0]=(fun->exe_addr+0)(U64)-(code->code+fixup->offset+4)(U64);
      *link=fixup->next; I386FrontendFree(state,fixup);
    } else link=&fixup->next;
  }
}
Bool I386FrontendSameHeap(U8 *context,U8 *left,U8 *right)
{
  CI386Frontend *state=context;
  return I386ParserRecord(state->cc,left) && I386ParserRecord(state->cc,right);
}
U0 I386FrontendAliasWarning(U8 *context,CCmpCtrl *cc,CHashSrcSym *symbol)
{ cc->warning_cnt++; }
U0 I386FrontendMemberWarning(U8 *context,CCmpCtrl *cc,CMemberLst *member,Bool unneeded)
{ cc->warning_cnt++; }
U0 I386FrontendDisassemble(U8 *context,U8 *code,I64 bytes)
{ I386FrontendUnavailable(context); }
U8 *I386FrontendInitializerCode(U8 *context,CCmpCtrl *cc,I64 *bytes)
{ I386FrontendUnavailable(context); return 0; }
U0 I386FrontendStoreByte(U8 *context,CCmpCtrl *cc,U8 value)
{ I386FrontendUnavailable(context); }
CCodeCtrl *I386FrontendPopSaved(U8 *context,CCmpCtrl *cc)
{
  CI386Frontend *state=context;
  CCodeCtrl *saved=I386COCPopNoFree(state->heap,cc);
  if(!saved) I386FrontendUnavailable(state);
  return saved;
}
extern U0 I386FrontendAssembly(U8 *context,CCmpCtrl *cc,I64 flags);
class CI386AsmOperand {
  I64 kind,size,register_code,base,disp,value;
};
class CI386AsmLabel {
  I64 offset;
  U8 name[32];
};
class CI386AsmFix {
  I64 offset;
  U8 name[32];
};
U0 I386FrontendAsmName(CI386Frontend *state,U8 *dst,U8 *src)
{
  I64 i,length;
  if(!src || src[0]!='@' || src[1]!='@' ||
      (length=StrLen(src))<3 || length>=32) I386FrontendUnavailable(state);
  for(i=0;i<=length;i++) dst[i]=src[i];
}
I64 I386FrontendAsmReg(U8 *name)
{
  if(!StrCmp(name,"EAX")) return 0;
  if(!StrCmp(name,"ECX")) return 1;
  if(!StrCmp(name,"EDX")) return 2;
  if(!StrCmp(name,"EBX")) return 3;
  if(!StrCmp(name,"ESP")) return 4;
  if(!StrCmp(name,"EBP")) return 5;
  if(!StrCmp(name,"ESI")) return 6;
  if(!StrCmp(name,"EDI")) return 7;
  return -1;
}
U0 I386FrontendAsmByte(CI386Frontend *state,U8 *bytes,I64 *count,I64 value)
{
  if(*count>=256) I386FrontendUnavailable(state);
  bytes[*count]=value; (*count)++;
}
U0 I386FrontendAsmDword(CI386Frontend *state,U8 *bytes,I64 *count,I64 value)
{
  I64 i;
  for(i=0;i<4;i++) I386FrontendAsmByte(state,bytes,count,value>>(i*8));
}
U0 I386FrontendAsmOperand(CI386Frontend *state,CCmpCtrl *cc,CI386AsmOperand *arg)
{//Keep register, immediate and EBP/class-member addressing explicit.
  CMemberLst *member;
  CHashClass *cls;
  I64 register_code,offset;
  U8 *name;
  arg->kind=arg->size=arg->register_code=arg->base=arg->disp=arg->value=0;
  if(cc->token==TK_I64) {
    arg->kind=3; arg->value=cc->cur_i64; I386FrontendLex(state,cc); return;
  }
  if(cc->token!=TK_IDENT || !cc->cur_str) I386FrontendUnavailable(state);
  register_code=I386FrontendAsmReg(cc->cur_str);
  if(register_code>=0) {
    arg->kind=1; arg->size=4; arg->register_code=register_code;
    I386FrontendLex(state,cc); return;
  }
  if(!StrCmp(cc->cur_str,"U32")) arg->size=4;
  else if(!StrCmp(cc->cur_str,"U8")) arg->size=1;
  else I386FrontendUnavailable(state);
  I386FrontendLex(state,cc);
  if(cc->token=='[') offset=0;
  else if(cc->token==TK_I64 || cc->token=='+' || cc->token=='-') {
    register_code=1;
    if(cc->token=='-' || cc->token=='+') {
      if(cc->token=='-') register_code=-1;
      if(I386FrontendLex(state,cc)!=TK_I64) I386FrontendUnavailable(state);
    }
    offset=register_code*cc->cur_i64;
    I386FrontendLex(state,cc);
  }
  else if(cc->token=='&') {
    if(I386FrontendLex(state,cc)!=TK_IDENT || !cc->cur_str)
      I386FrontendUnavailable(state);
    name=cc->cur_str; member=cc->htc.fun->member_lst_and_root;
    while(member && StrCmp(member->str,name)) member=member->next;
    if(!member) I386FrontendUnavailable(state);
    offset=member->offset;
    I386FrontendLex(state,cc);
  } else {
    if(cc->token!=TK_IDENT || !cc->cur_str) I386FrontendUnavailable(state);
    cls=HashFind(cc->cur_str,cc->htc.hash_table_lst,HTT_CLASS);
    if(!cls) I386FrontendUnavailable(state);
    cls=OptClassFwd(cls);
    if(I386FrontendLex(state,cc)!='.' ||
        I386FrontendLex(state,cc)!=TK_IDENT || !cc->cur_str)
      I386FrontendUnavailable(state);
    member=cls->member_lst_and_root;
    while(member && StrCmp(member->str,cc->cur_str)) member=member->next;
    if(!member) I386FrontendUnavailable(state);
    offset=member->offset;
    I386FrontendLex(state,cc);
  }
  if(cc->token!='[' || I386FrontendLex(state,cc)!=TK_IDENT ||
      !cc->cur_str || (register_code=I386FrontendAsmReg(cc->cur_str))<0 ||
      I386FrontendLex(state,cc)!=']') I386FrontendUnavailable(state);
  I386FrontendLex(state,cc);
  arg->kind=2; arg->base=register_code; arg->disp=offset;
}
U0 I386FrontendAsmModRM(CI386Frontend *state,U8 *bytes,I64 *count,
  I64 register_code,CI386AsmOperand *arg)
{
  I64 mode,disp=arg->disp,i;
  if(register_code<0 || register_code>7) I386FrontendUnavailable(state);
  if(arg->kind==1) {
    I386FrontendAsmByte(state,bytes,count,0xC0|register_code<<3|arg->register_code);
  } else if(arg->kind==2) {
    if(!disp && arg->base!=5) mode=0;
    else if(disp>=-128 && disp<=127) mode=1;
    else mode=2;
    I386FrontendAsmByte(state,bytes,count,mode<<6|register_code<<3|arg->base);
    if(arg->base==4) I386FrontendAsmByte(state,bytes,count,0x24);
    if(mode==1) I386FrontendAsmByte(state,bytes,count,disp);
    if(mode==2) for(i=0;i<4;i++) I386FrontendAsmByte(state,bytes,count,disp>>(i*8));
  } else I386FrontendUnavailable(state);
}
#include "/Compiler/I386/TopAssembly.HC"
CAOT *I386FrontendJoin(U8 *context,CCmpCtrl *cc,I64 flags)
{//Native 386 inline assembly; only recognized encodings are published.
  CI386Frontend *state=context;
  CAOT *aot;
  CI386AsmOperand dst,src;
  CI386AsmLabel *labels;
  CI386AsmFix *fixes;
  U8 bytes[256],opcode;
  I64 count=0,op,label_count=0,fix_count=0,i,j,delta;
  if(flags!=CMPF_ASM_BLK || !cc->htc.fun || cc->token!=TK_IDENT ||
      !cc->hash_entry || !(cc->hash_entry->type&HTT_KEYWORD) ||
      cc->hash_entry(CHashGeneric *)->user_data0!=KW_ASM) I386FrontendUnavailable(state);
  labels=I386FrontendAlloc(state,32*sizeof(CI386AsmLabel),TRUE,FALSE);
  fixes=I386FrontendAlloc(state,64*sizeof(CI386AsmFix),TRUE,FALSE);
  if(I386FrontendLex(state,cc)!='{') I386FrontendUnavailable(state);
  I386FrontendLex(state,cc);
  while(cc->token!='}') {
    if(cc->token==';') I386FrontendLex(state,cc);
    else {
      if(cc->token!=TK_IDENT || !cc->cur_str || count>=sizeof(bytes))
        I386FrontendUnavailable(state);
      if(cc->cur_str[0]=='@' && cc->cur_str[1]=='@') {
        if(label_count>=32) I386FrontendUnavailable(state);
        I386FrontendAsmName(state,labels[label_count].name,cc->cur_str);
        for(i=0;i<label_count;i++)
          if(!StrCmp(labels[i].name,labels[label_count].name)) I386FrontendUnavailable(state);
        labels[label_count].offset=count; label_count++;
        if(I386FrontendLex(state,cc)!=':') I386FrontendUnavailable(state);
        I386FrontendLex(state,cc);
        opcode=0xFF;
      } else if(!StrCmp(cc->cur_str,"CLI")) opcode=0xFA;
      else if(!StrCmp(cc->cur_str,"STI")) opcode=0xFB;
      else if(!StrCmp(cc->cur_str,"HLT")) opcode=0xF4;
      else if(!StrCmp(cc->cur_str,"CLD")) opcode=0xFC;
      else if(!StrCmp(cc->cur_str,"STD")) opcode=0xFD;
      else if(!StrCmp(cc->cur_str,"NOP")) opcode=0x90;
      else if(!StrCmp(cc->cur_str,"CLC")) opcode=0xF8;
      else if(!StrCmp(cc->cur_str,"STC")) opcode=0xF9;
      else if(!StrCmp(cc->cur_str,"MOV")) opcode=0;
      else if(!StrCmp(cc->cur_str,"XOR")) opcode=1;
      else if(!StrCmp(cc->cur_str,"CMP")) opcode=2;
      else if(!StrCmp(cc->cur_str,"TEST")) opcode=3;
      else if(!StrCmp(cc->cur_str,"ADD")) opcode=4;
      else if(!StrCmp(cc->cur_str,"SUB")) opcode=5;
      else if(!StrCmp(cc->cur_str,"LEA")) opcode=6;
      else if(!StrCmp(cc->cur_str,"LGDT")) opcode=7;
      else if(!StrCmp(cc->cur_str,"SGDT")) opcode=8;
      else if(!StrCmp(cc->cur_str,"LIDT")) opcode=9;
      else if(!StrCmp(cc->cur_str,"SIDT")) opcode=10;
      else if(!StrCmp(cc->cur_str,"JMP")) opcode=0xE9;
      else if(!StrCmp(cc->cur_str,"JB")) opcode=0x82;
      else if(!StrCmp(cc->cur_str,"JNZ") || !StrCmp(cc->cur_str,"JNE")) opcode=0x85;
      else if(!StrCmp(cc->cur_str,"JE")) opcode=0x84;
      else if(!StrCmp(cc->cur_str,"JA")) opcode=0x87;
      else I386FrontendUnavailable(state);
      if(opcode==0xFF) { }
      else if(opcode==0xE9 || opcode==0x82 || opcode==0x85 ||
          opcode==0x84 || opcode==0x87) {
        if(I386FrontendLex(state,cc)!=TK_IDENT || fix_count>=64)
          I386FrontendUnavailable(state);
        I386FrontendAsmName(state,fixes[fix_count].name,cc->cur_str);
        I386FrontendLex(state,cc);
        if(opcode!=0xE9) I386FrontendAsmByte(state,bytes,&count,0x0F);
        I386FrontendAsmByte(state,bytes,&count,opcode);
        fixes[fix_count].offset=count; fix_count++;
        for(i=0;i<4;i++) I386FrontendAsmByte(state,bytes,&count,0);
      } else if(opcode>=7 && opcode<=10) {
        op=opcode;
        I386FrontendLex(state,cc);
        I386FrontendAsmOperand(state,cc,&dst);
        if(dst.kind!=2 || dst.size!=4) I386FrontendUnavailable(state);
        I386FrontendAsmByte(state,bytes,&count,0x0F);
        I386FrontendAsmByte(state,bytes,&count,0x01);
        if(op==7) I386FrontendAsmModRM(state,bytes,&count,2,&dst);
        else if(op==8) I386FrontendAsmModRM(state,bytes,&count,0,&dst);
        else if(op==9) I386FrontendAsmModRM(state,bytes,&count,3,&dst);
        else I386FrontendAsmModRM(state,bytes,&count,1,&dst);
      } else if(opcode<=6) {
        I386FrontendLex(state,cc);
        op=opcode;
        I386FrontendAsmOperand(state,cc,&dst);
        if(cc->token!=',') I386FrontendUnavailable(state);
        I386FrontendLex(state,cc);
        I386FrontendAsmOperand(state,cc,&src);
        if(op==6 && dst.kind==1 && dst.size==4 &&
            src.kind==2 && src.size==4) {
          I386FrontendAsmByte(state,bytes,&count,0x8D);
          I386FrontendAsmModRM(state,bytes,&count,dst.register_code,&src);
        } else if(op==0 && dst.kind==1 && dst.size==4 &&
            (src.kind==1 || src.kind==2 && src.size==4)) {
          I386FrontendAsmByte(state,bytes,&count,0x8B);
          I386FrontendAsmModRM(state,bytes,&count,dst.register_code,&src);
        } else if(op==0 && dst.kind==2 && src.kind==3 &&
            (dst.size==4 || dst.size==1)) {
          if(dst.size==4) I386FrontendAsmByte(state,bytes,&count,0xC7);
          else I386FrontendAsmByte(state,bytes,&count,0xC6);
          I386FrontendAsmModRM(state,bytes,&count,0,&dst);
          if(dst.size==4) I386FrontendAsmDword(state,bytes,&count,src.value);
          else I386FrontendAsmByte(state,bytes,&count,src.value);
        } else if(op==1 && dst.kind==1 && src.kind==1) {
          I386FrontendAsmByte(state,bytes,&count,0x33);
          I386FrontendAsmModRM(state,bytes,&count,dst.register_code,&src);
        } else if(op==2 && src.kind==3 &&
            (dst.kind==1 && dst.size==4 || dst.kind==2 && dst.size==4)) {
          if(src.value>=-128 && src.value<=127)
            I386FrontendAsmByte(state,bytes,&count,0x83);
          else I386FrontendAsmByte(state,bytes,&count,0x81);
          I386FrontendAsmModRM(state,bytes,&count,7,&dst);
          if(src.value>=-128 && src.value<=127)
            I386FrontendAsmByte(state,bytes,&count,src.value);
          else I386FrontendAsmDword(state,bytes,&count,src.value);
        } else if(op==2 && dst.kind==1 && dst.size==4 &&
            (src.kind==1 || src.kind==2 && src.size==4)) {
          I386FrontendAsmByte(state,bytes,&count,0x3B);
          I386FrontendAsmModRM(state,bytes,&count,dst.register_code,&src);
        } else if(op==2 && dst.kind==2 && dst.size==4 &&
            src.kind==1 && src.size==4) {
          I386FrontendAsmByte(state,bytes,&count,0x39);
          I386FrontendAsmModRM(state,bytes,&count,src.register_code,&dst);
        } else if(op==3 && dst.kind==1 && dst.register_code==0 && src.kind==3) {
          I386FrontendAsmByte(state,bytes,&count,0xA9);
          I386FrontendAsmDword(state,bytes,&count,src.value);
        } else if((op==4 || op==5) && dst.kind==1 && dst.size==4 &&
            src.kind==3) {
          if(src.value>=-128 && src.value<=127)
            I386FrontendAsmByte(state,bytes,&count,0x83);
          else I386FrontendAsmByte(state,bytes,&count,0x81);
          if(op==4) I386FrontendAsmModRM(state,bytes,&count,0,&dst);
          else I386FrontendAsmModRM(state,bytes,&count,5,&dst);
          if(src.value>=-128 && src.value<=127)
            I386FrontendAsmByte(state,bytes,&count,src.value);
          else I386FrontendAsmDword(state,bytes,&count,src.value);
        } else if((op==4 || op==5) && dst.kind==1 && dst.size==4 &&
            src.kind==1 && src.size==4) {
          if(op==4) I386FrontendAsmByte(state,bytes,&count,0x03);
          else I386FrontendAsmByte(state,bytes,&count,0x2B);
          I386FrontendAsmModRM(state,bytes,&count,dst.register_code,&src);
        } else I386FrontendUnavailable(state);
      } else {
        I386FrontendAsmByte(state,bytes,&count,opcode);
        I386FrontendLex(state,cc);
      }
    }
  }
  for(i=0;i<fix_count;i++) {
    for(j=0;j<label_count;j++) if(!StrCmp(fixes[i].name,labels[j].name)) break;
    if(j==label_count) I386FrontendUnavailable(state);
    delta=labels[j].offset-fixes[i].offset-4;
    for(j=0;j<4;j++) bytes[fixes[i].offset+j]=delta>>(j*8);
  }
  if(!count) I386FrontendUnavailable(state);
  aot=I386FrontendAlloc(state,sizeof(CAOT),TRUE,FALSE);
  aot->buf=I386FrontendAlloc(state,count,FALSE,FALSE);
  for(opcode=0;opcode<count;opcode++) aot->buf[opcode]=bytes[opcode];
  aot->aot_U8s=count;
  aot->next_ie=aot->last_ie=&aot->next_ie;
  I386FrontendFree(state,labels); I386FrontendFree(state,fixes);
  return aot;
}
U0 I386FrontendFixAssembly(U8 *context,CCmpCtrl *cc,CAOT *aot)
{ I386FrontendUnavailable(context); }
CHashTable *I386FrontendTaskSymbols(U8 *context)
{ CI386Frontend *state=context; return state->table; }
U0 I386FrontendExecuteLine(U8 *context,CCmpCtrl *cc)
{ I386FrontendUnavailable(context); }
U0 I386FrontendInclude(U8 *context,CCmpCtrl *cc,U8 *name,U8 *source,Bool file)
{ I386FrontendUnavailable(context); }
U0 I386FrontendStatementsInit(CI386Frontend *state)
{
  CPrsInitializerServices *i=&state->initializers;
  CPrsGlobalServices *g=&state->globals;
  CPrsFunctionServices *f=&state->functions;
  CPrsStatementServices *s=&state->statements;
  i->context=state; i->declarations=&state->declarations;
  i->copy=&I386FrontendCopy; i->set=&I386FrontendSet;
  i->store_u8=&I386FrontendStoreByte; i->compile_code=&I386FrontendInitializerCode;
  g->context=state; g->symbols=&state->symbols; g->initializers=i;
  g->function=&I386FrontendFunction; g->resolve=&I386FrontendResolve;
  g->same_heap=&I386FrontendSameHeap; g->alias_warning=&I386FrontendAliasWarning;
  f->context=state; f->globals=g; f->statement=&I386FrontendStatementCall;
  f->compile=&I386FrontendFunctionCode; f->disassemble=&I386FrontendDisassemble;
  f->member_warning=&I386FrontendMemberWarning;
  s->context=state; s->globals=g; s->pop_saved=&I386FrontendPopSaved;
  s->assembly=&I386FrontendAssembly; s->join=&I386FrontendJoin; s->fix_assembly=&I386FrontendFixAssembly;
  s->task_symbols=&I386FrontendTaskSymbols; s->execute_line=&I386FrontendExecuteLine;
  s->include=&I386FrontendInclude; s->stack_check=&I386FrontendStack;
}
Bool I386FrontendStatement(CI386Heap *heap,CCmpCtrl *cc,CPrsSymbolServices *symbols,I64 flags)
{
  CI386Frontend *state;
  I64 old_flags;
  if(!I386CmpCodeOwner(heap,cc) || !symbols || !(state=symbols->context) ||
      state->heap!=heap || state->cc!=cc || symbols!=&state->symbols || cc->error_cnt) return FALSE;
  old_flags=cc->flags; cc->flags&=~CCF_AOT_COMPILE;
  PrsStmtCore(&state->statements,cc,0,0,flags);
  cc->flags=cc->flags&~CCF_AOT_COMPILE|old_flags&CCF_AOT_COMPILE;
  return TRUE;
}
U8 *I386FrontendCommand(CI386Heap *heap,CCmpCtrl *cc,CPrsSymbolServices *symbols,I64 *raw_type)
{//Native LexStmt2Bin staging: parse globally, then give generated code a frame.
  CI386Frontend *state;
  CI386FrontendBound *bound;
  CI386FrontendCode *result=0;
  CIntermediateCode *node,*enter;
  CHashClass *type;
  I64 old_flags,old_pass;
  if(!I386CmpCodeOwner(heap,cc) || !symbols || !(state=symbols->context) ||
      state->heap!=heap || state->cc!=cc || symbols!=&state->symbols || cc->error_cnt || cc->htc.fun)
    throw('Compiler',TRUE);
  I386FrontendStack(state,cc);
  if(raw_type) *raw_type=RT_U0;
  old_flags=cc->flags; old_pass=cc->pass;
  I386FrontendPush(state,cc); I386FrontendInit(state,cc);
  cc->flags&=~(CCF_AOT_COMPILE|CCF_HAS_MISC_DATA|(1<<CCf_PASS_TRACE_PRESENT));
  if(PrsStmtCore(&state->statements,cc,0,0,CMPF_PRS_SEMICOLON) &&
      !(cc->flags&CCF_MODULE_SOURCE)) I386FrontendUnavailable(state);
  if(cc->coc.coc_head.next!=&cc->coc.coc_head) {
    cc->coc.coc_head.last->ic_flags&=~ICF_RES_NOT_USED;
    bound=I386FrontendAlloc(state,sizeof(CI386FrontendBound),TRUE,FALSE);
    bound->typer.types=state->expression.types;
    cc->pass=0; I386FrontendOptimize(state,cc); I386FrontendOptimize(state,cc);
    type=state->expression.types[RT_I64];
    for(node=cc->coc.coc_head.last;node!=&cc->coc.coc_head;node=node->last)
      if(node->ic_code>IC_END_EXP && node->ic_code!=IC_NOP2 && node->ic_class) {
        type=I386ValueClass(&bound->typer,node); break;
      }
    //Do not install the dummy function until parsing has finished: declarations
    //inside top-level blocks must retain their ordinary global scope.
    bound->fun.return_class=type; cc->htc.fun=&bound->fun;
    enter=I386FrontendAdd(state,cc,IC_ENTER,0,0,0);
    ICDetach(enter);
    enter->last=&cc->coc.coc_head; enter->next=cc->coc.coc_head.next;
    enter->next->last=enter; cc->coc.coc_head.next=enter;
    I386FrontendAdd(state,cc,IC_RETURN_VAL2,0,type,0);
    I386FrontendAdd(state,cc,IC_LEAVE,0,type,0);
    result=I386FrontendOutput(state,cc,type,0);
    cc->htc.fun=0;
    I386FrontendFree(state,bound);
    if(raw_type) *raw_type=result->raw_type;
  } else if(!I386COCDiscard(heap,cc)) I386FrontendUnavailable(state);
  I386FrontendPop(state,cc);
  cc->flags=cc->flags&~(CCF_AOT_COMPILE|CCF_HAS_MISC_DATA)|old_flags&(CCF_AOT_COMPILE|CCF_HAS_MISC_DATA);
  cc->pass=old_pass;
  if(result) return result->code;
  return 0;
}
