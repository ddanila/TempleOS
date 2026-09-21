#include "/Kernel/GraphicsFrameCore.HC"
#include "/Kernel/I386/GraphicsFramePattern.HC"
I64 OriginalGraphicsFrameCheck()
{
  CDC *actual=DCNew(640,480),*expected=DCNew(640,480),*persistent=DCNew(640,480),*alias;
  CDC *saved_dc=gr.dc2;
  U32 *cells=MAlloc(19200),*saved_cells=gr.text_base;
  U64 *saved_font=text.font;
  U8 *guard=MAlloc(153602),*planes=guard+1;
  I64 flags=GetRFlags,ticks=cnts.jiffies,sx=gr.pan_text_x,sy=gr.pan_text_y;
  I64 phase,test,i,px,py,result=12,color,bit;
  Bool hc=gr.hide_col,hr=gr.hide_row,hide_col,hide_row;
  actual->flags|=DCF_SCRN_BITMAP; expected->flags|=DCF_SCRN_BITMAP;
  GraphicsFramePattern(cells,persistent);
  SetRFlags(flags&~0x200);
  gr.text_base=cells; text.font=sys_font_std;
  for(phase=0;phase<2;phase++) for(test=0;test<6;test++) {
    px=py=0; hide_col=hide_row=FALSE;
    switch(test) {
      case 1: px=3; py=-2; break;
      case 2: px=-7; py=7; break;
      case 3: hide_col=hide_row=TRUE; break;
      case 4: px=99; py=-99; break;
      case 5: px=1; hide_row=TRUE; break;
    }
    cnts.jiffies=phase*200;
    gr.dc2=actual; gr.pan_text_x=px; gr.pan_text_y=py; gr.hide_col=hide_col; gr.hide_row=hide_row;
    GrUpdateTextBG; GrUpdateTextFG;
    alias=DCAlias(actual,Fs); GraphicsFrameDraw(alias); DCDel(alias);
    DCBlotColor8(actual,persistent);
    alias=DCAlias(actual,Fs); alias->flags|=DCF_ON_TOP; GraphicsFrameFinal(alias); DCDel(alias);
    gr.dc2=expected;
    GraphicsFrameCore(expected,persistent,cells,sys_font_std,phase,px,py,hide_col,hide_row,
      &GraphicsFrameDraw,&GraphicsFrameFinal);
    for(i=0;i<307200;i++) if(actual->body[i]!=expected->body[i]) {
      result=-(1+phase*6+test); goto done;
    }
    guard[0]=0xA5; guard[153601]=0x5A;
    GraphicsPlanarCore(planes,expected->body);
    if(guard[0]!=0xA5 || guard[153601]!=0x5A) { result=-100; goto done; }
    for(i=0;i<307200;i++) {
      bit=1<<(i&7);
      color=ToBool(planes[i>>3]&bit)+2*ToBool(planes[38400+(i>>3)]&bit)+
        4*ToBool(planes[76800+(i>>3)]&bit)+8*ToBool(planes[115200+(i>>3)]&bit);
      if(color!=actual->body[i]) { result=-101; goto done; }
    }
  }
done:
  gr.dc2=saved_dc; gr.text_base=saved_cells; text.font=saved_font;
  gr.pan_text_x=sx; gr.pan_text_y=sy; gr.hide_col=hc; gr.hide_row=hr;
  cnts.jiffies=ticks; SetRFlags(flags);
  DCDel(actual); DCDel(expected); DCDel(persistent); Free(cells); Free(guard);
  return result;
}
