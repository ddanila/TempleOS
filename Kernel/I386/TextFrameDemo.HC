#include "/Kernel/I386/TextRenderPattern.HC"
I64 TextFrameDemo(I64 mode=0)
{//Ctrl-Alt-C returns to the command console and restores the previous cell surface.
  U8 *saved=0;
  I64 before=Fs->data_heap->used_u8s,px=0,py=0;
  Bool hide=FALSE;
  if(mode==2) { px=3; py=-2; }
  if(mode==3) { px=-7; py=7; hide=TRUE; }
  try {
    saved=MAlloc(19200); MemCpy(saved,i386_text_base,19200);
    TextRenderPattern(i386_text_base);
    if(!NativeTextBasePresent(mode&1,px,py,hide,hide)) throw('TxtFrame',TRUE);
    OutU8(0xE9,64);
    while(TRUE) {}
  } catch {
    if(saved) { MemCpy(i386_text_base,saved,19200); Free(saved); }
    NativeTextBaseRestore;
    if(Fs->except_ch=='Break') Fs->catch_except=TRUE;
  }
  return Fs->data_heap->used_u8s==before;
}
