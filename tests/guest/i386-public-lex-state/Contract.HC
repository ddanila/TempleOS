U0 LSLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 LSCheck()
{
  CCmpCtrl *cc=NULL;CDoc *d=DocNew,*put=DocPut;
  U32 bitmap[16];I64 old_lines=cmp.compiled_lines,mask=0,size;
  U8 *bytes=NULL,*s;Bool raw=Raw(OFF);
  MemCpy(bitmap,char_bmp_printable,sizeof(bitmap));Fs->put_doc=d;
  try {
    cc=CmpCtrlNew(StrNew("A\nB"));cc->opts|=OPTF_ECHO;
    cmp.compiled_lines=1000;
    LBtr(char_bmp_printable,'B');
    if(LexGetChar(cc)=='A' && LexGetChar(cc)=='\n' && LexGetChar(cc)=='B' &&
       LexGetChar(cc)==TK_EOF)mask|=1;
    if(cmp.compiled_lines==1001)mask|=2;
    if(cc->lex_include_stk->line_num==2)mask|=4;
    bytes=DocSave(d,&size);
    s=MStrPrint("EXPORT lex-state-echo.DD %X %X\n",bytes,size);LSLog(s);Free(s);Sleep(1000);
    if(size==3 && bytes[0]=='A' && bytes[1]=='\n' && bytes[2]==CH_CURSOR)mask|=8;
    CmpCtrlDel(cc);cc=NULL;Free(bytes);bytes=NULL;
    MemCpy(char_bmp_printable,bitmap,sizeof(bitmap));
    if(!MemCmp(char_bmp_printable,bitmap,sizeof(bitmap)))mask|=16;
    if(DocPut==d)mask|=32;
  } catch {
    if(cc)CmpCtrlDel(cc);Free(bytes);Fs->put_doc=put;DocDel(d);Raw(raw);
    MemCpy(char_bmp_printable,bitmap,sizeof(bitmap));cmp.compiled_lines=old_lines;
  }
  Fs->put_doc=put;DocDel(d);Raw(raw);cmp.compiled_lines=old_lines;
  s=MStrPrint("EXPORT lex-state-mask.bin %X 8\n",&mask);LSLog(s);Free(s);
  LSLog("PUBLIC LEX STATE DONE\n");Sleep(1000);
}
