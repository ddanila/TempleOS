CTask *graphics_owner;
CDC *graphics_persistent,*graphics_frame;
U8 *graphics_planes;
Bool graphics_presenting;
Bool NativeGraphicsReady()
{
  return graphics_owner==Fs && graphics_persistent && graphics_frame && graphics_planes &&
    gr.dc==graphics_persistent && gr.dc2==graphics_frame && gr.text_base==i386_text_base;
}
Bool NativeGraphicsStart()
{//Commit both real working contexts only after all allocations succeed.
  CDC *persistent=NULL,*frame=NULL;
  U8 *planes=NULL;
  if(graphics_owner) return NativeGraphicsReady;
  if(gr.dc || gr.dc2 || gr.text_base) return FALSE;
  try {
    persistent=DCNew(640,480); frame=DCNew(640,480);
    persistent->flags|=DCF_SCRN_BITMAP|DCF_ON_TOP;
    frame->flags|=DCF_SCRN_BITMAP;
    DCFill(persistent,TRANSPARENT);
    planes=MAlloc(153600);
  } catch { Free(planes); DCDel(frame); DCDel(persistent); }
  KernelLog("GRAPHICS BUFFERS ");
  KernelHex(MSize2(persistent)+MSize2(persistent->body)+MSize2(persistent->r)+
    MSize2(frame)+MSize2(frame->body)+MSize2(frame->r)+MSize2(planes));
  KernelLog("\n");
  graphics_planes=planes; graphics_owner=Fs;
  gr.dc=graphics_persistent=persistent; gr.dc2=graphics_frame=frame;
  gr.text_base=i386_text_base; gr.scrn_zoom=1;
  Fs->win_left=0; Fs->win_right=79;
  Fs->win_top=0; Fs->win_bottom=59;
  LBts(&Fs->task_flags,TASKf_TASK_LOCK);
  WinDerivedValsUpdate(Fs);
  LBtr(&Fs->task_flags,TASKf_TASK_LOCK);
  return TRUE;
}
Bool NativeGraphicsPresent(U0 (*draw)(CDC *dc)=NULL,Bool blink=FALSE)
{//Single console owner; callbacks draw over text before the persistent overlay.
  Bool result=FALSE;
  if(!NativeGraphicsReady || graphics_presenting ||
      gr.dc->dc_signature!=DCS_SIGNATURE_VAL || gr.dc2->dc_signature!=DCS_SIGNATURE_VAL ||
      gr.dc->width_internal!=640 || gr.dc->height!=480 ||
      gr.dc2->width_internal!=640 || gr.dc2->height!=480 ||
      !gr.dc->body || !gr.dc2->body) return FALSE;
  gr.pan_text_x=MinI64(7,MaxI64(-7,gr.pan_text_x));
  gr.pan_text_y=MinI64(7,MaxI64(-7,gr.pan_text_y));
  graphics_presenting=TRUE;
  try {
    GraphicsFrameCore(gr.dc2,gr.dc,gr.text_base,text.font,blink,
      gr.pan_text_x,gr.pan_text_y,gr.hide_col,gr.hide_row,draw,gr.fp_final_scrn_update);
    GraphicsPlanarCore(graphics_planes,gr.dc2->body);
    result=I386VgaRows(graphics_planes,0,480);
  } catch { graphics_presenting=FALSE; }
  graphics_presenting=FALSE;
  return result;
}
