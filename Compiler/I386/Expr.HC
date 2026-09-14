// Initial i386 backend entry point. Uses the existing HolyC expression parser.
// Returned bytes are target code: never call them from the x86-64 compiler host.
extern U0 COCInit(CCmpCtrl *cc);
extern U0 COCDel(CCmpCtrl *cc,CCodeCtrl *coc);
extern Bool PrsExpression(CCmpCtrl *cc,I64 *unary_post_prec=NULL,
  Bool end_exp=TRUE,CPrsStk *ps=NULL);

#include "/Compiler/I386/Emit.HC"

public U8 *I386Expr(U8 *source,I64 *size)
{
  CCmpCtrl *cc=CmpCtrlNew(source,CCF_DONT_FREE_BUF);
  CIntermediateCode *ic;
  CI386Out out;
  I64 depth=0;
  U8 *result=NULL;
  I386OutInit(&out);
  *size=0;
  QueIns(cc,Fs->last_cc);
  COCInit(cc);
  try {
    Lex(cc);
    if (!PrsExpression(cc,NULL,FALSE)) throw('Compiler');
    if (cc->token!=TK_EOF) throw('Compiler');
    // Preserve callee-saved scratch registers; evaluation stack holds I64 pairs.
    I386Bytes(&out,"\x53\x56\x57",3);
    for (ic=cc->coc.coc_head.next;ic!=&cc->coc.coc_head;ic=ic->next) {
      if (ic->ic_class && (ic->ic_class->ptr_stars_cnt ||
          (ic->ic_class->raw_type!=RT_I64 && ic->ic_class->raw_type!=RT_U64)))
        throw('Compiler');
      switch (ic->ic_code) {
        case IC_NOP1:
        case IC_NOP2:
        case IC_END_EXP:
        case IC_HOLYC_TYPECAST:
          break;
        case IC_SIZEOF:
          // Parser inserts deferred pointer scaling around addition/subtraction.
          // This entry point rejects pointers, so the integer scale is one.
          I386Bytes(&out,"\x6A\x00\x6A\x01",4);
          depth++;
          break;
        case IC_IMM_I64:
          I386Byte(&out,0x68); I386Dword(&out,ic->ic_data.u32[1]);
          I386Byte(&out,0x68); I386Dword(&out,ic->ic_data.u32[0]);
          depth++;
          break;
        case IC_UNARY_MINUS:
        case IC_COM:
          if (depth<1) throw('Compiler');
          I386Bytes(&out,"\x58\x5A",2); // pop eax,edx
          if (ic->ic_code==IC_COM)
            I386Bytes(&out,"\xF7\xD0\xF7\xD2",4);
          else
            I386Bytes(&out,"\xF7\xD8\x83\xD2\x00\xF7\xDA",7);
          I386Bytes(&out,"\x52\x50",2);
          break;
        case IC_ADD:
        case IC_SUB:
        case IC_AND:
        case IC_OR:
        case IC_XOR:
        case IC_MUL:
          if (depth<2) throw('Compiler');
          I386Bytes(&out,"\x59\x5B\x58\x5A",4); // right ecx:ebx; left eax:edx
          switch (ic->ic_code) {
            case IC_ADD: I386Bytes(&out,"\x01\xC8\x11\xDA",4); break;
            case IC_SUB: I386Bytes(&out,"\x29\xC8\x19\xDA",4); break;
            case IC_AND: I386Bytes(&out,"\x21\xC8\x21\xDA",4); break;
            case IC_OR:  I386Bytes(&out,"\x09\xC8\x09\xDA",4); break;
            case IC_XOR: I386Bytes(&out,"\x31\xC8\x31\xDA",4); break;
            case IC_MUL:
              I386Bytes(&out,"\x89\xC6\x89\xD7\x0F\xAF\xF9\x0F\xAF\xDE"
                "\xF7\xE1\x01\xFA\x01\xDA",16);
              break;
          }
          I386Bytes(&out,"\x52\x50",2);
          depth--;
          break;
        default:
          PrintErr("i386 expression opcode 0x%X is not implemented.\n",ic->ic_code);
          throw('Compiler');
      }
    }
    if (depth!=1) throw('Compiler');
    I386Bytes(&out,"\x58\x5A\x5F\x5E\x5B\xC3",6);
    *size=out.count;
    result=out.data;
  } catch {
    Free(out.data);
    Fs->catch_except=TRUE;
  }
  COCDel(cc,&cc->coc);
  QueRem(cc);
  CmpCtrlDel(cc);
  return result;
}
