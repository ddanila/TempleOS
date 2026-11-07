U0 DLLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 DLCheck()
{
  CDoc *src=DocNew,*dst=DocNew,*put=DocPut;CDocEntry *entry,*next,*res;
  U8 *before=NULL,*after=NULL,*bytes=NULL,*s;I64 mask=0,n1,n2,size;
  Bool raw=Raw(OFF);
  try {
    DocPutS(src,"A$$$$\tB\nTail");
    entry=src->head.next;next=entry;
    while(next!=src && next->type_u8!=DOCT_NEW_LINE)next=next->next;
    if(next!=src)next=next->next;
    before=DocSave(src,&n1);Fs->put_doc=dst;
    res=DocPutLine(src,entry);
    if(res==next)mask|=1;
    after=DocSave(src,&n2);
    if(n1==n2 && !MemCmp(before,after,n1))mask|=2;
    if(DocPut==dst)mask|=4;
    bytes=DocSave(dst,&size);
    s=MStrPrint("EXPORT doc-line-output.DD %X %X\n",bytes,size);DLLog(s);Free(s);Sleep(1000);
    if(DocPutLine(src,src)==src)mask|=8;
    src->doc_signature=0;
    if(!DocPutLine(src,entry))mask|=16;
    src->doc_signature=DOC_SIGNATURE_VAL;
  } catch {src->doc_signature=DOC_SIGNATURE_VAL;}
  Fs->put_doc=put;Free(before);Free(after);Free(bytes);DocDel(src);DocDel(dst);Raw(raw);
  s=MStrPrint("EXPORT doc-line-mask.bin %X 8\n",&mask);DLLog(s);Free(s);
  DLLog("PUBLIC DOC LINE DONE\n");Sleep(1000);
}
