//Diagnostic only: copy actual frame layers in the final callback, then compare
//the same popup after explicit full document refresh. FileMgr stays unchanged.
U8 *pdr_cells,*pdr_pixels,*pdr_overlay;
I64 pdr_state[16];
Bool pdr_take,pdr_full;
CDoc *pdr_doc;
U0 (*pdr_previous)(CDC *dc);
U0 PDRFinal(CDC *dc)
{
  CTask *task;
  if(pdr_previous)(*pdr_previous)(dc);
  if(pdr_take) {
    task=pdr_doc->win_task;
    MemCpy(pdr_cells,gr.text_base,80*60*4);
    MemCpy(pdr_pixels,gr.dc2->body,640*480);
    MemCpy(pdr_overlay,gr.dc->body,640*480);
    pdr_state[0]=pdr_doc->line_start_col;pdr_state[1]=pdr_doc->top_line_num;
    pdr_state[2]=pdr_doc->x;pdr_state[3]=pdr_doc->y;
    pdr_state[4]=task->scroll_x;pdr_state[5]=task->scroll_y;pdr_state[6]=task->scroll_z;
    pdr_state[7]=task->win_left;pdr_state[8]=task->win_right;
    pdr_state[9]=task->win_top;pdr_state[10]=task->win_bottom;
    pdr_state[11]=pdr_doc->flags;pdr_state[12]=pdr_doc->cur_col;
    pdr_state[13]=gr.pan_text_x;pdr_state[14]=gr.pan_text_y;pdr_state[15]=pdr_doc->updates_cnt;
    pdr_take=FALSE;
  }
}
U0 PDRLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 PDRExport(I64 phase,U8 *name,U8 *data,I64 size)
{
  U8 *s=MStrPrint("EXPORT render-%d-%s.bin %X %X\n",phase,name,data,size);
  PDRLog(s);Free(s);
}
U0 PDRClose()
{
  gr.fp_final_scrn_update=pdr_previous;pdr_take=FALSE;
  if(pdr_doc)LBEqu(&pdr_doc->flags,DOCf_DO_FULL_REFRESH,pdr_full);
  Free(pdr_cells);pdr_cells=NULL;Free(pdr_pixels);pdr_pixels=NULL;
  Free(pdr_overlay);pdr_overlay=NULL;pdr_doc=NULL;
}
U0 PDRenderProbe(CDoc *doc)
{
  I64 phase,i;U8 *s;
  pdr_previous=gr.fp_final_scrn_update;pdr_doc=doc;
  pdr_full=Bt(&doc->flags,DOCf_DO_FULL_REFRESH);
  try {
    pdr_cells=MAlloc(80*60*4);pdr_pixels=MAlloc(640*480);pdr_overlay=MAlloc(640*480);
    gr.fp_final_scrn_update=&PDRFinal;
    for(phase=0;phase<3;phase++) {
      if(phase) {
        if(phase==2)LBts(&doc->flags,DOCf_DO_FULL_REFRESH);
        for(i=0;i<3;i++)if(!NativeWindowPresent(FALSE))throw('Frame',TRUE);
      }
      pdr_take=TRUE;
      while(pdr_take)Yield;
      PDRExport(phase,"cells",pdr_cells,80*60*4);
      PDRExport(phase,"pixels",pdr_pixels,640*480);
      PDRExport(phase,"overlay",pdr_overlay,640*480);
      PDRExport(phase,"state",pdr_state,sizeof(pdr_state));
      s=MStrPrint("PICK RENDER %d\n",phase);PDRLog(s);Free(s);
      Sleep(2000);
    }
    PDRClose;
  } catch {PDRClose;}
}
