#ifndef I386_EDITOR_RUNTIME_INCLUDED
#define I386_EDITOR_RUNTIME_INCLUDED
#include "/Kernel/I386/DocAccess.HH"
#define I386_EDITOR_VERSION 1
class CI386EditorContext {
 U32 version,bytes;
 U32 *alpha_numeric;
 Bool (*doc_lock)(CDoc *doc);
 Bool (*doc_unlock)(CDoc *doc);
 Bool (*doc_recalc)(CDoc *doc,I64 flags);
 U0 (*doc_center)(CDoc *doc,I64 flags);
 I64 (*cur_u8)(CDoc *doc);
 U0 (*cursor_left)(CDoc *doc,I64 sc);
 U0 (*cursor_right)(CDoc *doc,I64 sc);
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
};
#endif
