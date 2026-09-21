#include "/Kernel/TextRenderCore.HC"
#include "/Kernel/GraphicsFrameCore.HC"
Bool NativeTextBasePresent(Bool blink=FALSE,I64 pan_x=0,I64 pan_y=0,
  Bool hide_col=FALSE,Bool hide_row=FALSE)
{
  U8 *pixels=0,*planes=0;
  Bool result=FALSE;
  try {
    pixels=CAlloc(307200); planes=CAlloc(153600);
    TextRenderCore(pixels,i386_text_base,text.font,80,60,blink,pan_x,pan_y,hide_col,hide_row);
    GraphicsPlanarCore(planes,pixels);
    result=I386VgaRows(planes,0,480);
  } catch { Free(planes); Free(pixels); }
  Free(planes); Free(pixels); return result;
}
U0 NativeTextBaseRestore()
{
  console_text.dirty_first=0; console_text.dirty_last=60;
  ConsolePresent;
}
