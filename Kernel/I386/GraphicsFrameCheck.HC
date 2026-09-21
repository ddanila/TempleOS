U0 GraphicsFrameThrow(CDC *dc)
{ throw('FrameChk',TRUE); }
I64 GraphicsFrameCheck()
{
  I64 before=Fs->data_heap->used_u8s,caught=0,px=gr.pan_text_x,py=gr.pan_text_y;
  CDC *a=gr.dc,*b=gr.dc2;
  U0 (*saved)(CDC *dc);
  saved=gr.fp_final_scrn_update;
  if(!NativeGraphicsStart || gr.dc!=a || gr.dc2!=b || gr.text_base!=i386_text_base ||
      a->width!=640 || a->height!=480 || b->width!=640 || b->height!=480 ||
      !(a->flags&DCF_ON_TOP) || !(a->flags&DCF_SCRN_BITMAP) ||
      b->flags&DCF_ON_TOP || !(b->flags&DCF_SCRN_BITMAP)) return -1;
  try { NativeGraphicsPresent(&GraphicsFrameThrow); }
  catch { if(Fs->except_ch=='FrameChk') { Fs->catch_except=TRUE; caught++; } }
  if(caught!=1 || Fs->data_heap->used_u8s!=before) return -2;
  gr.fp_final_scrn_update=&GraphicsFrameThrow;
  try { NativeGraphicsPresent; }
  catch { if(Fs->except_ch=='FrameChk') { Fs->catch_except=TRUE; caught++; } }
  gr.fp_final_scrn_update=saved;
  if(caught!=2 || Fs->data_heap->used_u8s!=before) return -3;
  gr.pan_text_x=99; gr.pan_text_y=-99;
  if(!NativeGraphicsPresent || gr.pan_text_x!=7 || gr.pan_text_y!=-7) return -4;
  gr.pan_text_x=px; gr.pan_text_y=py;
  NativeTextBaseRestore;
  if(Fs->data_heap->used_u8s!=before) return -5;
  return 5;
}
