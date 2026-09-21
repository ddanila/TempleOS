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
U0 GraphicsPlanarCore(U8 *planes,U8 *pixels)
{//Use the same low-bit-left logical planes as the existing VGA driver.
  I64 i;
  U64 pixels8,mask=0x0101010101010101,weights=0x0102040810204080;
  for(i=0;i<38400;i++) {
    pixels8=(pixels+i*8)(U64 *)[0];
    //Each byte contributes one bit; no partial sum can carry into another byte.
    planes[i]=((pixels8&mask)*weights)>>56;
    planes[38400+i]=(((pixels8>>1)&mask)*weights)>>56;
    planes[76800+i]=(((pixels8>>2)&mask)*weights)>>56;
    planes[115200+i]=(((pixels8>>3)&mask)*weights)>>56;
  }
}
