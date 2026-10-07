//Original screen layering over explicitly supplied task drawing.
//Both contexts are full-size 640x480 packed 8-bit surfaces.
U0 GraphicsFrameCore(CDC *frame,CDC *persistent,U32 *cells,U8 *font,
  Bool blink,I64 pan_x,I64 pan_y,Bool hide_col,Bool hide_row,
  U0 (*draw)(CDC *dc),U0 (*final_draw)(CDC *dc))
{
  CDC *alias=NULL;
  try {
    TextRenderCore(frame->body,cells,font,80,60,blink,pan_x,pan_y,hide_col,hide_row);
    if(draw) {
      alias=DCAlias(frame,Fs);
      (*draw)(alias);
      DCDel(alias); alias=NULL;
    }
    DCBlotColor8(frame,persistent);
    if(final_draw) {
      alias=DCAlias(frame,Fs); alias->flags|=DCF_ON_TOP;
      (*final_draw)(alias);
      DCDel(alias); alias=NULL;
    }
  } catch { DCDel(alias); }
}
#include "/Kernel/GraphicsPlanarCore.HC"
