#ifndef I386_DOC_DIAGNOSTIC_CONTEXT_INCLUDED
#define I386_DOC_DIAGNOSTIC_CONTEXT_INCLUDED
#include "/Kernel/I386/DocDiagnostic.HH"
#include "/Kernel/I386/DocAccess.HH"
#include "/Kernel/DocGlobals.HH"
class CI386DocDiagnosticContext {
  U32 version,bytes;
  CDolDocGlbls *globals;
  CDoc **clipboard;
  I64 *alloc_count;
  U8 *(*alloc)(I64 bytes,CTask *task);
  U8 *(*calloc)(I64 bytes,CTask *task);
  U0 (*free)(U8 *data);
  U8 *(*str_new)(U8 *text,CTask *task);
  I64 (*str_cmp)(U8 *a,U8 *b);
  CDoc *(*doc_new)(U8 *name,CTask *task);
  U0 (*doc_del)(CDoc *doc);
  U0 (*put_key)(CDoc *doc,I64 ch,I64 sc);
  U0 (*ins_entry)(CDoc *doc,CDocEntry *entry);
  U8 *(*save)(CDoc *doc,I64 *size);
  Bool (*load)(CDoc *doc,U8 *bytes,I64 size);
  Bool (*write)(CDoc *doc,Bool prompt);
  CDoc *(*read)(U8 *name,I64 flags);
  U0 (*arm)(I64 fail_after);
  Bool (*copy_clip)(CDoc *doc,Bool clear_selection);
  Bool (*paste_clip)(CDoc *doc);
};
#endif
