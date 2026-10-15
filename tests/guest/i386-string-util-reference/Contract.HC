I64 SUContract(I64 mode)
{
 I64 before=Fs->data_heap->used_u8s,m=0;
 U8 src[128],dst[128],*result=NULL;
 CDoc*put=DocPut,*display=DocDisplay,*border=DocBorder;
 StrCpy(dst,"sentinel");
 if(mode==0){if(StrOcc(NULL,'a')==0&&StrOcc("banana",'a')==3&&StrOcc("banana",'x')==0)m|=1;}
 else if(mode==1){
  StrCpy(src,"alpha;beta/gamma");result=StrFirstRem(src,";/",dst);
  if(result==dst&&!StrCmp(dst,"alpha")&&!StrCmp(src,"beta/gamma"))m|=1;
 }
 else if(mode==2){
  StrCpy(src,"alpha");result=StrFirstRem(src,";/",dst);
  if(result==dst&&!StrCmp(dst,"alpha")&&!*src)m|=1;
 }
 else if(mode==3){
  StrCpy(src,"A/B/note.HC");result=StrLastRem(src,"/",dst);
  if(result==dst&&!StrCmp(dst,"note.HC")&&!StrCmp(src,"A/B"))m|=1;
 }
 else if(mode==4){
  StrCpy(src,"note.HC");result=StrLastRem(src,"/",dst);
  if(result==dst&&!StrCmp(dst,"note.HC")&&!*src)m|=1;
 }
 else if(mode==5){
  StrCpy(src,"alpha;beta");result=StrFirstRem(src,";");
  if(!result&&!StrCmp(src,"beta")){result=StrLastRem(src,"/");if(!result&&!*src)m|=1;}
 }
 else if(mode==6){
  StrCpy(src,"A/B;C");
  if(StrFirstOcc(src,";/")==src+1&&StrLastOcc(src,";/")==src+3&&
      !StrFirstOcc(src,"x")&&!StrLastOcc(src,"x"))m|=1;
 }
 else if(mode==7){
  StrCpy(src,"\t  alpha\x01 beta \r\n");
  result=StrUtil(src,SUF_REM_LEADING|SUF_REM_TRAILING|SUF_REM_CTRL_CHARS);
  if(result==src&&!StrCmp(src,"alpha beta"))m|=1;
 }
 else if(mode==8){
  result=MStrUtil("\t alpha\t beta \n",SUF_REM_LEADING|SUF_REM_TRAILING|SUF_SINGLE_SPACE|SUF_TO_UPPER);
  if(result&&!StrCmp(result,"ALPHA BETA"))m|=1;Free(result);
 }
 else if(mode==9){
  result=MStrUtil("a\tb",SUF_T2S);
  if(result&&!StrCmp(result,"a       b"))m|=1;Free(result);
 }
 else if(mode==10){
  result=MStrUtil("\talpha",SUF_SCALE_INDENT,0.25);
  if(result&&!StrCmp(result,"  alpha"))m|=1;Free(result);
 }
 if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=2;
 if(Fs->data_heap->used_u8s==before)m|=4;
 return m;
}
I64 SUCheck(I64 mode){I64 m=SUContract(mode);if(m!=7)throw('StrUtil',TRUE);return m;}
