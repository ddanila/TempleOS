#include "/Kernel/TextBaseCore.HC"
#include "/Kernel/I386/TextBaseCheck.HC"
I64 OriginalTextBaseCheck()
{
  CTask task;
  U32 *area=CAlloc(4802*4),*expected=CAlloc(4800*4),values[32],*saved=gr.text_base;
  U8 chars[32];
  I64 irq=GetRFlags,result=256,test,mode,i,x,y,length;
  Bool a,b;
  area[0]=0xAB1234CD; area[4801]=0xEF567890;
  if(TEXT_COLS!=80 || TEXT_ROWS!=60) { Free(area); Free(expected); return -1; }
  //No allocation, yielding or framebuffer upload while the isolated surface is installed.
  SetRFlags(irq&~0x200); gr.text_base=area+1;
  if(TextBaseCheck(gr.text_base,&TextChar,&TextLenStr,&TextLenAttrStr,&TextLenAttr)!=12) result=-2;
  MemSet(&task,0,sizeof(task));
  for(i=0;i<32;i++) { values[i]=0xDEADBE00+i; chars[i]=i+65; }
  for(test=0;test<64;test++) for(mode=0;mode<4;mode++) {
    for(i=0;i<4800;i++) gr.text_base[i]=expected[i]=0xA1B2C300;
    task.win_left=test%4*27-3; task.win_right=task.win_left+7;
    task.win_top=test%3*30-1; task.win_bottom=task.win_top+2;
    task.scroll_x=(test/4%3-1)*8; task.scroll_y=(test/12%3-1)*8;
    x=test%7-3; y=test%5-2; length=test%11-2;
    switch(mode) {
      case 0:
        a=TextChar(&task,test&1,x,y,0xFEDCBA98);
        b=TextBaseCharCore(expected,80,60,&task,test&1,x,y,0xFEDCBA98); break;
      case 1:
        a=TextLenStr(&task,x,y,length,0x112233FF,chars);
        b=TextBaseStrCore(expected,80,60,&task,x,y,length,0x112233FF,chars); break;
      case 2:
        a=TextLenAttrStr(&task,x,y,length,values);
        b=TextBaseAttrStrCore(expected,80,60,&task,x,y,length,values); break;
      case 3:
        a=TextLenAttr(&task,x,y,length,0x99887700);
        b=TextBaseAttrCore(expected,80,60,&task,x,y,length,0x99887700); break;
    }
    if(a!=b || !TextBaseCheckEqual(gr.text_base,expected)) { result=-3; goto done; }
  }
done:
  gr.text_base=saved; SetRFlags(irq);
  Free(area); Free(expected); return result;
}
