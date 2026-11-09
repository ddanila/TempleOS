U8 gp_bytes[400000];I64 gp_size;Bool gp_done;
U0 GPLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 GPChild(U8 *)
{
  CDC *dc=DCNew(32,32);
  GrFillCircle(dc,16,16,0,9);DCDel(dc);gp_done=TRUE;
  while(TRUE)Yield;
}
U0 GPProbe()
{
  CTask *task;CDC *dc;I64 i,k,n,metadata[7],deadline=cnts.jiffies+20000;
  U8 *s;
  s=MStrPrint("PEN CACHE BEFORE %d\n",gr.pen_brushes[3]!=NULL);GPLog(s);Free(s);
  gp_size=0;gp_done=FALSE;task=Spawn(&GPChild,NULL,"Pen init",-1,Fs,131072);
  while(!gp_done&&cnts.jiffies<deadline)Yield;
  if(!gp_done)throw('PenWait',TRUE);
  if(!Kill(task))throw('PenKill',TRUE);
  Sleep(100);
  MemCpy(gp_bytes,gr.circle_lo,sizeof(gr.circle_lo));gp_size+=sizeof(gr.circle_lo);
  MemCpy(gp_bytes+gp_size,gr.circle_hi,sizeof(gr.circle_hi));gp_size+=sizeof(gr.circle_hi);
  for(i=0;i<GR_PEN_BRUSHES_NUM;i++)for(k=0;k<4;k++) {
    switch(k) {
      case 0:dc=gr.pen_brushes[i];break;
      case 1:dc=gr.collision_pen_brushes[i];break;
      case 2:dc=gr.even_pen_brushes[i];break;
      case 3:dc=gr.odd_pen_brushes[i];break;
    }
    if(!dc||dc->dc_signature!=DCS_SIGNATURE_VAL)throw('PenGone',TRUE);
    metadata[0]=i;metadata[1]=k;metadata[2]=dc->width;
    metadata[3]=dc->width_internal;metadata[4]=dc->height;
    metadata[5]=TaskValidate(dc->mem_task);metadata[6]=dc->mem_task!=task;
    n=dc->width_internal*dc->height;
    if(gp_size+sizeof(metadata)+n>sizeof(gp_bytes))throw('PenDump',TRUE);
    MemCpy(gp_bytes+gp_size,metadata,sizeof(metadata));gp_size+=sizeof(metadata);
    MemCpy(gp_bytes+gp_size,dc->body,n);gp_size+=n;
  }
  s=MStrPrint("EXPORT graphics-pens.bin %X %X\n",gp_bytes,gp_size);GPLog(s);Free(s);
  GPLog("GRAPHICS PENS DONE\n");
}
