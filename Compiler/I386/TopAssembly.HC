//Native top-level i386 assembler: first boot-provider slice (SysTry).
U0 I386FrontendTopName(CI386Frontend *state,U8 *dst,U8 *src)
{
  I64 i,length;
  if(!src || !(length=StrLen(src)) || length>=32)
    I386FrontendUnavailable(state);
  for(i=0;i<=length;i++) dst[i]=src[i];
}
U0 I386FrontendAssembly(U8 *context,CCmpCtrl *cc,I64 flags)
{
  CI386Frontend *state=context;
  CI386AsmOperand dst,src;
  CI386AsmLabel labels[16],imports[8];
  CI386AsmFix branches[32],calls[16];
  CI386FrontendCode *output;
  CHashFun *fun;
  U8 bytes[256],name[32],export_name[32];
  I64 count=0,label_count=0,import_count=0,branch_count=0,call_count=0;
  I64 i,j,k,opcode,delta,export_count=0;
  if(flags || !(cc->flags&CCF_MODULE_SOURCE) || cc->htc.fun || cc->token!='{')
    I386FrontendReport(state,cc,0,"Invalid top-level assembly entry");
  I386FrontendLex(state,cc);
  while(cc->token!='}') {
    if(cc->token==';') I386FrontendLex(state,cc);
    else {
      if(cc->token!=TK_IDENT || !cc->cur_str)
        I386FrontendReport(state,cc,0,"Invalid top-level assembly token");
      I386FrontendTopName(state,name,cc->cur_str);
      I386FrontendLex(state,cc);
      if(cc->token==TK_DBL_COLON) {
        if(export_count || count) I386FrontendUnavailable(state);
        I386FrontendTopName(state,export_name,name); export_count++;
        I386FrontendLex(state,cc);
      } else if(cc->token==':' && name[0]=='@' && name[1]=='@') {
        if(label_count>=16) I386FrontendUnavailable(state);
        I386FrontendAsmName(state,labels[label_count].name,name);
        for(i=0;i<label_count;i++)
          if(!StrCmp(labels[i].name,labels[label_count].name))
            I386FrontendUnavailable(state);
        labels[label_count].offset=count; label_count++;
        I386FrontendLex(state,cc);
      } else if(!StrCmp(name,"USE32")) {
        if(export_count || count) I386FrontendUnavailable(state);
      } else if(!StrCmp(name,"IMPORT")) {
        if(export_count || count) I386FrontendUnavailable(state);
        while(TRUE) {
          if(cc->token!=TK_IDENT || import_count>=8) I386FrontendUnavailable(state);
          I386FrontendTopName(state,imports[import_count].name,cc->cur_str);
          import_count++;
          if(I386FrontendLex(state,cc)!=',') break;
          I386FrontendLex(state,cc);
        }
        if(cc->token!=';') I386FrontendUnavailable(state);
        I386FrontendLex(state,cc);
      } else {
        if(!export_count) I386FrontendUnavailable(state);
        if(!StrCmp(name,"PUSHFD")) I386FrontendAsmByte(state,bytes,&count,0x9C);
        else if(!StrCmp(name,"POP")) {
          I386FrontendAsmOperand(state,cc,&dst);
          if(dst.kind!=1 || dst.size!=4) I386FrontendUnavailable(state);
          I386FrontendAsmByte(state,bytes,&count,0x58+dst.register_code);
        } else if(!StrCmp(name,"PUSH")) {
          I386FrontendAsmOperand(state,cc,&dst);
          if(dst.kind==1 && dst.size==4)
            I386FrontendAsmByte(state,bytes,&count,0x50+dst.register_code);
          else if(dst.kind==3) {
            if(dst.value>=-128 && dst.value<=127) {
              I386FrontendAsmByte(state,bytes,&count,0x6A);
              I386FrontendAsmByte(state,bytes,&count,dst.value);
            } else {
              I386FrontendAsmByte(state,bytes,&count,0x68);
              I386FrontendAsmDword(state,bytes,&count,dst.value);
            }
          } else I386FrontendUnavailable(state);
        } else if(!StrCmp(name,"MOV") || !StrCmp(name,"LEA") ||
            !StrCmp(name,"TEST")) {
          opcode=0;
          if(!StrCmp(name,"LEA")) opcode=1;
          if(!StrCmp(name,"TEST")) opcode=2;
          I386FrontendAsmOperand(state,cc,&dst);
          if(cc->token!=',') I386FrontendUnavailable(state);
          I386FrontendLex(state,cc);
          I386FrontendAsmOperand(state,cc,&src);
          if(opcode==0 && dst.kind==1 && dst.size==4 &&
              (src.kind==1 || src.kind==2 && src.size==4)) {
            I386FrontendAsmByte(state,bytes,&count,0x8B);
            I386FrontendAsmModRM(state,bytes,&count,dst.register_code,&src);
          } else if(opcode==0 && dst.kind==2 && dst.size==4 &&
              src.kind==1 && src.size==4) {
            I386FrontendAsmByte(state,bytes,&count,0x89);
            I386FrontendAsmModRM(state,bytes,&count,src.register_code,&dst);
          } else if(opcode==1 && dst.kind==1 && dst.size==4 &&
              src.kind==2 && src.size==4) {
            I386FrontendAsmByte(state,bytes,&count,0x8D);
            I386FrontendAsmModRM(state,bytes,&count,dst.register_code,&src);
          } else if(opcode==2 && dst.kind==1 && src.kind==1 &&
              dst.size==4 && src.size==4) {
            I386FrontendAsmByte(state,bytes,&count,0x85);
            I386FrontendAsmModRM(state,bytes,&count,src.register_code,&dst);
          } else I386FrontendUnavailable(state);
        } else if(!StrCmp(name,"CALL")) {
          if(cc->token!=TK_IDENT || call_count>=16) I386FrontendUnavailable(state);
          for(i=0;i<import_count;i++)
            if(!StrCmp(cc->cur_str,imports[i].name)) break;
          if(i==import_count) I386FrontendUnavailable(state);
          I386FrontendTopName(state,calls[call_count].name,cc->cur_str);
          I386FrontendLex(state,cc);
          I386FrontendAsmByte(state,bytes,&count,0xE8);
          calls[call_count].offset=count; call_count++;
          I386FrontendAsmDword(state,bytes,&count,0);
        } else if(!StrCmp(name,"JMP") || !StrCmp(name,"JNZ")) {
          if(cc->token!=TK_IDENT || branch_count>=32) I386FrontendUnavailable(state);
          I386FrontendAsmName(state,branches[branch_count].name,cc->cur_str);
          I386FrontendLex(state,cc);
          if(!StrCmp(name,"JNZ")) {
            I386FrontendAsmByte(state,bytes,&count,0x0F);
            I386FrontendAsmByte(state,bytes,&count,0x85);
          } else I386FrontendAsmByte(state,bytes,&count,0xE9);
          branches[branch_count].offset=count; branch_count++;
          I386FrontendAsmDword(state,bytes,&count,0);
        } else if(!StrCmp(name,"RET1")) {
          if(cc->token!=TK_I64 || cc->cur_i64<0 || cc->cur_i64>65535)
            I386FrontendUnavailable(state);
          I386FrontendAsmByte(state,bytes,&count,0xC2);
          I386FrontendAsmByte(state,bytes,&count,cc->cur_i64);
          I386FrontendAsmByte(state,bytes,&count,cc->cur_i64>>8);
          I386FrontendLex(state,cc);
        } else I386FrontendReport(state,cc,0,name);
      }
    }
  }
  if(export_count!=1 || !count) I386FrontendUnavailable(state);
  for(i=0;i<branch_count;i++) {
    for(j=0;j<label_count;j++)
      if(!StrCmp(branches[i].name,labels[j].name)) break;
    if(j==label_count) I386FrontendUnavailable(state);
    delta=labels[j].offset-branches[i].offset-4;
    for(k=0;k<4;k++) bytes[branches[i].offset+k]=delta>>(k*8);
  }
  output=I386FrontendAlloc(state,sizeof(CI386FrontendCode),TRUE,FALSE);
  output->code=I386ParserCodeAlloc(state->heap,cc,count);
  if(!output->code) I386FrontendUnavailable(state);
  output->bytes=output->data_start=count;
  for(i=0;i<count;i++) output->code[i]=bytes[i];
  for(i=0;i<call_count;i++) I386FrontendRelocAdd(state,output,calls[i].offset,
    I386_MODULE_REL32,calls[i].name);
  output->next=state->codes; state->codes=output;
  fun=I386FrontendAlloc(state,sizeof(CHashFun),TRUE,FALSE);
  fun->str=I386FrontendDuplicate(state,export_name);
  fun->type=HTT_FUN; fun->exe_addr=output->code;
  fun->return_class=state->expression.types[RT_U0];
  HashAdd(fun,state->table);
}
