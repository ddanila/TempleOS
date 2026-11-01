CDirEntry *DSNode(U8 *name,Bool dir,I64 clus)
{
 CDirEntry *e=CAlloc(sizeof(CDirEntry));e->full_name=StrNew(name);StrCpy(e->name,name);e->clus=clus;if(dir)e->attr|=0x10;return e;
}
I64 DSContract()
{
 I64 before=Fs->data_heap->used_u8s,mask=0;
 CDirEntry *a,*b,*c,*d,*e,*f,*head;
 head=NULL;DirFilesSort(&head,0);if(!head)mask|=1;
 a=DSNode("B.HC",FALSE,4);b=DSNode("ZZ",TRUE,3);c=DSNode("A.HC",FALSE,2);d=DSNode("AZ",TRUE,1);
 e=DSNode("C.HC",FALSE,7);f=DSNode("A.HC",FALSE,8);a->next=b;b->next=c;c->next=d;d->sub=e;e->next=f;head=a;
 DirFilesSort(&head,0);
 if(head==d && d->next==b && b->next==c && c->next==a && !a->next)mask|=2;
 if(d->sub==f && f->next==e && !e->next)mask|=4;
 DirTreeDel(head);if(Fs->data_heap->used_u8s==before)mask|=8;
 a=DSNode("X",FALSE,9);b=DSNode("Y",FALSE,2);c=DSNode("Z",FALSE,5);
 d=DSNode("P",FALSE,8);e=DSNode("Q",FALSE,1);a->next=b;b->next=c;a->sub=d;d->next=e;head=a;
 DirFilesSort(&head,1);
 if(head==b && b->next==c && c->next==a && !a->next)mask|=16;
 if(a->sub==e && e->next==d && !d->next)mask|=32;
 DirTreeDel(head);if(Fs->data_heap->used_u8s==before)mask|=64;
 a=DSNode("D",TRUE,1);a->sub=DSNode("B",FALSE,2);a->sub->next=DSNode("A",FALSE,3);head=a;
 DirFilesSort(&head,0);if(head==a && !StrCmp(a->sub->name,"A") && !StrCmp(a->sub->next->name,"B"))mask|=128;
 DirTreeDel(head);if(Fs->data_heap->used_u8s==before)mask|=256;
 return mask;
}
