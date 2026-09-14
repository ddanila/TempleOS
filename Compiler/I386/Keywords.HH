#ifndef I386_KEYWORDS_INCLUDED
#define I386_KEYWORDS_INCLUDED
#include "/Compiler/KeywordTable.HH"
#include "/Kernel/I386/HashTable.HH"
class CI386Keywords { CI386Heap *heap; CHashTable *table; };
//Zeroed exclusively owned registry. Keep entries read-only; definitions live above it.
public extern Bool I386KeywordsInit(CI386Keywords *registry,CI386Heap *heap);
//Detach all incoming references before deletion. Clears the registry for reuse.
public extern Bool I386KeywordsDelete(CI386Keywords *registry);
#endif
