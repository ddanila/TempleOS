#include "/Kernel/TextRenderCore.HC"
#include "/Kernel/I386/GraphicsScope.HC"
#include "/Kernel/GraphicsFrameCore.HC"
extern Bool NativeGraphicsReady();
extern U8 **NativeGraphicsPlanes();
extern Bool NativeGraphicsTextLock(CNativeGraphicsScope *scope);
extern U0 NativeGraphicsTextUnlock(CNativeGraphicsScope *scope);
Bool NativeTextBasePresent(Bool blink=FALSE,I64 pan_x=0,I64 pan_y=0,
  Bool hide_col=FALSE,Bool hide_row=FALSE)
{
  U8 *pixels=0,*owned[4],**planes=0;
  I64 p;
  for(p=0;p<4;p++) owned[p]=NULL;
  Bool result=FALSE,borrowed=FALSE;
  CNativeGraphicsScope scope;
  try {
    if(NativeGraphicsReady) {
      if(!gr.dc2 ||
          gr.dc2->dc_signature!=DCS_SIGNATURE_VAL ||
          gr.dc2->width_internal!=640 || gr.dc2->height!=480 ||
          !gr.dc2->body) goto text_present_done;
      planes=NativeGraphicsPlanes;
      if(!planes) goto text_present_done;
      if(!NativeGraphicsTextLock(&scope)) goto text_present_done;
      borrowed=TRUE;pixels=gr.dc2->body;
    }
    if(!borrowed) {
      pixels=CAlloc(307200);
      for(p=0;p<4;p++) owned[p]=CAlloc(38400);
      planes=owned;
    }
    TextRenderCore(pixels,i386_text_base,text.font,80,60,blink,pan_x,pan_y,hide_col,hide_row);
    GraphicsPlanarSplitCore(planes,pixels);
    result=I386VgaSplitRows(planes,0,480);
text_present_done:;
  } catch {
    if(borrowed) NativeGraphicsTextUnlock(&scope);
    else { for(p=0;p<4;p++) Free(owned[p]); Free(pixels); }
  }
  if(borrowed) NativeGraphicsTextUnlock(&scope);
  else { for(p=0;p<4;p++) Free(owned[p]); Free(pixels); }
  return result;
}
U0 NativeTextBaseRestore()
{
  NativeTerminalText()->dirty_first=0; NativeTerminalText()->dirty_last=60;
  ConsolePresent;
}
