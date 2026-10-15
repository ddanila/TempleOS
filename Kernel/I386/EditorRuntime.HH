#ifndef I386_EDITOR_RUNTIME_INCLUDED
#define I386_EDITOR_RUNTIME_INCLUDED
#include "/Kernel/I386/DocAccess.HH"
#include "/Kernel/I386/KernelSymbols.HH"
#define I386_EDITOR_VERSION 3
class CI386EditorBindings {
 U32 version,bytes;
 U32 *alpha_numeric;
 Bool (*doc_lock)(CDoc *doc);
 Bool (*doc_unlock)(CDoc *doc);
 Bool (*doc_recalc)(CDoc *doc,I64 flags);
 U0 (*doc_center)(CDoc *doc,I64 flags);
 I64 (*cur_u8)(CDoc *doc);
 U0 (*cursor_left)(CDoc *doc,I64 sc);
 U0 (*cursor_right)(CDoc *doc,I64 sc);
 I64 (*str_cmp)(U8 *a,U8 *b);
 CHash *(*hash_find)(U8 *name,CHashTable *table,I64 mask,I64 instance);
 CDoc *(*doc_new)(U8 *filename,CTask *task);
 U0 (*doc_del)(CDoc *doc);
 CDocEntry *(*doc_print)(CDoc *doc,U8 *format,...);
 U8 *(*alloc)(I64 bytes,CTask *task);
 U0 (*free)(U8 *allocation);
 U0 (*data_fmt)(CDoc *doc,CDocEntry *entry,I64 value);
 Bool (*doc_ed)(CDoc *doc,I64 flags);
 I64 (*entry_run)(CDoc *doc,CDocEntry *entry,Bool exited,I64 *action);
 I64 (*popup_print)(U8 *format,...);
};
class CI386EditorContext {
 U32 version,bytes;
 U32 *alpha_numeric;
 CI386KernelSymbol *symbols;
 I64 symbol_count;
 I64 (*str_cmp)(U8 *a,U8 *b);
 CHash *(*hash_find)(U8 *name,CHashTable *table,I64 mask,I64 instance);
 U8 *(*alloc)(I64 bytes,CTask *task);
 U0 (*free)(U8 *allocation);
};
class CI386EditorServices {
 U32 version,bytes;
 Bool (*init)(CI386EditorContext *context,I64 bytes);
 U8 *(*str_find)(U8 *needle,U8 *haystack,I64 flags);
 U0 (*find_next)(CDoc *doc);
 U0 (*sel_all)(CDoc *doc,Bool sel);
 Bool (*find_paired)(CDoc *doc,U8 plus,U8 minus,Bool fwd,Bool abort_colon);
 Bool (*go_to_fun)(CDoc *doc,Bool fwd,Bool abort_colon);
 U0 (*sel_fun)(CDoc *doc,Bool abort_colon);
 Bool (*form)(U8 *data,U8 *class_name,I64 flags,U8 *header,U8 *footer);
 Bool (*popup)(U8 *data,U8 *class_name,I64 flags,U8 *header,U8 *footer);
};
#endif
