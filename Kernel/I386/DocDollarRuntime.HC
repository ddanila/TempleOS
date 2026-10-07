//Original dollar grammar and data fields, using task-owned native compilation.
import I64 MSize(U8 *allocation);
Bool NativeDocBEqu(U8 *bits,I64 index,Bool value)
{
  if(value) return Bts(bits,index);
  return Btr(bits,index);
}
U8 *NativeDocStrMatch(U8 *needle,U8 *haystack)
{
  U8 *at=haystack;
  I64 i;
  while(TRUE) {
    i=0;
    while(needle[i] && at[i]==needle[i]) i++;
    if(!needle[i]) return at;
    if(!*at) return NULL;
    at++;
  }
}
#include "/Adam/DolDoc/DocFormDataCore.HC"
#include "/Adam/DolDoc/DocBinPtrCore.HC"
#define BEqu NativeDocBEqu
#define StrMatch NativeDocStrMatch
#include "/Adam/DolDoc/DocDollarFlagsCore.HC"
#include "/Adam/DolDoc/DocDollarParseCore.HC"
CDocEntry *PrsDollarCmd(CDoc *doc,U8 *source)
{
  CI386DocParser parser;
  CDocDollarServices services;
  CDocEntry *result;
  NativeDocParserOpen(&parser,source);
  NativeDocDollarServices(&services,&parser);
  try { result=PrsDollarCmdCore(&services,parser.control,doc,source); }
  catch { NativeDocParserClose(&parser); }
  NativeDocParserClose(&parser);
  return result;
}

//Original bitmap contents: zero, CR/NL/cursor; optional tab and dollar.
U32 char_bmp_zero_cr_nl_cursor[16]={0x00002421,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    char_bmp_zero_tab_cr_nl_cursor[16]={0x00002621,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    char_bmp_zero_tab_cr_nl_cursor_dollar[16]={0x00002621,0x10,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
#include "/Adam/DolDoc/DocPutSCore.HC"
