//Complete original optional editor services, owned by the kernel after first use.
#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#define NULL 0
#include "/Kernel/I386/Intrinsic.HH"
#include "/Kernel/I386/EditorRuntime.HH"
#include "/Kernel/StringFindFlags.HH"
#include "/Kernel/RawTypes.HH"
U32 editor_version=I386_EDITOR_VERSION;
CI386EditorContext *editor_context;
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
Bool EditorInit(CI386EditorContext*context,I64 bytes)
{
 if(editor_context||!context||bytes!=sizeof(CI386EditorContext)||context->version!=I386_EDITOR_VERSION||
    context->bytes!=sizeof(CI386EditorContext)||!context->alpha_numeric||!context->doc_lock||!context->doc_unlock||
    !context->doc_recalc||!context->doc_center||!context->cur_u8||!context->cursor_left||!context->cursor_right||!context->str_cmp||!context->hash_find||!context->doc_new||!context->doc_del||
    !context->doc_print||!context->alloc||!context->free||!context->data_fmt||
    !context->doc_ed||!context->entry_run||!context->popup_print)return FALSE;
 editor_context=context;return TRUE;
}
I64 Main(CI386EditorServices*services,I64 bytes)
{
 if(!services||bytes!=sizeof(CI386EditorServices))return 0;
 services->version=editor_version;services->bytes=sizeof(CI386EditorServices);services->init=&EditorInit;
 services->str_find=&StrFind;services->find_next=&EdFindNext;services->sel_all=&EdSelAll;
 services->find_paired=&EdFindPaired;services->go_to_fun=&EdGoToFun;services->sel_fun=&EdSelFun;
 services->form=&DocForm;services->popup=&PopUpForm;
 return 1;
}
