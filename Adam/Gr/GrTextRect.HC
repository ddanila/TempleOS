public U0 TextBorder(CTask *task=NULL,
	I64 l,I64 r,I64 t,I64 b,I64 attr,Bool solid)
{//Plot border square. 30fps in Fs->draw_it() callback.
//Draws window borders or DolDoc text bttn borders.
  //Set task=sys_winmgr_task for no clipping.
  I64 i;
  if (!task) task=Fs;
  attr<<=8;
  TextChar(task,,l-1,t-1,text.border_chars[6+solid]+attr);
  TextChar(task,,r+1,t-1,text.border_chars[8+solid]+attr);
  TextChar(task,,l-1,b+1,text.border_chars[10+solid]+attr);
  TextChar(task,,r+1,b+1,text.border_chars[12+solid]+attr);
  for (i=l;i<=r;i++) {
    TextChar(task,,i,t-1,text.border_chars[2+solid]+attr);
    TextChar(task,,i,b+1,text.border_chars[2+solid]+attr);
  }
  for (i=t;i<=b;i++) {
    TextChar(task,,l-1,i,text.border_chars[4+solid]+attr);
    TextChar(task,,r+1,i,text.border_chars[4+solid]+attr);
  }
}

public U0 TextRect(I64 l,I64 r,I64 t,I64 b,I64 d)
{//Fill text rect. 30fps in Fs->draw_it() callback.
  I64 y,w;
  if (l>r || t>b) return;
  if (t<0) t=0;
  if (b>=TEXT_ROWS) b=TEXT_ROWS-1;
  if (l<0) l=0;
  if (r>=TEXT_COLS) r=TEXT_COLS-1;
  if (l>r || t>b) return; //The clipped rectangle may be wholly outside the screen.
  if (w=r-l+1)
    for (y=t;y<=b;y++)
      MemSetU32(gr.text_base(U8 *)+(y*TEXT_COLS+l)*sizeof(U32),d,w);
}

