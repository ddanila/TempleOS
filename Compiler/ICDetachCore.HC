U0 ICDetach(CIntermediateCode *node)
{//Leave the removed node fields intact for compiler tree/backward references.
  node->last->next=node->next; node->next->last=node->last;
}
