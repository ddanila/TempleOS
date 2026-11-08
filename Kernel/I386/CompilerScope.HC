#ifndef I386_COMPILER_SCOPE_INCLUDED
#define I386_COMPILER_SCOPE_INCLUDED
//A caller may prepend borrowed tables without transferring the owned scope.
//Only the prefix up to that scope is relevant; reject detached or cyclic heads.
Bool I386CompilerScopeLinked(CHashTable *head,CHashTable *owned)
{
  CHashTable *slow=head,*fast=head;
  if(!owned) return FALSE;
  while(slow) {
    if(slow==owned) return TRUE;
    slow=slow->next;
    if(fast && fast->next) fast=fast->next->next;
    else fast=0;
    if(slow && slow==fast) return FALSE;
  }
  return FALSE;
}
#endif
