//Complete original optional editor services, owned by the kernel after first use.
#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#define NULL 0
#include "/Kernel/I386/Intrinsic.HH"
#include "/Kernel/I386/EditorRuntime.HH"
#include "/Kernel/StringFindFlags.HH"
#include "/Kernel/RawTypes.HH"
#include "/Kernel/NumericLimits.HH"
U32 editor_version=I386_EDITOR_VERSION;
CI386EditorBindings editor_bindings;
CI386EditorBindings *editor_context;
Bool DocLock(CDoc*d){return (*editor_context->doc_lock)(d);}
Bool DocUnlock(CDoc*d){return (*editor_context->doc_unlock)(d);}
Bool DocRecalc(CDoc*d,I64 flags=RECALCt_NORMAL){return (*editor_context->doc_recalc)(d,flags);}
U0 DocCenter(CDoc*d=NULL,I64 flags=RECALCt_NORMAL){(*editor_context->doc_center)(d,flags);}
I64 EdCurU8(CDoc*d){return (*editor_context->cur_u8)(d);}
U0 EdCursorLeft(CDoc*d,I64 sc=0){(*editor_context->cursor_left)(d,sc);}
U0 EdCursorRight(CDoc*d,I64 sc=0){(*editor_context->cursor_right)(d,sc);}
Bool BEqu(U8*b,I64 bit,Bool value){if(value)return Bts(b,bit);return Btr(b,bit);}
U8 *StrMatch(U8*needle,U8*haystack)
{
 U8*at=haystack;I64 i;
 while(TRUE){i=0;while(needle[i]&&at[i]==needle[i])i++;if(!needle[i])return at;if(!*at)return NULL;at++;}
}
#include "/Kernel/StrIMatchCore.HC"
#define char_bmp_alpha_numeric (editor_context->alpha_numeric)
#include "/Kernel/StrFindCore.HC"
#include "/Adam/DolDoc/DocEditorSearchCore.HC"
//Form dependencies borrow permanent Console services; metadata stays caller-owned.
public _intern 0x15 CTask *Fs();
#include "/Kernel/SymbolTypes.HH"
#include "/Kernel/TaskDisplayFlags.HH"
I64 StrCmp(U8*a,U8*b){return (*editor_context->str_cmp)(a,b);}
CHash *HashFind(U8*n,CHashTable*t,I64 mask,I64 instance=1){return (*editor_context->hash_find)(n,t,mask,instance);}
CDoc *DocNew(U8*n=NULL,CTask*t=NULL){return (*editor_context->doc_new)(n,t);}
U0 DocDel(CDoc*d){(*editor_context->doc_del)(d);}
U8 *MAlloc(I64 n,CTask*t=NULL){return (*editor_context->alloc)(n,t);}
U0 Free(U8*p){(*editor_context->free)(p);}
U0 DocDataFmt(CDoc*d,CDocEntry*e,I64 value=DOCM_CANCEL){(*editor_context->data_fmt)(d,e,value);}
Bool DocEd(CDoc*d,I64 flags=0){return (*editor_context->doc_ed)(d,flags);}
I64 DocEntryRun(CDoc*d,CDocEntry*e,Bool exited,I64*action=NULL){return (*editor_context->entry_run)(d,e,exited,action);}
#include "/Compiler/MemberLookup.HC"
#include "/Compiler/OptClassFwdCore.HC"
//Preserve the original variadic ABI through permanent Console function pointers.
#define DocPrint (*editor_context->doc_print)
#define PopUpPrint (*editor_context->popup_print)
#include "/Adam/DolDoc/DocClassFormCore.HC"
#include "/Adam/DolDoc/DocFormPopupCore.HC"
//Resolve only the permanent Console array. Caller hash-table shadows are irrelevant.
U8 *EditorConsoleSymbol(CI386EditorContext*context,U8*name)
{
 I64 i;U8*result=NULL;CI386KernelSymbol*symbol;
 for(i=0;i<context->symbol_count;i++){
  symbol=&context->symbols[i];
  if(symbol->str&&!(*context->str_cmp)(symbol->str,name)){
   if(result||symbol->kind!=1||symbol->type!=HTT_EXPORT_SYS_SYM||symbol->val<=0||symbol->val>0xFFFFFFFF)return NULL;
   result=symbol->val;
  }
 }
 return result;
}
U8 *MemCpy(U8*d,U8*s,I64 n){return (*editor_context->copy)(d,s,n);}
U8 *MemSet(U8*d,I64 v,I64 n){return (*editor_context->set)(d,v,n);}
CDocEntry *DocSplitTag(CDoc*d,CDocEntry*e,I64 at,I64 x,I64 y,I64 type){return (*editor_context->split_tag)(d,e,at,x,y,type);}
U0 DocEntryDel(CDoc*d,CDocEntry*e){(*editor_context->entry_del)(d,e);}
U0 DocRemSoftNewLines(CDoc*d=NULL,CDocEntry*e=NULL){(*editor_context->rem_soft)(d,e);}
U0 DocBottom(CDoc*d=NULL){(*editor_context->doc_bottom)(d);}
#include "/Adam/DolDoc/DocFindCore.HC"
I64 PopUpMenu(CDoc*d,I64 flags=0){return (*editor_context->popup_menu)(d,flags);}
#include "/Adam/DolDoc/DocEditorReplaceCore.HC"
Bool EditorInit(CI386EditorContext*context,I64 bytes)
{
 if(editor_context||!context||bytes!=sizeof(CI386EditorContext)||context->version!=I386_EDITOR_VERSION||
    context->bytes!=sizeof(CI386EditorContext)||!context->alpha_numeric||!context->symbols||
    context->symbol_count<=0||context->symbol_count>4096||!context->str_cmp||!context->hash_find||!context->alloc||!context->free||!context->copy||!context->set)return FALSE;
 editor_bindings.alpha_numeric=context->alpha_numeric;
 editor_bindings.str_cmp=context->str_cmp;editor_bindings.hash_find=context->hash_find;
 editor_bindings.alloc=context->alloc;editor_bindings.free=context->free;
 editor_bindings.copy=context->copy;editor_bindings.set=context->set;
 if(!(editor_bindings.doc_lock=EditorConsoleSymbol(context,"_DOC_LOCK")))return FALSE;
 if(!(editor_bindings.doc_unlock=EditorConsoleSymbol(context,"_DOC_UNLOCK")))return FALSE;
 if(!(editor_bindings.doc_recalc=EditorConsoleSymbol(context,"_DOC_RECALC")))return FALSE;
 if(!(editor_bindings.doc_center=EditorConsoleSymbol(context,"_DOC_CENTER")))return FALSE;
 if(!(editor_bindings.cur_u8=EditorConsoleSymbol(context,"_ED_CUR_U8")))return FALSE;
 if(!(editor_bindings.cursor_left=EditorConsoleSymbol(context,"_ED_CURSOR_LEFT")))return FALSE;
 if(!(editor_bindings.cursor_right=EditorConsoleSymbol(context,"_ED_CURSOR_RIGHT")))return FALSE;
 if(!(editor_bindings.doc_new=EditorConsoleSymbol(context,"_DOC_NEW")))return FALSE;
 if(!(editor_bindings.doc_del=EditorConsoleSymbol(context,"_DOC_DEL")))return FALSE;
 if(!(editor_bindings.doc_print=EditorConsoleSymbol(context,"_DOC_PRINT")))return FALSE;
 if(!(editor_bindings.data_fmt=EditorConsoleSymbol(context,"_DOC_DATA_FMT")))return FALSE;
 if(!(editor_bindings.doc_ed=EditorConsoleSymbol(context,"_DOC_ED")))return FALSE;
 if(!(editor_bindings.entry_run=EditorConsoleSymbol(context,"_DOC_ENTRY_RUN")))return FALSE;
 if(!(editor_bindings.popup_print=EditorConsoleSymbol(context,"_POP_UP_PRINT")))return FALSE;
 if(!(editor_bindings.split_tag=EditorConsoleSymbol(context,"_DOC_SPLIT_TAG")))return FALSE;
 if(!(editor_bindings.entry_del=EditorConsoleSymbol(context,"_DOC_ENTRY_DEL")))return FALSE;
 if(!(editor_bindings.rem_soft=EditorConsoleSymbol(context,"_DOC_REM_SOFT")))return FALSE;
 if(!(editor_bindings.doc_bottom=EditorConsoleSymbol(context,"_DOC_BOTTOM")))return FALSE;
 if(!(editor_bindings.popup_menu=EditorConsoleSymbol(context,"_POP_UP_MENU")))return FALSE;
 editor_context=&editor_bindings;return TRUE;
}

I64 Main(CI386EditorServices*services,I64 bytes)
{
 if(!services||bytes!=sizeof(CI386EditorServices))return 0;
 services->version=editor_version;services->bytes=sizeof(CI386EditorServices);services->init=&EditorInit;
 services->str_find=&StrFind;services->find_next=&EdFindNext;services->sel_all=&EdSelAll;
 services->find_paired=&EdFindPaired;services->go_to_fun=&EdGoToFun;services->sel_fun=&EdSelFun;
 services->form=&DocForm;services->popup=&PopUpForm;services->replace=&EdReplace;services->go_to_line=&DocGoToLine;
 services->doc_find=&DocFind;services->doc_anchor_find=&DocAnchorFind;
 services->find_replace=&EdFindReplace;services->prompt_go_to_line=&EdGoToLine;
 return 1;
}
