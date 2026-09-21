#include "/Kernel/TextRenderCore.HC"
Bool NativeTextBasePresent(Bool blink=FALSE,I64 pan_x=0,I64 pan_y=0,
  Bool hide_col=FALSE,Bool hide_row=FALSE)
{
  U8 *pixels=0,*planes=0;
  I64 i,bit,color,a,b,c,d;
  Bool result=FALSE;
  try {
    pixels=CAlloc(307200); planes=CAlloc(153600);
    TextRenderCore(pixels,i386_text_base,sys_font_std,80,60,blink,pan_x,pan_y,hide_col,hide_row);
    for(i=0;i<38400;i++) {
      a=b=c=d=0;
      for(bit=0;bit<8;bit++) {
        color=pixels[i*8+bit];
        if(color&1) a|=1<<bit; if(color&2) b|=1<<bit;
        if(color&4) c|=1<<bit; if(color&8) d|=1<<bit;
      }
      planes[i]=a; planes[38400+i]=b; planes[76800+i]=c; planes[115200+i]=d;
    }
    result=I386VgaRows(planes,0,480);
  } catch { Free(planes); Free(pixels); }
  Free(planes); Free(pixels); return result;
}
U0 NativeTextBaseRestore()
{
  console_text.dirty_first=0; console_text.dirty_last=60;
  ConsolePresent;
}
