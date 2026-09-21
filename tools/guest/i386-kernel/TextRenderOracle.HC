#include "/Kernel/TextRenderCore.HC"
#include "/Kernel/I386/TextRenderPattern.HC"
I64 OriginalTextRenderCheck()
{
  CDC dc,*saved_dc=gr.dc2;
  U8 *actual=MAlloc(307200),*expected=MAlloc(307200);
  U32 *cells=MAlloc(19200),*saved_cells=gr.text_base;
  U64 *saved_font=text.font;
  I64 flags=GetRFlags,saved_ticks=cnts.jiffies,saved_x=gr.pan_text_x,saved_y=gr.pan_text_y;
  I64 phase,test,i,px,py,result=12;
  Bool saved_col=gr.hide_col,saved_row=gr.hide_row,hc,hr;
  MemSet(&dc,0,sizeof(dc)); dc.body=actual; dc.width_internal=640; dc.height=480;
  TextRenderPattern(cells);
  SetRFlags(flags&~0x200);
  gr.dc2=&dc; gr.text_base=cells; text.font=sys_font_std;
  for(phase=0;phase<2;phase++) for(test=0;test<6;test++) {
    px=py=0; hc=hr=FALSE;
    switch(test) {
      case 1: px=3; py=-2; break;
      case 2: px=-7; py=7; break;
      case 3: hc=hr=TRUE; break;
      case 4: px=99; py=-99; break;
      case 5: px=1; hr=TRUE; break;
    }
    cnts.jiffies=phase*200;
    gr.pan_text_x=px; gr.pan_text_y=py; gr.hide_col=hc; gr.hide_row=hr;
    MemSet(actual,0xA5,307200);
    GrUpdateTextBG; GrUpdateTextFG;
    TextRenderCore(expected,cells,sys_font_std,80,60,phase,px,py,hc,hr);
    for(i=0;i<307200;i++) if(actual[i]!=expected[i]) {
      result=-(1+phase*6+test); goto done;
    }
  }
done:
  gr.dc2=saved_dc; gr.text_base=saved_cells; text.font=saved_font;
  gr.pan_text_x=saved_x; gr.pan_text_y=saved_y; gr.hide_col=saved_col; gr.hide_row=saved_row;
  cnts.jiffies=saved_ticks; SetRFlags(flags);
  if(result<0) { "Text rendering mismatch: case %d pixel %d actual %d expected %d\n",-result,i,actual[i],expected[i]; }
  Free(actual); Free(expected); Free(cells); return result;
}
