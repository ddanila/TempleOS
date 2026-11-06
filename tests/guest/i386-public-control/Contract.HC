U0 PCLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 PCCheck()
{
  I64 v[12],used=Fs->data_heap->used_u8s;
  U8 *buffer=StrNew("owned"),*s;
  CCmpCtrl *cc=CmpCtrlNew(buffer);
  v[0]=cc && !cc->flags && cc->next==cc && cc->last==cc;
  v[1]=cc->cur_buf_ptr==buffer && cc->lex_include_stk->buf==buffer;
  v[2]=cc->htc.glbl_hash_table==Fs->hash_table && cc->htc.define_hash_table==Fs->hash_table;
  v[3]=blkdev.tmp_filename && cc->lex_include_stk->full_name &&
    cc->lex_include_stk->line_num==1 &&
    !StrCmp(cc->lex_include_stk->full_name,blkdev.tmp_filename);
  v[4]=CmpCtrlSize(cc)==MSize2(cc)+MSize2(cc->lex_include_stk)+
    MSize2(cc->lex_include_stk->full_name)+MSize2(buffer);
  CmpCtrlDel(cc);v[5]=Fs->data_heap->used_u8s==used;
  buffer=StrNew("borrowed");cc=CmpCtrlNew(buffer,CCF_DONT_FREE_BUF);
  v[6]=cc->cur_buf_ptr==buffer && cc->flags==CCF_DONT_FREE_BUF &&
    CmpCtrlSize(cc)==MSize2(cc)+MSize2(cc->lex_include_stk)+MSize2(cc->lex_include_stk->full_name);
  CmpCtrlDel(cc);v[7]=!StrCmp(buffer,"borrowed") && MSize(buffer)>=9;Free(buffer);
  cc=CmpCtrlNew(,CCF_PMT);
  v[8]=cc->flags==CCF_PMT && cc->cur_buf_ptr && MSize(cc->cur_buf_ptr)>=8 && !cc->cur_buf_ptr[0];
  CmpCtrlDel(cc);
  cc=CmpCtrlNew(,CCF_KEEP_AT_SIGN);
  v[9]=cc->flags==CCF_KEEP_AT_SIGN && !Bt(cc->char_bmp_alpha_numeric,'@');CmpCtrlDel(cc);
  cc=CmpCtrlNew(,,"::/PublicControl.HC");s=FileNameAbs("::/PublicControl.HC");
  v[10]=!StrCmp(cc->lex_include_stk->full_name,s) && Bt(cc->char_bmp_alpha_numeric,'@');
  Free(s);CmpCtrlDel(cc);v[11]=Fs->data_heap->used_u8s==used;
  s=MStrPrint("EXPORT public-control.bin %X %X\n",v,sizeof(v));PCLog(s);Free(s);
  PCLog("PUBLIC CONTROL DONE\n");Sleep(1000);
}
