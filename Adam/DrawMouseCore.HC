U0 DrawMs(CDC *dc)
{
  I64 x,y;
  PUSHFD
  CLI
  x=ms.pos.x;
  y=ms.pos.y;
  POPFD
  if (ms.show && ms_hard.installed) {
    if (!Bt(&sys_run_level,RLf_VGA)) //if text mode
      gr.text_base[ms.pos_text.x+ms.pos_text.y*TEXT_COLS]^=0x7F00;
    else {
      if (gr.fp_draw_ms) {
	if (ms.lb)
	  dc->color=ROP_XOR+LTPURPLE^TRANSPARENT;
	else if (ms.rb)
	  dc->color=ROP_XOR+LTCYAN^TRANSPARENT;
	else
	  dc->color=ROP_XOR+BLACK^TRANSPARENT;
	if (winmgr.grab_scroll && gr.fp_draw_grab_ms)
	  (*gr.fp_draw_grab_ms)(dc,x,y,winmgr.grab_scroll_closed);
	else
	  (*gr.fp_draw_ms)(dc,x,y);
      }
    }
  }
}

