Bool SFBytes(U8*a,U8*b,I64 n){I64 i;for(i=0;i<n;i++)if(a[i]!=b[i])return FALSE;return TRUE;}
I64 SFString()
{
 I64 before=Fs->data_heap->used_u8s,m=0;U8*a="one cat",*b="xxcat",*c="scat cat_",*d="cat_ cat",*e="scatter cat_ cat",*f="xy";
 if(StrFind("cat",a)==a+4&&!StrFind("dog",a))m|=1;
 if(StrFind("CAT",b,1)==b+2)m|=2;
 if(StrFind("cat",c,2)==c+5)m|=4;
 if(StrFind("cat",d,4)==d+5&&StrFind("cat",e,6)==e+13)m|=8;
 if(StrFind("",f)==f&&StrFind("aa","aaa"))m|=16;
 if(Fs->data_heap->used_u8s==before)m|=32;return m;
}
CDoc *SFDoc(U8*s){CDoc*d=DocNew("Search.DD");d->flags|=DOCF_PLAIN_TEXT;DocLoad(d,s,StrLen(s));d->flags&=~DOCF_PLAIN_TEXT;DocTop(d);return d;}
I64 SFNext(I64 mode)
{
 I64 before=Fs->data_heap->used_u8s,m=0,col=5;CDoc*put=DocPut,*display=DocDisplay,*d=SFDoc("cat scatter CAT cat_ cat\ncat");
 CDocEntry*first=d->head.next,*last=d->head.last,*want=first;CEdFindText saved;
 StrCpy(d->find_replace->find_text,"cat");d->find_replace->match_case=TRUE;d->find_replace->scan_fwd=TRUE;
 d->find_replace->scan_sel_text=FALSE;d->find_replace->whole_labels=FALSE;
 if(mode==1){d->find_replace->match_case=FALSE;d->find_replace->whole_labels=TRUE;col=12;}
 if(mode==2){d->find_replace->whole_labels=TRUE;col=21;}
 if(mode==3){d->find_replace->scan_fwd=FALSE;d->cur_col=21;col=16;}
 if(mode==4){StrCpy(d->find_replace->find_text,"dog");col=0;}
 if(mode==5){EdSelAll(d,FALSE);last->type|=DOCET_SEL;d->find_replace->scan_sel_text=TRUE;want=last;col=0;}
 if(mode==6){first->de_flags|=DOCEF_FILTER_SKIP;want=last;col=0;}
 if(mode==7)DocLock(d);
 MemCpy(&saved,d->find_replace,sizeof(CEdFindText));EdFindNext(d);
 if(d->cur_entry==want&&d->cur_col==col)m|=1;
 if(SFBytes(&saved,d->find_replace,sizeof(CEdFindText)))m|=2;
 if(!StrCmp(first->tag,"cat scatter CAT cat_ cat")&&!StrCmp(last->tag,"cat"))m|=4;
 if(Bt(&d->locked_flags,DOClf_LOCKED)==(mode==7))m|=8;
 if(DocPut==put&&DocDisplay==display)m|=16;
 DocUnlock(d);DocDel(d);if(Fs->data_heap->used_u8s==before)m|=32;return m;
}
I64 SFPair(I64 mode)
{
 I64 before=Fs->data_heap->used_u8s,m=0,col=6;U8*text="{A{B}C}";Bool result,expected=TRUE;
 CDoc*put=DocPut,*display=DocDisplay,*d;CDocEntry*first,*last,*want;
 if(mode==2){text="ABC";col=1;expected=FALSE;}
 if(mode==3){text="{A::B}";col=2;expected=FALSE;}
 if(mode==4){text="{A\n{B}\nC}";col=1;}
 d=SFDoc(text);first=d->head.next;last=d->head.last;want=first;
 if(mode==1){d->cur_col=6;col=0;DocLock(d);}
 if(mode==2)d->cur_col=1;
 if(mode==4)want=last;
 if(mode==1)result=EdFindPaired(d,'}','{',FALSE);else result=EdFindPaired(d,'{','}',TRUE,mode==3);
 if(result==expected)m|=1;if(d->cur_entry==want&&d->cur_col==col)m|=2;
 if(mode!=4&&!StrCmp(first->tag,text)||mode==4&&!StrCmp(first->tag,"{A")&&!StrCmp(last->tag,"C}"))m|=4;
 if(Bt(&d->locked_flags,DOClf_LOCKED)==(mode==1))m|=8;
 if(DocPut==put&&DocDisplay==display)m|=16;
 DocUnlock(d);DocDel(d);if(Fs->data_heap->used_u8s==before)m|=32;return m;
}
I64 SFFunction(I64 mode)
{
 I64 before=Fs->data_heap->used_u8s,m=0,n=0,selected=0;Bool forward,back;
 CDoc*put=DocPut,*display=DocDisplay,*d=SFDoc("{A{B}C}\n{D}");CDocEntry*e,*first=d->head.next,*last=d->head.last;
 if(mode)DocLock(d);
 EdSelAll(d,TRUE);for(e=d->head.next;e!=d;e=e->next){n++;if(e->type&DOCET_SEL)selected++;}
 EdSelAll(d,FALSE);if(n==selected){selected=0;for(e=d->head.next;e!=d;e=e->next)if(e->type&DOCET_SEL)selected++;if(!selected)m|=1;}
 d->cur_entry=first;d->cur_col=1;forward=EdGoToFun(d,TRUE,FALSE)&&d->cur_entry==first&&d->cur_col==6;
 back=EdGoToFun(d,FALSE,FALSE)&&d->cur_entry==first&&!d->cur_col;if(forward&&back)m|=2;
 EdSelFun(d);if(first->type&DOCET_SEL&&!(last->type&DOCET_SEL)&&!StrCmp(first->tag,"{A{B}C}")&&!StrCmp(last->tag,"{D}"))m|=4;
 if(Bt(&d->locked_flags,DOClf_LOCKED)==(mode!=0))m|=8;
 if(DocPut==put&&DocDisplay==display)m|=16;
 DocUnlock(d);DocDel(d);if(Fs->data_heap->used_u8s==before)m|=32;return m;
}
I64 SFCheck(I64 group,I64 mode){I64 m;if(!group)m=SFString;else if(group==1)m=SFNext(mode);else if(group==2)m=SFPair(mode);else m=SFFunction(mode);if(m!=63)throw('EdSearch',TRUE);return m;}
