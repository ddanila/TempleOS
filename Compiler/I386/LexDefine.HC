#include "/Compiler/I386/LexDefine.HH"
#include "/Compiler/LexDefine.HC"
class CI386LexDefineBuffer { CI386Heap *heap; U8 *text; I64 length; };
Bool I386LexDefineAppend(U8 *context,U8 *text,I64 count)
{
  CI386LexDefineBuffer *buffer=context; U8 *next; I64 i; U32 flags;
  if(count<1 || buffer->length>0xFFFFFFFF-23-count) return FALSE;
  flags=I386IrqSave;
  next=I386HeapAlloc(buffer->heap,buffer->length+count,FALSE);
  I386IrqRestore(flags);
  if(!next) return FALSE;
  for(i=0;i<buffer->length;i++) next[i]=buffer->text[i];
  for(i=0;i<count;i++) next[buffer->length+i]=text[i];
  flags=I386IrqSave;
  if(buffer->text) I386HeapFree(buffer->heap,buffer->text);
  I386IrqRestore(flags);
  buffer->text=next; buffer->length+=count-1;
  return TRUE;
}
U8 *I386LexDefineBody(CI386Heap *heap,CCmpCtrl *cc,I64 *compiled_lines)
{
  CI386LexCharSource native; CLexCharSource source; CLexDefineSink sink;
  CI386LexDefineBuffer buffer; U32 flags;
  if(!heap || !cc || !compiled_lines) return 0;
  native.heap=heap; native.compiled_lines=compiled_lines;
  source.context=&native; source.read=&I386LexSourceRead;
  buffer.heap=heap; buffer.text=0; buffer.length=0;
  sink.context=&buffer; sink.append=&I386LexDefineAppend;
  if(LexDefineRead(cc,&source,&sink)) return buffer.text;
  flags=I386IrqSave;
  if(buffer.text) I386HeapFree(heap,buffer.text);
  I386IrqRestore(flags);
  return 0;
}
Bool I386LexDefinePublish(CI386Heap *heap,CCmpCtrl *cc,I64 *compiled_lines)
{
  CHashDefineStr *entry=0;
  U8 digits[20],*name,*help; I64 length=0,help_length=0,line,count=0,i; U32 flags;
  if(!heap || !cc || !compiled_lines || cc->token!=TK_IDENT || !cc->cur_str ||
      !cc->lex_include_stk || !cc->lex_include_stk->full_name ||
      !cc->htc.define_hash_table || !cc->htc.define_hash_table->body) return FALSE;
  flags=I386IrqSave;
  if(cc->cur_str_len<1 || I386HeapSize(heap,cc->cur_str)!=cc->cur_str_len) {
    I386IrqRestore(flags); return FALSE;
  }
  entry=I386HeapAlloc(heap,sizeof(CHashDefineStr),TRUE);
  I386IrqRestore(flags);
  if(!entry) return FALSE;
  name=cc->lex_include_stk->full_name; help=cc->cur_help_idx;
  line=cc->lex_include_stk->line_num; if(line<1) line=1;
  do { digits[count++]=48+line%10; line/=10; } while(line);
  while(name[length]) { if(length>=0xFFFFFF00) goto define_failed; length++; }
  if(help) while(help[help_length]) { if(help_length>=0xFFFFFF00) goto define_failed; help_length++; }
  flags=I386IrqSave;
  entry->src_link=I386HeapAlloc(heap,length+count+5,FALSE);
  if(help_length) entry->idx=I386HeapAlloc(heap,help_length+1,FALSE);
  I386IrqRestore(flags);
  if(!entry->src_link || (help_length && !entry->idx)) goto define_failed;
  entry->src_link[0]='F'; entry->src_link[1]='L'; entry->src_link[2]=':';
  for(i=0;i<length;i++) entry->src_link[3+i]=name[i];
  entry->src_link[3+length]=44;
  for(i=0;i<count;i++) entry->src_link[4+length+i]=digits[count-1-i];
  entry->src_link[4+length+count]=0;
  if(help_length) for(i=0;i<=help_length;i++) entry->idx[i]=help[i];
  entry->type=HTT_DEFINE_STR;
  if(cc->opts&(1<<OPTf_KEEP_PRIVATE)) entry->type|=HTF_PRIVATE;
  entry->data=I386LexDefineBody(heap,cc,compiled_lines);
  if(!entry->data) goto define_failed;
  entry->cnt=-1;
  flags=I386IrqSave;
  entry->str=cc->cur_str; cc->cur_str=0;
  HashAdd(entry,cc->htc.define_hash_table);
  I386IrqRestore(flags);
  return TRUE;
define_failed:
  flags=I386IrqSave;
  if(entry->src_link) I386HeapFree(heap,entry->src_link);
  if(entry->idx) I386HeapFree(heap,entry->idx);
  if(entry->data) I386HeapFree(heap,entry->data);
  I386HeapFree(heap,entry);
  I386IrqRestore(flags);
  return FALSE;
}
