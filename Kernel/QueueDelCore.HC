U0 QueDel(CQue *head,Bool querem=FALSE)
{//Free entries in queue, not head.
  CQue *tmpq=head->next,*tmpq1;
  while (tmpq!=head) {
    tmpq1=tmpq->next;
    if (querem)
      QueRem(tmpq);
    Free(tmpq);
    tmpq=tmpq1;
  }
}

