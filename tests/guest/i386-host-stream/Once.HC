while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
U0 HSLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 hs_mask=0;
U0 HSProbe()
{
  U8 *code=NULL,*again=NULL,*line,*saved;I64 saved_size;
  I64 size=0,again_size=0,errors=0,flags,mask=CCF_TARGET_I386|CCF_TARGET_HOST_CONST;
  CCmpCtrl *before=Fs->last_cc,*cc;
  Bool caught=FALSE;
  U8 *source="#include \"/Kernel/Types.HH\";#exe{StreamPrint(\"I64 HSHostSize=%d;I64 HSHostCall=%d;\",sizeof(U8 *),StrLen(\"host64\"));}"
    "U8 *HSTargetPointer=0;U32 HSTargetSize(){return sizeof(U8 *);}";
  hs_mask=0;
  try {code=CmpI386Module(source,&size,&errors);}
  catch {Fs->catch_except=TRUE;}
  saved=DocSave(DocPut,&saved_size);
  line=MStrPrint("EXPORT host-stream-log.DD %X %X\n",saved,saved_size);HSLog(line);Free(line);
  line=MStrPrint("EXPORT host-stream-source.HC %X %X\n",source,StrLen(source));HSLog(line);Free(line);
  if(code&&!errors)hs_mask|=1;
  if(Fs->last_cc==before)hs_mask|=2;
  if(code) {
    cc=CmpCtrlNew("#exe{throw('HostTry');}",CCF_DONT_FREE_BUF|CCF_AOT_COMPILE|mask);
    QueIns(cc,Fs->last_cc);flags=cc->flags;
    try {Lex(cc);}
    catch {if(Fs->except_ch=='HostTry'){caught=TRUE;Fs->catch_except=TRUE;}}
    if((cc->flags&mask)==(flags&mask))hs_mask|=4;
    QueRem(cc);CmpCtrlDel(cc);
    if(caught&&Fs->last_cc==before)hs_mask|=8;
    again=CmpI386Module(source,&again_size,&errors);
    if(again&&!errors&&size==again_size&&!MemCmp(code,again,size)&&Fs->last_cc==before)hs_mask|=16;
    line=MStrPrint("EXPORT host-stream.t32m %X %X\n",code,size);HSLog(line);Free(line);
  }
  line=MStrPrint("EXPORT host-stream-mask.bin %X 8\n",&hs_mask);HSLog(line);Free(line);
  HSLog("DONE host stream\n");
}
HSProbe;
