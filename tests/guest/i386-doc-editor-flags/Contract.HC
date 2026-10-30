I64 DocEditorFlagContract(I64 mode)
{
  CDoc *target=DocNew,*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CDocEntry *tree;U8 *link,*name="C:/FlagTarget.DD",*initial="alpha\nbeta\n";
  I64 flags=EDF_BAIL,mask=0;Bool result,wanted=TRUE;
  target->filename.name[0]=0;tree=DocPrint(target,"$$TR,\"Tree\"$$");
  DocPrint(target,"\nbody\n");DocTop(target);
  if(mode==5)tree->de_flags|=DOCEF_CHECKED_COLLAPSED;
  if(mode==4)flags|=EDF_COLLAPSE;
  if(mode==5)flags|=EDF_UNCOLLAPSE;
  if(mode==1) {flags|=EDF_WAS_WRITE;wanted=FALSE;}
  if(mode==2 || mode==3) {flags=EDF_WAS_WRITE;wanted=FALSE;}
  if(mode==6)wanted=FALSE;
  if(mode>=7) {
    if(mode==8)name="C:/FlagMissing.DD";
    if(mode!=8)FileWrite(name,initial,StrLen(initial));
    link=MStrPrint("FI:%s",name);
    if(mode==8)wanted=FALSE;
    if(mode==9 || mode==10) {flags=EDF_WAS_WRITE;wanted=mode==9;}
  } else if(mode==6) link=MStrPrint("AL:%d,999",target);
  else link=MStrPrint("AI:%d",target);
  FlushMsgs;
  if(mode==2 || mode==9)Msg(MSG_KEY_DOWN,CH_ESC,0);
  if(mode==3 || mode==10)Msg(MSG_KEY_DOWN,CH_SHIFT_ESC,0);
  result=Ed(link,flags);
  if(result==wanted)mask|=1;
  if(target->doc_signature==DOC_SIGNATURE_VAL && !Bt(&target->locked_flags,DOClf_LOCKED))mask|=2;
  if(DocPut==put && DocDisplay==display && DocBorder==border)mask|=4;
  if(mode==4 && !(tree->de_flags&DOCEF_CHECKED_COLLAPSED) ||
     mode==5 && tree->de_flags&DOCEF_CHECKED_COLLAPSED)mask&=~2;
  Free(link);FlushMsgs;DocDel(target);return mask;
}
