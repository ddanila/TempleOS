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

#include "/Kernel/I386/Cpu.HH"
class CI386IdentSink { CI386Heap *heap; U8 *macro_filename; };
Bool I386IdentInclude(U8 *context,CCmpCtrl *cc,CHashDefineStr *entry)
{
  CI386IdentSink *sink=context;
  return I386LexIncludeCopy(sink->heap,cc,sink->macro_filename,entry->data,TRUE);
}
Bool I386IdentPublish(U8 *context,CCmpCtrl *cc,U8 *name,I64 length,CHash *entry)
{
  CI386IdentSink *sink=context; U8 *text;
  I64 i; U32 flags=I386IrqSave;
  if(cc->cur_str && I386HeapSize(sink->heap,cc->cur_str)<1) { I386IrqRestore(flags); return FALSE; }
  text=I386HeapAlloc(sink->heap,length,FALSE);
  I386IrqRestore(flags);
  if(!text) return FALSE;
  for(i=0;i<length;i++) text[i]=name[i];
  flags=I386IrqSave;
  if(cc->cur_str && !I386HeapFree(sink->heap,cc->cur_str)) {
    I386HeapFree(sink->heap,text); I386IrqRestore(flags); return FALSE;
  }
  cc->hash_entry=entry; cc->cur_str=text; cc->cur_str_len=length; cc->token=TK_IDENT;
  I386IrqRestore(flags);
  return TRUE;
}
I64 I386LexIdentToken(CI386Heap *heap,CCmpCtrl *cc,I64 ch,U8 *macro_filename,I64 *compiled_lines)
{
  U8 name[STR_LEN]; CHash *entry; CLexIdentSink sink; CI386IdentSink native;
  I64 length,result;
  length=I386LexIdentScan(heap,cc,ch,name,STR_LEN,&entry,compiled_lines);
  if(length==-2) return -3;
  if(length<0) return -1;
  native.heap=heap; native.macro_filename=macro_filename;
  sink.context=&native; sink.include=&I386IdentInclude; sink.publish=&I386IdentPublish;
  result=LexIdentFinish(cc,name,length,entry,&sink);
  if(result!=TK_IDENT) return result;
  if(I386LexRawChar(heap,cc,compiled_lines)<0) return -1;
  cc->flags|=CCF_USE_LAST_U16;
  return TK_IDENT;
}
