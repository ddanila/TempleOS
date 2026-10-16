U0 LinkedLstDel(U8 **_lst)
{//Free entire linked-list.
  U8 **tmpl;
  while (_lst) {
    tmpl=*_lst;
    Free(_lst);
    _lst=tmpl;
  }
}

U8 *LinkedLstCopy(U8 **_lst,CTask *mem_task=NULL)
{//MAlloc ident copy of entire linked-list.
  U8 *res=NULL,**tmpl=&res;
  while (_lst) {
    tmpl=*tmpl=MAllocIdent(_lst,mem_task);
    _lst=*_lst;
  }
  return res;
}

I64 LinkedLstCnt(U8 **_lst)
{//Count of nodes in linked-list.
  I64 res=0;
  while (_lst) {
    res++;
    _lst=*_lst;
  }
  return res;
}

I64 LinkedLstSize(U8 **_lst)
{//Mem size of all nodes in linked-list.
  I64 res=0;
  while (_lst) {
    res+=MSize2(_lst);
    _lst=*_lst;
  }
  return res;
}

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

CQue *QueCopy(CQue *head,CTask *mem_task=NULL)
{//MAlloc ident copy of entire queue and head.
  CQue *res=MAllocIdent(head,mem_task),*tmpq=head->next,*tmpq1;
  QueInit(res);
  while (tmpq!=head) {
    tmpq1=MAllocIdent(tmpq,mem_task);
    QueIns(tmpq1,res->last);
    tmpq=tmpq->next;
  }
  return res;
}

I64 QueCnt(CQue *head)
{//Count of nodes in queue, not head.
  CQue *tmpq=head->next;
  I64 res=0;
  while (tmpq!=head) {
    res++;
    tmpq=tmpq->next;
  }
  return res;
}

I64 QueSize(CQue *head)
{//Mem size of all nodes in queue, not head.
  CQue *tmpq=head->next;
  I64 res=0;
  while (tmpq!=head) {
    res+=MSize2(tmpq);
    tmpq=tmpq->next;
  }
  return res;
}

CQueVectU8 *QueVectU8New(I64 min_idx=0)
{//Create new queue vecter.
  CQueVectU8 *res=MAlloc(sizeof(CQueVectU8));
  QueInit(res);
  res->total_cnt=res->node_cnt=0;
  res->min_idx=min_idx;
  return res;
}

U0 QueVectU8Put(CQueVectU8 *v,I64 idx,U8 ch)
{//Put U8 at idx i.
  CQueVectU8 *tmpv;
  idx-=v->min_idx;
  if (idx<0) return;
  if (idx<v->total_cnt) {
    tmpv=v;
    do {
      idx-=tmpv->node_cnt;
      if (idx<0) {
	tmpv->body[idx+tmpv->node_cnt]=ch;
	return;
      }
      tmpv=tmpv->next;
    } while (tmpv!=v);
  } else
    idx-=v->total_cnt;

  while (TRUE) {
    tmpv=v->last;
    if (tmpv->node_cnt>=QUE_VECT_U8_CNT) {
      tmpv=MAlloc(sizeof(CQueVectU8));
      tmpv->node_cnt=0;
      QueIns(tmpv,v->last);
    }
    if (idx--) {
      tmpv->body[tmpv->node_cnt++]=0;
      v->total_cnt++;
    } else {
      tmpv->body[tmpv->node_cnt++]=ch;
      v->total_cnt++;
      break;
    }
  }
}

U0 QueVectU8Del(CQueVectU8 *v)
{//Free entire queue vector.
  if (v) {
    QueDel(v);
    Free(v);
  }
}

I64 QueVectU8Get(CQueVectU8 *v,I64 idx)
{//Get U8 at idx i.
  CQueVectU8 *tmpv;
  idx-=v->min_idx;
  if (!(0<=idx<v->total_cnt)) return 0;
  tmpv=v;
  do {
    idx-=tmpv->node_cnt;
    if (idx<0)
      return tmpv->body[idx+tmpv->node_cnt];
    tmpv=tmpv->next;
  } while (tmpv!=v);
  return 0;
}

#include "/Kernel/FifoCore.HC"
