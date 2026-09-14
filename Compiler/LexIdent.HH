#ifndef COMPILER_LEX_IDENT_INCLUDED
#define COMPILER_LEX_IDENT_INCLUDED
#include "/Compiler/LexInput.HH"
#include "/Compiler/MemberLookup.HH"
#include "/Kernel/StringLimits.HH"
//First identifier byte is normalized and consumed. Length includes the final NUL.
//Return -1 on a reader failure, -2 on capacity exhaustion before lookahead.
public extern I64 LexIdentRead(CCmpCtrl *cc,I64 ch,U8 *buf,I64 capacity,CLexCharSource *source);
//Resolve local members before global symbols. Returned records remain borrowed.
public extern CHash *LexIdentFind(CCmpCtrl *cc,U8 *name);
class CLexIdentSink {
  U8 *context;
  Bool (*include)(U8 *context,CCmpCtrl *cc,CHashDefineStr *entry);
  Bool (*publish)(U8 *context,CCmpCtrl *cc,U8 *name,I64 length,CHash *entry);
};
//Token publication, -2 macro expansion (resume dispatch), or -1 sink failure.
public extern I64 LexIdentFinish(CCmpCtrl *cc,U8 *name,I64 length,CHash *entry,CLexIdentSink *sink);
#endif
