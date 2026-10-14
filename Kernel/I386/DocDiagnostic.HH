#ifndef I386_DOC_DIAGNOSTIC_INCLUDED
#define I386_DOC_DIAGNOSTIC_INCLUDED
#define I386_DOC_DIAGNOSTIC_VERSION 1
class CI386DocDiagnosticServices {
  U32 version,bytes;
  I64 (*run)(U8 *context,I64 bytes);
};
#endif
