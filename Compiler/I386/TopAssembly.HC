//Native top-level i386 assembler for the boot-provider modules.
U0 I386FrontendTopName(CI386Frontend *state,U8 *dst,U8 *src)
{
  I64 i,length;
  if(!src || !(length=StrLen(src)) || length>=32)
    I386FrontendUnavailable(state);
  for(i=0;i<=length;i++) dst[i]=src[i];
}
class CI386FrontendTopBundle {
  I64 bytes,export_count,call_count;
  U8 code[1024];
  CI386AsmLabel exports[32];
  CI386AsmFix calls[16];
};
I64 I386FrontendTopPack(CI386Frontend *state,U8 *output,I64 capacity)
{
  CI386FrontendTopBundle *bundle=state->top_bundle;
  CI386ModuleRecord records[48];
  U8 strings[2048],*name;
  I64 i,j,length,string_bytes=0,record_count;
  if(!bundle || bundle->bytes<1 || bundle->bytes>1024 ||
      bundle->export_count<1 || bundle->export_count>32 ||
      bundle->call_count<0 || bundle->call_count>16) return 0;
  record_count=bundle->export_count+bundle->call_count;
  for(i=0;i<record_count;i++) {
    if(i<bundle->export_count) {
      name=bundle->exports[i].name;
      records[i].kind=I386_MODULE_EXPORT;
      records[i].offset=bundle->exports[i].offset;
    } else {
      name=bundle->calls[i-bundle->export_count].name;
      records[i].kind=I386_MODULE_REL32;
      records[i].offset=bundle->calls[i-bundle->export_count].offset;
    }
    length=StrLen(name);
    if(length<1 || length>31 || string_bytes>2048-length-1) return 0;
    records[i].name_offset=string_bytes; records[i].name_length=length;
    for(j=0;j<=length;j++) strings[string_bytes+j]=name[j];
    string_bytes+=length+1;
  }
  return I386ModulePackRaw(output,capacity,bundle->code,bundle->bytes,
    records,record_count,strings,string_bytes);
}
U0 I386FrontendAssembly(U8 *context,CCmpCtrl *cc,I64 flags)
{
  CI386Frontend *state=context;
  CI386AsmOperand dst,src;
  CI386AsmLabel labels[32],imports[8],exports[32];
  CI386AsmFix branches[64],calls[16];
  CI386FrontendTopBundle *bundle;
  U8 bytes[1024],name[32];
  I64 count=0,label_count=0,import_count=0,branch_count=0,call_count=0;
  I64 i,j,k,delta,opcode,export_count=0;
  if(flags || !(cc->flags&CCF_MODULE_SOURCE) || cc->htc.fun ||
      cc->token!='{' || state->top_bundle)
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
        if(export_count>=32 || !export_count && count) I386FrontendUnavailable(state);
        for(i=0;i<export_count;i++)
          if(!StrCmp(exports[i].name,name)) I386FrontendUnavailable(state);
        I386FrontendTopName(state,exports[export_count].name,name);
        exports[export_count].offset=count; export_count++;
        I386FrontendLex(state,cc);
      } else if(cc->token==':') {
        if(!export_count || label_count>=32) I386FrontendUnavailable(state);
        I386FrontendTopName(state,labels[label_count].name,name);
        for(i=0;i<label_count;i++)
          if(!StrCmp(labels[i].name,labels[label_count].name))
            I386FrontendUnavailable(state);
        for(i=0;i<export_count;i++)
          if(!StrCmp(exports[i].name,name)) I386FrontendUnavailable(state);
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
        else if(!StrCmp(name,"POPFD")) I386FrontendAsmByte(state,bytes,&count,0x9D);
        else if(!StrCmp(name,"PUSHAD")) I386FrontendAsmByte(state,bytes,&count,0x60);
        else if(!StrCmp(name,"POPAD")) I386FrontendAsmByte(state,bytes,&count,0x61);
        else if(!StrCmp(name,"STI")) I386FrontendAsmByte(state,bytes,&count,0xFB);
        else if(!StrCmp(name,"CLI")) I386FrontendAsmByte(state,bytes,&count,0xFA);
        else if(!StrCmp(name,"CLD")) I386FrontendAsmByte(state,bytes,&count,0xFC);
        else if(!StrCmp(name,"HLT")) I386FrontendAsmByte(state,bytes,&count,0xF4);
        else if(!StrCmp(name,"IRET")) I386FrontendAsmByte(state,bytes,&count,0xCF);
        else if(!StrCmp(name,"RET")) I386FrontendAsmByte(state,bytes,&count,0xC3);
        else if(!StrCmp(name,"POP")) {
          if(cc->token==TK_IDENT && cc->cur_str && !StrCmp(cc->cur_str,"DS")) {
            I386FrontendAsmByte(state,bytes,&count,0x1F); I386FrontendLex(state,cc);
          } else if(cc->token==TK_IDENT && cc->cur_str && !StrCmp(cc->cur_str,"ES")) {
            I386FrontendAsmByte(state,bytes,&count,0x07); I386FrontendLex(state,cc);
          } else if(cc->token==TK_IDENT && cc->cur_str && !StrCmp(cc->cur_str,"FS")) {
            I386FrontendAsmByte(state,bytes,&count,0x0F);
            I386FrontendAsmByte(state,bytes,&count,0xA1); I386FrontendLex(state,cc);
          } else if(cc->token==TK_IDENT && cc->cur_str && !StrCmp(cc->cur_str,"GS")) {
            I386FrontendAsmByte(state,bytes,&count,0x0F);
            I386FrontendAsmByte(state,bytes,&count,0xA9); I386FrontendLex(state,cc);
          } else {
            I386FrontendAsmOperand(state,cc,&dst);
            if(dst.kind!=1 || dst.size!=4) I386FrontendUnavailable(state);
            I386FrontendAsmByte(state,bytes,&count,0x58+dst.register_code);
          }
        } else if(!StrCmp(name,"PUSH")) {
          if(cc->token==TK_IDENT && cc->cur_str && !StrCmp(cc->cur_str,"DS")) {
            I386FrontendAsmByte(state,bytes,&count,0x1E); I386FrontendLex(state,cc);
          } else if(cc->token==TK_IDENT && cc->cur_str && !StrCmp(cc->cur_str,"ES")) {
            I386FrontendAsmByte(state,bytes,&count,0x06); I386FrontendLex(state,cc);
          } else if(cc->token==TK_IDENT && cc->cur_str && !StrCmp(cc->cur_str,"FS")) {
            I386FrontendAsmByte(state,bytes,&count,0x0F);
            I386FrontendAsmByte(state,bytes,&count,0xA0); I386FrontendLex(state,cc);
          } else if(cc->token==TK_IDENT && cc->cur_str && !StrCmp(cc->cur_str,"GS")) {
            I386FrontendAsmByte(state,bytes,&count,0x0F);
            I386FrontendAsmByte(state,bytes,&count,0xA8); I386FrontendLex(state,cc);
          } else {
            I386FrontendAsmOperand(state,cc,&dst);
            if(dst.kind==1 && dst.size==4)
              I386FrontendAsmByte(state,bytes,&count,0x50+dst.register_code);
            else if(dst.kind==2 && dst.size==4) {
              I386FrontendAsmByte(state,bytes,&count,0xFF);
              I386FrontendAsmModRM(state,bytes,&count,6,&dst);
            }
            else if(dst.kind==3) {
              if(dst.value>=-128 && dst.value<=127) {
                I386FrontendAsmByte(state,bytes,&count,0x6A);
                I386FrontendAsmByte(state,bytes,&count,dst.value);
              } else {
                I386FrontendAsmByte(state,bytes,&count,0x68);
                I386FrontendAsmDword(state,bytes,&count,dst.value);
              }
            } else I386FrontendUnavailable(state);
          }
        } else if(!StrCmp(name,"MOV") || !StrCmp(name,"LEA") ||
            !StrCmp(name,"TEST") || !StrCmp(name,"XOR") || !StrCmp(name,"ADD") ||
            !StrCmp(name,"CMP") || !StrCmp(name,"SUB")) {
          opcode=0;
          if(!StrCmp(name,"LEA")) opcode=1;
          if(!StrCmp(name,"TEST")) opcode=2;
          if(!StrCmp(name,"XOR")) opcode=3;
          if(!StrCmp(name,"ADD")) opcode=4;
          if(!StrCmp(name,"CMP")) opcode=5;
          if(!StrCmp(name,"SUB")) opcode=6;
          if(opcode==0 && cc->token==TK_IDENT && cc->cur_str &&
              (!StrCmp(cc->cur_str,"DS") || !StrCmp(cc->cur_str,"ES") ||
               !StrCmp(cc->cur_str,"FS") || !StrCmp(cc->cur_str,"GS"))) {
            if(!StrCmp(cc->cur_str,"DS")) i=0xD8;
            else if(!StrCmp(cc->cur_str,"ES")) i=0xC0;
            else if(!StrCmp(cc->cur_str,"FS")) i=0xE0;
            else i=0xE8;
            if(I386FrontendLex(state,cc)!=',' ||
                I386FrontendLex(state,cc)!=TK_IDENT ||
                !cc->cur_str || StrCmp(cc->cur_str,"AX"))
              I386FrontendUnavailable(state);
            I386FrontendLex(state,cc);
            I386FrontendAsmByte(state,bytes,&count,0x8E);
            I386FrontendAsmByte(state,bytes,&count,i);
          } else if(opcode==0 && cc->token==TK_IDENT && cc->cur_str &&
              !StrCmp(cc->cur_str,"AX")) {
            if(I386FrontendLex(state,cc)!=',' ||
                I386FrontendLex(state,cc)!=TK_I64 || cc->cur_i64<0 ||
                cc->cur_i64>65535) I386FrontendUnavailable(state);
            i=cc->cur_i64; I386FrontendLex(state,cc);
            I386FrontendAsmByte(state,bytes,&count,0x66);
            I386FrontendAsmByte(state,bytes,&count,0xB8);
            I386FrontendAsmByte(state,bytes,&count,i);
            I386FrontendAsmByte(state,bytes,&count,i>>8);
          } else {
            I386FrontendAsmOperand(state,cc,&dst);
            if(cc->token!=',') I386FrontendUnavailable(state);
            I386FrontendLex(state,cc);
            I386FrontendAsmOperand(state,cc,&src);
            if(opcode==0 && dst.kind==1 && dst.size==4 &&
                (src.kind==1 || src.kind==2 && src.size==4)) {
              I386FrontendAsmByte(state,bytes,&count,0x8B);
              I386FrontendAsmModRM(state,bytes,&count,dst.register_code,&src);
            } else if(opcode==0 && dst.kind==1 && dst.size==4 &&
                src.kind==3 && src.value>=I32_MIN && src.value<=U32_MAX) {
              I386FrontendAsmByte(state,bytes,&count,0xB8+dst.register_code);
              I386FrontendAsmDword(state,bytes,&count,src.value);
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
            } else if(opcode==3 && dst.kind==1 && dst.size==4 &&
                (src.kind==1 || src.kind==2 && src.size==4)) {
              I386FrontendAsmByte(state,bytes,&count,0x33);
              I386FrontendAsmModRM(state,bytes,&count,dst.register_code,&src);
            } else if(opcode==5 && dst.kind==1 && src.kind==1 &&
                dst.size==4 && src.size==4) {
              I386FrontendAsmByte(state,bytes,&count,0x3B);
              I386FrontendAsmModRM(state,bytes,&count,dst.register_code,&src);
            } else if((opcode==4 || opcode==6) && dst.kind==1 && dst.size==4 &&
                src.kind==3 && src.value>=-128 && src.value<=127) {
              I386FrontendAsmByte(state,bytes,&count,0x83);
              if(opcode==4) I386FrontendAsmModRM(state,bytes,&count,0,&dst);
              else I386FrontendAsmModRM(state,bytes,&count,5,&dst);
              I386FrontendAsmByte(state,bytes,&count,src.value);
            } else I386FrontendUnavailable(state);
          }
        } else if(!StrCmp(name,"DEC")) {
          I386FrontendAsmOperand(state,cc,&dst);
          if(dst.kind!=1 || dst.size!=4) I386FrontendUnavailable(state);
          I386FrontendAsmByte(state,bytes,&count,0x48+dst.register_code);
        } else if(!StrCmp(name,"CALL")) {
          if(cc->token==TK_IDENT && cc->cur_str && !StrCmp(cc->cur_str,"U32")) {
            I386FrontendAsmOperand(state,cc,&dst);
            if(dst.kind!=2 || dst.size!=4) I386FrontendUnavailable(state);
            I386FrontendAsmByte(state,bytes,&count,0xFF);
            I386FrontendAsmModRM(state,bytes,&count,2,&dst);
          } else {
            if(cc->token!=TK_IDENT || call_count>=16) I386FrontendUnavailable(state);
            for(i=0;i<import_count;i++)
              if(!StrCmp(cc->cur_str,imports[i].name)) break;
            if(i==import_count) I386FrontendUnavailable(state);
            I386FrontendTopName(state,calls[call_count].name,cc->cur_str);
            I386FrontendLex(state,cc);
            I386FrontendAsmByte(state,bytes,&count,0xE8);
            calls[call_count].offset=count; call_count++;
            I386FrontendAsmDword(state,bytes,&count,0);
          }
        } else if(!StrCmp(name,"JMP") || !StrCmp(name,"JNZ") ||
            !StrCmp(name,"JZ") || !StrCmp(name,"JC")) {
          if(!StrCmp(name,"JMP") && cc->token==TK_IDENT && cc->cur_str &&
              I386FrontendAsmReg(cc->cur_str)>=0) {
            I386FrontendAsmOperand(state,cc,&dst);
            if(dst.kind!=1 || dst.size!=4) I386FrontendUnavailable(state);
            I386FrontendAsmByte(state,bytes,&count,0xFF);
            I386FrontendAsmModRM(state,bytes,&count,4,&dst);
          } else {
            if(cc->token!=TK_IDENT || branch_count>=64) I386FrontendUnavailable(state);
            I386FrontendTopName(state,branches[branch_count].name,cc->cur_str);
            I386FrontendLex(state,cc);
            if(StrCmp(name,"JMP")) {
              I386FrontendAsmByte(state,bytes,&count,0x0F);
              if(!StrCmp(name,"JNZ")) opcode=0x85;
              else if(!StrCmp(name,"JZ")) opcode=0x84;
              else opcode=0x82;
              I386FrontendAsmByte(state,bytes,&count,opcode);
            } else I386FrontendAsmByte(state,bytes,&count,0xE9);
            branches[branch_count].offset=count; branch_count++;
            I386FrontendAsmDword(state,bytes,&count,0);
          }
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
  if(!export_count || !count) I386FrontendUnavailable(state);
  for(i=0;i<branch_count;i++) {
    for(j=0;j<label_count;j++)
      if(!StrCmp(branches[i].name,labels[j].name)) break;
    if(j<label_count) delta=labels[j].offset-branches[i].offset-4;
    else {
      for(j=0;j<export_count;j++)
        if(!StrCmp(branches[i].name,exports[j].name)) break;
      if(j==export_count) I386FrontendUnavailable(state);
      delta=exports[j].offset-branches[i].offset-4;
    }
    for(k=0;k<4;k++) bytes[branches[i].offset+k]=delta>>(k*8);
  }
  bundle=I386FrontendAlloc(state,sizeof(CI386FrontendTopBundle),TRUE,FALSE);
  bundle->bytes=count; bundle->export_count=export_count;
  bundle->call_count=call_count;
  for(i=0;i<count;i++) bundle->code[i]=bytes[i];
  for(i=0;i<export_count;i++) {
    bundle->exports[i].offset=exports[i].offset;
    for(j=0;j<32;j++) bundle->exports[i].name[j]=exports[i].name[j];
  }
  for(i=0;i<call_count;i++) {
    bundle->calls[i].offset=calls[i].offset;
    for(j=0;j<32;j++) bundle->calls[i].name[j]=calls[i].name[j];
  }
  state->top_bundle=bundle;
}
