Bool RRBytes(U8*a,U8*b,I64 n){I64 i;for(i=0;i<n;i++)if(a[i]!=b[i])return FALSE;return TRUE;}
I64 RRContract(I64 mode)
{
 I64 before=Fs->data_heap->used_u8s,m=0,result,want_count=2,i,markers=0;
 CDoc*put=DocPut,*display=DocDisplay,*border=DocBorder,*d;
 U8*text="cat cat",*want="dog dog",*find="cat",*replace="dog",*large=NULL,*line,*last_line;
 CDocEntry*e;CEdFindText saved;Bool selected=FALSE,match_case=TRUE,whole=FALSE;
 if(mode==9){
  if(EdReplace(NULL,"cat","dog")==-1)m|=1;
  m|=14; //No document settings, entry ring or lock exists for NULL.
  if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=16;
  if(Fs->data_heap->used_u8s==before)m|=32;return m;
 }
 if(mode==1){text="Cat cat";match_case=FALSE;}
 if(mode==2){text="cat scatter cat_ cat";want="dog scatter cat_ dog";whole=TRUE;}
 if(mode==3){text="cat\ncat";want="dog";want_count=1;selected=TRUE;}
 if(mode==4){find="";want="cat cat";want_count=0;}
 if(mode==5){find="fish";want="cat cat";want_count=0;}
 if(mode==7||mode==8){
  large=MAlloc(sizeof(CEdFindText.find_text)+1);
  for(i=0;i<sizeof(CEdFindText.find_text);i++)large[i]='X';large[i]=0;
  if(mode==7)find=large;else replace=large;want="cat cat";want_count=-1;
 }
 d=DocNew("Replace.DD");d->flags|=DOCF_PLAIN_TEXT;
 DocLoad(d,text,StrLen(text));d->flags&=~DOCF_PLAIN_TEXT;DocTop(d);
 if(mode==3){EdSelAll(d,FALSE);d->head.next->type|=DOCET_SEL;}
 StrCpy(d->find_replace->find_text,"saved find");StrCpy(d->find_replace->replace_text,"saved replacement");
 d->find_replace->scan_fwd=TRUE;MemCpy(&saved,d->find_replace,sizeof(CEdFindText));
 if(mode==6)DocLock(d);
 result=EdReplace(d,find,replace,selected,match_case,whole);
 if(result==want_count)m|=1;
 if(RRBytes(&saved,d->find_replace,sizeof(CEdFindText)))m|=2;
 line=DocScanLine(d,d->head.next);last_line=DocScanLine(d,d->head.last);
 for(e=d->head.next;e!=d;e=e->next)if(e->type_u8==DOCT_MARKER)markers++;
 if(line&&!StrCmp(line,want)&&!markers&&d->doc_signature==DOC_SIGNATURE_VAL&&
   (mode!=3||last_line&&!StrCmp(last_line,"cat")))m|=4;
 if(Bt(&d->locked_flags,DOClf_LOCKED)==(mode==6))m|=8;
 if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=16;
 Free(line);Free(last_line);Free(large);DocUnlock(d);DocDel(d);
 if(Fs->data_heap->used_u8s==before)m|=32;return m;
}
I64 RRCheck(I64 mode){I64 m=RRContract(mode);if(m!=63)throw('Replace',TRUE);return m;}

I64 RRLine(I64 mode)
{
 I64 before=Fs->data_heap->used_u8s,m=0,target=2;CDoc*d,*put=DocPut,*display=DocDisplay,*border=DocBorder;
 CEdFindText saved;Bool result;U8*want="two";
 if(mode==2){
  if(!DocGoToLine(NULL,1))m|=1;m|=14;
  if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=16;
  if(Fs->data_heap->used_u8s==before)m|=32;return m;
 }
 d=DocNew("GoTo.DD");d->flags|=DOCF_PLAIN_TEXT;DocLoad(d,"one\ntwo\nthree",13);d->flags&=~DOCF_PLAIN_TEXT;
 MemCpy(&saved,d->find_replace,sizeof(CEdFindText));
 if(mode==1){DocLock(d);target=3;want="three";}
 result=DocGoToLine(d,target);
 if(result)m|=1;
 if(d->cur_entry!=d&&d->cur_entry->y==target-1&&!d->cur_col&&!StrCmp(d->cur_entry->tag,want))m|=2;
 if(d->doc_signature==DOC_SIGNATURE_VAL&&RRBytes(&saved,d->find_replace,sizeof(CEdFindText)))m|=4;
 if(Bt(&d->locked_flags,DOClf_LOCKED)==(mode==1))m|=8;
 if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=16;
 DocUnlock(d);DocDel(d);if(Fs->data_heap->used_u8s==before)m|=32;return m;
}
I64 RRLineCheck(I64 mode){I64 m=RRLine(mode);if(m!=63)throw('GoToLine',TRUE);return m;}
#include "/Kernel/SymbolTypes.HH"
I64 RRMeta()
{
 I64 before=Fs->data_heap->used_u8s,m=0;CHashClass*c=HashFind("CEdLineGoTo",Fs->hash_table,HTT_CLASS);
 CMemberLst*member;CMemberLstMeta*meta;
 if(c){m|=1;if(member=c->member_lst_and_root){
  if(!StrCmp(member->str,"line"))m|=2;
  if(!member->offset&&member->member_class->raw_type==RT_I64)m|=4;
  for(meta=member->meta;meta;meta=meta->next)
   if(!StrCmp(meta->str,"format")&&!StrCmp(meta->user_data,"$$DA,A=\"Go to Line:%d\"$$"))m|=8;
  if(!member->dim.next&&!member->member_class->ptr_stars_cnt)m|=16;
 }}
 if(Fs->data_heap->used_u8s==before)m|=32;return m;
}
