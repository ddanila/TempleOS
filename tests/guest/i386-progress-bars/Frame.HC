I64 progress_final_calls;
U0 ProgressFinalProbe(CDC *dc){progress_final_calls++;dc->body[0]=RED;}
I64 ProgressFrameContract()
{
  CProgress saved[4];I64 mask=0,updates;
  U0 (*saved_final)(CDC *dc);
  saved_final=gr.fp_final_scrn_update;
  MemCpy(saved,sys_progresses,sizeof(saved));MemSet(sys_progresses,0,sizeof(saved));
  updates=winmgr.updates;sys_progresses[0].max=100;sys_progresses[0].val=50;
  Sleep(1500);
  if(winmgr.updates>updates && gr.dc2->body[170*gr.dc2->width_internal+80]==BLACK &&
     gr.dc2->body[180*gr.dc2->width_internal+100]==LTGREEN &&
     gr.dc2->body[180*gr.dc2->width_internal+350]==BLACK)mask|=1;
  if(NativeGraphicsPresent && gr.dc2->body[170*gr.dc2->width_internal+80]==BLACK &&
     gr.dc2->body[180*gr.dc2->width_internal+100]==LTGREEN &&
     gr.dc2->body[180*gr.dc2->width_internal+350]==BLACK)mask|=2;
  progress_final_calls=0;gr.fp_final_scrn_update=&ProgressFinalProbe;
  if(NativeGraphicsPresent && progress_final_calls && gr.dc2->body[0]==RED &&
     gr.dc2->body[180*gr.dc2->width_internal+100]==LTGREEN)mask|=4;
  gr.fp_final_scrn_update=saved_final;
  MemCpy(sys_progresses,saved,sizeof(saved));return mask;
}
