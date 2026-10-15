class FPEmpty { I64 opaque; };
class FPMixed {
 U32 guard_before;
 I32 number format "$$DA-TRM,A=\"N:%d\"$$\n";
 U8 name[8] format "$$DA-P,A=\"S:%s\"$$\n";
 Bool yes format "$$CB,\"Check\"$$\n";
 U8 *dynamic format "$$DA+M,A=\"D:%s\"$$\n";
 U32 guard_after;
};
class FPNumeric { I64 number format "$$DA-TRM,A=\"N:%d\"$$\n"; };
I64 fp_mode,fp_seen,fp_mask,fp_heap_delta[7],fp_root_delta[7],fp_bound[7],fp_seen_each[7],fp_name_len[7],fp_name_raw[7],fp_windows[7],fp_rect[28];
I64 fp_numeric_value[7],fp_values_mask[7],fp_typed[7];
U8 *fp_object;Bool fp_good;
Bool FPObserve(I64 ch,I64 sc)
{
 CDoc*d=DocDisplay;CDocEntry*e;I64 mask=0,want=15;FPMixed*p=fp_object;FPNumeric*n=fp_object;
 if(!d||d->desc!='Form')return FALSE;
 if(fp_mode>=5)want=1;else if(fp_mode==2)want=63;else if(fp_mode==4)want=127;
 for(e=d->head.next;e!=d;e=e->next){
  if(fp_mode>=5){if(e->type_u8==DOCT_DATA&&e->data==&n->number&&e->raw_type==RT_I64){
    mask|=1;
    if(ch==CH_ESC||ch==CH_SHIFT_ESC)fp_typed[fp_mode]=!StrCmp(e->tag,"N:42");
   }}
  else {
   if(e->data==p->name){fp_name_len[fp_mode]=e->len;fp_name_raw[fp_mode]=e->raw_type;}
   if(e->type_u8==DOCT_DATA&&e->data==&p->number&&e->raw_type==RT_I32)mask|=1;
   if(e->type_u8==DOCT_DATA&&e->data==p->name&&e->raw_type==RT_PTR&&e->len==7)mask|=2;
   if(e->type_u8==DOCT_CHECK_BOX&&e->data==&p->yes&&e->raw_type==RT_I8)mask|=4;
   if(e->type_u8==DOCT_DATA&&e->de_flags&DOCEF_REMALLOC_DATA&&e->user_data==&p->dynamic&&e->data==p->dynamic)mask|=8;
   if(e->tag&&!StrCmp(e->tag,"Header"))mask|=16;
   if(e->tag&&!StrCmp(e->tag,"Footer"))mask|=32;
  }
 }
 if(fp_mode==4&&d->flags&DOCF_SIZE_MIN)mask|=64;
 fp_rect[fp_mode*4]=Fs->win_left;fp_rect[fp_mode*4+1]=Fs->win_right;fp_rect[fp_mode*4+2]=Fs->win_top;fp_rect[fp_mode*4+3]=Fs->win_bottom;
 fp_seen++;fp_mask=mask;fp_good=fp_good&&((mask&want)==want);
 return FALSE;
}
I64 FPContract(I64 mode)
{
 I64 before=Fs->data_heap->used_u8s,root_before=adam_task->data_heap->used_u8s,m=0;
 CDoc*put=DocPut,*display=DocDisplay,*border=DocBorder;
 U8*end=Fs->task_end_cb,title[STR_LEN];I64 border_src=Fs->border_src,attr=Fs->text_attr,title_src=Fs->title_src;
 I64 left=Fs->win_left,right=Fs->win_right,top=Fs->win_top,bottom=Fs->win_bottom;
 CKeyDevEntry*first=keydev.put_key_head.next,*last=keydev.put_key_head.last,*hook;
 FPMixed data;FPNumeric numeric;FPEmpty empty;Bool result,window_ok,expected=mode==2||mode==3||mode==5;
 MemSet(&data,0,sizeof(FPMixed));data.guard_before=0x12345678;data.guard_after=0xA5A5A5A5;
 data.number=-12345;StrCpy(data.name,"abc");data.yes=TRUE;data.dynamic=StrNew("old");numeric.number=12;empty.opaque=99;
 StrCpy(title,Fs->task_title);fp_mode=mode;fp_seen=fp_mask=0;fp_typed[mode]=0;fp_good=TRUE;fp_object=&data;if(mode>=5)fp_object=&numeric;
 hook=KeyDevAdd(&FPObserve,NULL,1);FlushMsgs;
 if(mode>=5){Msg(MSG_KEY_DOWN,'4',0);Msg(MSG_KEY_DOWN,'2',0);}
 if(mode==4||mode==6)Msg(MSG_KEY_DOWN,CH_SHIFT_ESC,0);else Msg(MSG_KEY_DOWN,CH_ESC,0);
 if(mode==0)result=DocForm(&data,"FPDoesNotExist");
 else if(mode==1)result=DocForm(&empty,"FPEmpty");
 else if(mode==3)result=DocForm(&data);
 else if(mode==4)result=DocForm(&data,"FPMixed",DOF_SIZE_MIN,"Header\n","Footer\n");
 else if(mode>=5)result=DocForm(&numeric,"FPNumeric");
 else result=DocForm(&data,"FPMixed",0,"Header\n","Footer\n");
 KeyDevRem(hook);FlushMsgs;
 if((mode<2&&!fp_seen||mode>=2&&fp_seen&&fp_good)&&(mode<5||fp_typed[mode]))m|=1;
 fp_numeric_value[mode]=numeric.number;fp_values_mask[mode]=0;
 if(result==expected)fp_values_mask[mode]|=1;if(data.number==-12345)fp_values_mask[mode]|=2;
 if(!StrCmp(data.name,"abc"))fp_values_mask[mode]|=4;if(data.yes)fp_values_mask[mode]|=8;
 if(!StrCmp(data.dynamic,"old"))fp_values_mask[mode]|=16;
 if(mode==5&&numeric.number==42||mode!=5&&numeric.number==12)fp_values_mask[mode]|=32;
 if(result==expected&&data.number==-12345&&!StrCmp(data.name,"abc")&&data.yes&&!StrCmp(data.dynamic,"old")&&(mode==5&&numeric.number==42||mode!=5&&numeric.number==12))m|=2;
 if(DocPut==put&&DocDisplay==display&&DocBorder==border&&Fs->task_end_cb==end&&Fs->border_src==border_src)m|=4;
 if(data.guard_before==0x12345678&&data.guard_after==0xA5A5A5A5&&empty.opaque==99&&keydev.put_key_head.next==first&&keydev.put_key_head.last==last)m|=8;
 window_ok=Fs->win_left==left&&Fs->win_right==right&&Fs->win_top==top&&Fs->win_bottom==bottom;
 if(mode==4)window_ok=Fs->win_left==fp_rect[mode*4]&&Fs->win_right==fp_rect[mode*4+1]&&Fs->win_top==fp_rect[mode*4+2]&&Fs->win_bottom==fp_rect[mode*4+3]&&(Fs->win_right<right||Fs->win_bottom<bottom);
 if(Fs->text_attr==attr&&Fs->title_src==title_src&&!StrCmp(Fs->task_title,title)&&window_ok)m|=16;
 fp_bound[mode]=fp_mask;fp_seen_each[mode]=fp_seen;fp_windows[mode]=0;
 if(Fs->win_left==left)fp_windows[mode]|=1;if(Fs->win_right==right)fp_windows[mode]|=2;if(Fs->win_top==top)fp_windows[mode]|=4;if(Fs->win_bottom==bottom)fp_windows[mode]|=8;
 if(Fs->text_attr==attr)fp_windows[mode]|=16;if(Fs->title_src==title_src)fp_windows[mode]|=32;if(!StrCmp(Fs->task_title,title))fp_windows[mode]|=64;
 if(mode==4){WinHorz(left,right);WinVert(top,bottom);} //Restore fixture window only after observing original sizing.
 Free(data.dynamic);fp_object=NULL;
 fp_heap_delta[mode]=Fs->data_heap->used_u8s-before;fp_root_delta[mode]=adam_task->data_heap->used_u8s-root_before;
 if(!fp_heap_delta[mode])m|=32;
 return m;
}
I64 FPCheck(I64 mode)
{
 I64 m=FPContract(mode);U8*s,*p;
 if(m!=63){
  s=MStrPrint("FORM FAILURE %d %d %d %d %d %d\n",mode,m,fp_bound[mode],fp_values_mask[mode],fp_numeric_value[mode],fp_heap_delta[mode]);
  p=s;while(*p)OutU8(0xE9,*p++);Free(s);throw('ClsForm',TRUE);
 }
 return m;
}

I64 FPYieldControl(){I64 before=adam_task->data_heap->used_u8s;Refresh(2,TRUE);Yield;return adam_task->data_heap->used_u8s-before;}
