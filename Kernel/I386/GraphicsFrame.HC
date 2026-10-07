CDC *graphics_persistent,*graphics_frame;
U8 *graphics_planes[4];
U16 *graphics_zbuffer,*graphics_uncovered;
Bool graphics_presenting;
#include "/Kernel/GraphicsWindowReserveCore.HC"
U8 *NativeGraphicsWindowAlloc(U8 *context,I64 bytes)
{
  U8 *result=NULL;
  try { result=CAlloc(bytes); }
  catch { if(Fs->except_ch=='OutMem')Fs->catch_except=TRUE; }
  return result;
}
U0 NativeGraphicsWindowFree(U8 *context,U8 *ptr)
{ Free(ptr); }
Bool NativeGraphicsWindowReserve()
{//Kernel-root public ownership, reserved before source parsing fragments RAM.
  U8 *buffers[2];
  buffers[0]=buffers[1]=NULL;
  if(graphics_zbuffer || graphics_uncovered)return graphics_zbuffer && graphics_uncovered;
  try {
    if(!GraphicsWindowReserveCore(buffers,NULL,&NativeGraphicsWindowAlloc,
        &NativeGraphicsWindowFree))return FALSE;
  } catch { Free(buffers[1]);Free(buffers[0]); }
  graphics_zbuffer=buffers[0];graphics_uncovered=buffers[1];
  return TRUE;
}

Bool NativeGraphicsReady()
{
  return graphics_owner==Fs && graphics_persistent && graphics_frame &&
    graphics_planes[0] && graphics_planes[1] && graphics_planes[2] && graphics_planes[3] &&
    gr.dc==graphics_persistent && gr.dc2==graphics_frame && gr.text_base==i386_text_base &&
    gr.win_z_buf==graphics_zbuffer && gr.win_uncovered_bitmap==graphics_uncovered;
}
Bool NativeGraphicsTextLock()
{
  if(!NativeGraphicsReady || graphics_presenting) return FALSE;
  graphics_presenting=TRUE; return TRUE;
}
U0 NativeGraphicsTextUnlock()
{ graphics_presenting=FALSE; }
U8 **NativeGraphicsPlanes()
{
  if(NativeGraphicsReady) return graphics_planes;
  return NULL;
}
Bool NativeGraphicsStorageReserve()
{//Reserve all fixed graphics storage before source parsing splits physical RAM.
  CDC *persistent=NULL,*frame=NULL;
  U8 *planes[4];I64 p;
  if(!NativeGraphicsWindowReserve)return FALSE;
  if(graphics_persistent || graphics_frame)
    return graphics_persistent && graphics_frame && graphics_planes[0] &&
      graphics_planes[1] && graphics_planes[2] && graphics_planes[3];
  for(p=0;p<4;p++)planes[p]=NULL;
  try {
    persistent=DCNew(640,480);frame=DCNew(640,480);
    persistent->flags|=DCF_SCRN_BITMAP|DCF_ON_TOP;
    frame->flags|=DCF_SCRN_BITMAP;
    DCFill(persistent,TRANSPARENT);
    for(p=0;p<4;p++)planes[p]=MAlloc(38400);
  } catch {
    for(p=0;p<4;p++)Free(planes[p]);
    DCDel(frame);DCDel(persistent);
    if(Fs->except_ch=='OutMem') { Fs->catch_except=TRUE;return FALSE; }
  }
  graphics_persistent=persistent;graphics_frame=frame;
  for(p=0;p<4;p++)graphics_planes[p]=planes[p];
  return TRUE;
}
Bool NativeGraphicsStart()
{//Associate reserved root-owned storage with the live console only after startup.
  CDC *persistent=graphics_persistent,*frame=graphics_frame;
  U16 *zbuffer=graphics_zbuffer,*uncovered=graphics_uncovered;
  I64 p,plane_bytes=0;
  if(graphics_owner)return NativeGraphicsReady;
  if(gr.dc || gr.dc2 || gr.text_base || gr.win_z_buf || gr.win_uncovered_bitmap ||
      !persistent || !frame || !zbuffer || !uncovered)return FALSE;
  for(p=0;p<4;p++) {
    if(!graphics_planes[p])return FALSE;
    plane_bytes+=MSize2(graphics_planes[p]);
  }
  KernelLog("GRAPHICS BUFFERS ");
  KernelHex(MSize2(persistent)+MSize2(persistent->body)+MSize2(persistent->r)+
    MSize2(frame)+MSize2(frame->body)+MSize2(frame->r)+plane_bytes+
    MSize2(zbuffer)+MSize2(uncovered));KernelLog("\n");
  persistent->win_task=frame->win_task=Fs;
  graphics_owner=Fs;
  gr.dc=graphics_persistent=persistent; gr.dc2=graphics_frame=frame;
  gr.text_base=i386_text_base; gr.scrn_zoom=1;
  gr.win_z_buf=graphics_zbuffer=zbuffer; gr.win_uncovered_bitmap=graphics_uncovered=uncovered;
  gr.to_8_bits=graphics_raster_bits;gr.to_8_colors=graphics_raster_colors;
  GrRasterTablesInit;
  Fs->win_left=0; Fs->win_right=79;
  Fs->win_top=0; Fs->win_bottom=59;
  LBts(&Fs->display_flags,DISPLAYf_SHOW);
  LBts(&Fs->display_flags,DISPLAYf_NO_BORDER);
  TaskDerivedValsUpdate(Fs);
  WinZBufUpdate;
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
    //Refresh from the live ring, including tasks removed since the previous frame.
    WinZBufUpdate;
    GraphicsFrameCore(gr.dc2,gr.dc,gr.text_base,text.font,blink,
      gr.pan_text_x,gr.pan_text_y,gr.hide_col,gr.hide_row,draw,gr.fp_final_scrn_update);
    GraphicsPlanarSplitCore(graphics_planes,gr.dc2->body);
    result=I386VgaSplitRows(graphics_planes,0,480);
    if(result) NativeWinRefreshCommit;
  } catch { graphics_presenting=FALSE; }
  graphics_presenting=FALSE;
  return result;
}
