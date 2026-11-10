U0 ScalarReport(U8*s){while(*s)OutU8(0xE9,*s++);}
U0 ScalarCapture()
{
  CDoc *doc=DocPut;
  CDocEntry *e=doc->head.last;
  I64 *v=CAlloc(1408),n,i=0,j,k,length;
  U8 *data,*line;
  v[0]=(Fs+0)(U64);v[1]=Fs->answer;v[2]=Fs->answer_type;
  v[3]=doc->flags;v[4]=doc->x;v[5]=doc->y;v[6]=doc->cur_col;
  v[7]=Fs->win_left;v[8]=Fs->win_right;v[9]=Fs->win_top;v[10]=Fs->win_bottom;
  v[11]=Fs->horz_scroll.pos;v[12]=doc->line_start_col;v[13]=doc->top_line_num;
  v[14]=Fs->win_width;v[15]=doc->win_task==Fs;
  while(e!=doc && i<20) {
    k=16+i*8;v[k]=e->type;v[k+1]=e->de_flags;v[k+2]=e->x;
    v[k+3]=e->y;v[k+4]=e->min_col;v[k+5]=e->max_col;
    if(e->type_u8==DOCT_TEXT && e->tag) {
      length=StrLen(e->tag);v[k+7]=length;
      for(j=0;j<8 && j<length;j++)v[k+6]|=e->tag[j](U64)<<(j*8);
    }
    e=e->last;i++;
  }
  line=MStrPrint("EXPORT scalar-entries.bin %X %X\n",v,1408);ScalarReport(line);Free(line);
  data=DocSave(doc,&n);
  if(n<=0 || n>65536)throw('ScalSize',TRUE);
  line=MStrPrint("EXPORT scalar-document.DD %X %X\n",data,n);ScalarReport(line);Free(line);
  ScalarReport("DONE scalar document capture\n");
}
ScalarCapture;
