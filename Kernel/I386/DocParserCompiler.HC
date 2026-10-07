//Caller-owned context for the original DolDoc dollar grammar's compiler calls.
//All frontend storage belongs to an entered compiler control, including on Kill.
class CI386DocParser {
  CI386Task *task;
  CI386Heap *heap;
  CCmpCtrl *boundary,*control;
  CPrsSymbolServices *symbols;
  Bool entered;
};
U0 NativeDocParserClose(CI386DocParser *parser)
{
  if(!parser || !parser->control) return;
  if(parser->task!=I386TaskSelf) throw('Compiler',TRUE);
  if(parser->entered) {
    if(!(*console_config->compiler->control_unwind)(parser->task,parser->boundary))
      throw('Compiler',TRUE);
  } else if(!(*console_config->compiler->control_del)(parser->heap,parser->control,0,0))
    throw('Compiler',TRUE);
  parser->control=0; parser->symbols=0; parser->entered=FALSE;
}
U0 NativeDocParserOpen(CI386DocParser *parser,U8 *source)
{
  CI386Task *task=I386TaskSelf;
  CI386TaskSymbols *scope;
  CI386CompilerServices *compiler;
  if(!parser || !source || !console_config || !task ||
      !(scope=task->symbol_state) || scope->task!=task ||
      scope->signature!=I386_TASK_SYMBOLS_MAGIC) throw('Compiler',TRUE);
  MemSet(parser,0,sizeof(CI386DocParser));
  parser->task=task; parser->heap=scope->heap; parser->boundary=task->last_cc;
  compiler=console_config->compiler;
  try {
    parser->control=(*console_config->files->control_new)(source,CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,0);
    if(!parser->control) throw('OutMem',TRUE);
    if(!(*compiler->control_enter)(parser->heap,parser->control,0,0)) {
      if(!(*compiler->control_del)(parser->heap,parser->control,0,0))
        throw('Compiler',TRUE);
      parser->control=0; throw('OutMem',TRUE);
    }
    parser->entered=TRUE;
    parser->symbols=(*compiler->frontend)(parser->heap,parser->control,
      console_config->types,console_config->includes);
    if(!parser->symbols ||
        !(*compiler->frontend_bind_files)(parser->symbols,console_config->files))
      throw('Compiler',TRUE);
    //Frontend creation requires AOT mode; executed expressions use live task addresses.
    parser->control->flags&=~CCF_AOT_COMPILE;
  } catch {
    NativeDocParserClose(parser);
  }
}
I64 NativeDocParserLex(CI386DocParser *parser)
{
  CPrsExpressionServices *expression=parser->symbols->declarations->expression;
  return (*expression->lex)(expression->context,parser->control);
}
I64 NativeDocParserExpression(CI386DocParser *parser)
{
  CPrsDeclarationServices *declarations=parser->symbols->declarations;
  return (*declarations->evaluate)(declarations->context,parser->control);
}
I64 NativeDocParserInteger(CI386DocParser *parser)
{
  CPrsTypeServices *types=parser->symbols->declarations->types;
  return (*types->integer_expression)(types->context,parser->control);
}
U8 *NativeDocParserString(CI386DocParser *parser,I64 *size=0)
{//Normal LexExtStr: join adjacent literals and return caller-owned bytes.
  CPrsDeclarationServices *declarations=parser->symbols->declarations;
  CPrsExpressionServices *expression=declarations->expression;
  U8 *tracked,*copy;
  I64 bytes;
  tracked=(*expression->string)(expression->context,parser->control,&bytes);
  if(bytes<1) throw('Compiler',TRUE);
  //Keep the tracked result attached to the control until the copy succeeds.
  copy=MAlloc(bytes);
  MemCpy(copy,tracked,bytes);
  try {
    (*declarations->release)(declarations->context,tracked);
  } catch {
    Free(copy);
  }
  if(size) *size=bytes;
  return copy;
}
#include "/Adam/DolDoc/DocDollarServices.HH"
I64 NativeDocDollarLex(U8 *context,CCmpCtrl *cc)
{
  CI386DocParser *parser=context;
  if(parser->control!=cc) throw('Compiler',TRUE);
  return NativeDocParserLex(parser);
}
I64 NativeDocDollarExpression(U8 *context,CCmpCtrl *cc)
{
  CI386DocParser *parser=context;
  if(parser->control!=cc) throw('Compiler',TRUE);
  return NativeDocParserExpression(parser);
}
I64 NativeDocDollarInteger(U8 *context,CCmpCtrl *cc)
{
  CI386DocParser *parser=context;
  if(parser->control!=cc) throw('Compiler',TRUE);
  return NativeDocParserInteger(parser);
}
U8 *NativeDocDollarString(U8 *context,CCmpCtrl *cc)
{
  CI386DocParser *parser=context;
  if(parser->control!=cc) throw('Compiler',TRUE);
  return NativeDocParserString(parser);
}
U0 NativeDocDollarServices(CDocDollarServices *services,CI386DocParser *parser)
{
  services->context=parser; services->lex=&NativeDocDollarLex;
  services->expression=&NativeDocDollarExpression;
  services->integer_expression=&NativeDocDollarInteger;
  services->string=&NativeDocDollarString;
}
