#include "/Kernel/I386/GraphicsFramePattern.HC"
I64 graphics_frame_ticks,graphics_frame_heap_bytes,graphics_frame_baseline;
U0 GraphicsFrameDemoDraw(CDC *dc)
{
  GraphicsFrameDraw(dc);
  graphics_frame_heap_bytes=Fs->data_heap->used_u8s-graphics_frame_baseline;
}
U0 GraphicsFrameMetric(I64 value)
{
  I64 i,digit;
  for(i=60;i>=0;i-=4) {
    digit=(value>>i)&15;
    if(digit<10) OutU8(0xE9,'0'+digit); else OutU8(0xE9,'A'+digit-10);
  }
}

I64 GraphicsFrameDemo(I64 mode=0)
{//Ctrl-Alt-C restores the console and the original persistent/text surfaces.
  U8 *saved=NULL,*saved_cells=NULL;
  U0 (*saved_final)(CDC *dc);
  I64 before=Fs->data_heap->used_u8s,px=gr.pan_text_x,py=gr.pan_text_y,start;
  Bool hc=gr.hide_col,hr=gr.hide_row;
  saved_final=gr.fp_final_scrn_update;
  if(!NativeGraphicsStart) return -1;
  try {
    saved=MAlloc(307200); MemCpy(saved,gr.dc->body,307200);
    saved_cells=MAlloc(19200); MemCpy(saved_cells,gr.text_base,19200);
    GraphicsFramePattern(gr.text_base,gr.dc);
    gr.pan_text_x=gr.pan_text_y=0; gr.hide_col=gr.hide_row=FALSE;
    if(mode==2) { gr.pan_text_x=3; gr.pan_text_y=-2; }
    if(mode==3) { gr.pan_text_x=-7; gr.pan_text_y=7; gr.hide_col=gr.hide_row=TRUE; }
    gr.fp_final_scrn_update=&GraphicsFrameFinal;
    graphics_frame_baseline=before; start=cnts.jiffies;
    if(!NativeGraphicsPresent(&GraphicsFrameDemoDraw,mode&1)) throw('Frame',TRUE);
    graphics_frame_ticks=cnts.jiffies-start;
    OutU8(0xE9,'G'); OutU8(0xE9,'F'); OutU8(0xE9,'R'); OutU8(0xE9,'A'); OutU8(0xE9,'M'); OutU8(0xE9,'E'); OutU8(0xE9,32);
    GraphicsFrameMetric(graphics_frame_ticks); OutU8(0xE9,32);
    GraphicsFrameMetric(graphics_frame_heap_bytes); OutU8(0xE9,10);
    OutU8(0xE9,64);
    while(TRUE) {}
  } catch {
    if(saved) MemCpy(gr.dc->body,saved,307200);
    if(saved_cells) MemCpy(gr.text_base,saved_cells,19200);
    Free(saved_cells); Free(saved);
    gr.fp_final_scrn_update=saved_final;
    gr.pan_text_x=px; gr.pan_text_y=py; gr.hide_col=hc; gr.hide_row=hr;
    NativeTextBaseRestore;
    if(Fs->except_ch=='Break') Fs->catch_except=TRUE;
  }
  return Fs->data_heap->used_u8s==before;
}
