#include "/Compiler/I386/LexIdent.HH"
#include "/Compiler/LexIdent.HC"
I64 I386LexIdentScan(CI386Heap *heap,CCmpCtrl *cc,I64 ch,U8 *buf,I64 capacity,CHash **entry,I64 *compiled_lines)
{
  CLexCharSource source; CI386LexCharSource native; I64 length;
  if(!entry) return -1;
  *entry=0;
  if(!cc || !compiled_lines || !buf || capacity<2 || !cc->char_bmp_alpha_numeric) return -1;
  switch(ch) {
    case TK_SUPERSCRIPT: ch='>'; break;
    case TK_SUBSCRIPT: ch='<'; break;
    case TK_NORMALSCRIPT: ch='='; break;
    case '@': if(cc->flags&CCF_KEEP_AT_SIGN) return -1; break;
    case 'A'...'Z': case 'a'...'z': case '_': case 128...255: break;
    default: return -1;
  }
  native.heap=heap; native.compiled_lines=compiled_lines;
  source.context=&native; source.read=&I386LexSourceRead;
  length=LexIdentRead(cc,ch,buf,capacity,&source);
  if(length<0) return length;
  *entry=LexIdentFind(cc,buf);
  return length;
}
