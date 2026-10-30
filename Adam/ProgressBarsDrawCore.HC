//Original desktop progress-bar rendering.
#define PROGRESS_BAR_HEIGHT	20
#define PROGRESS_BAR_WIDTH	(3*GR_WIDTH/4)
U0 DrawProgressBars(CDC *dc)
{
  I64 i,j,k,n,m;
  U8 *st,*st2;
  for (i=0;i<PROGRESS_BARS_NUM;i++) {
    if (m=sys_progresses[i].max) {
      dc->color=BLACK;
      GrRect(dc,
	    (GR_WIDTH-PROGRESS_BAR_WIDTH)/2,
	    (GR_HEIGHT-(PROGRESS_BARS_NUM*2-1-i*4)*PROGRESS_BAR_HEIGHT)/2,
	    PROGRESS_BAR_WIDTH,PROGRESS_BAR_HEIGHT);

      dc->color=LTGREEN;
      n=sys_progresses[i].val;
      if (n>m)
	n=m;
      GrRect(dc,
	    (GR_WIDTH-PROGRESS_BAR_WIDTH)/2+2,
	    (GR_HEIGHT-(PROGRESS_BARS_NUM*2-1-i*4)*PROGRESS_BAR_HEIGHT)/2+2,
	    n*(PROGRESS_BAR_WIDTH-4)/m,
	    PROGRESS_BAR_HEIGHT-4);

      if (m>1) {
	dc->color=BLACK;
	k=m-1;
	if (k>19) k=19;
	for (j=0;j<=k;j++)
	  GrLine(dc,
		(GR_WIDTH-PROGRESS_BAR_WIDTH)/2+1+j*
		(PROGRESS_BAR_WIDTH-4)/ToF64(k+1),
		(GR_HEIGHT-(PROGRESS_BARS_NUM*2-1-i*4)*
		PROGRESS_BAR_HEIGHT)/2+4,
		(GR_WIDTH-PROGRESS_BAR_WIDTH)/2+1+j*
		(PROGRESS_BAR_WIDTH-4)/ToF64(k+1),
		(GR_HEIGHT-(PROGRESS_BARS_NUM*2-3-i*4)*
		PROGRESS_BAR_HEIGHT)/2-4);
      }

      dc->color=GREEN;
      if (*sys_progresses[i].desc)
	st=StrNew(sys_progresses[i].desc);
      else
	st=MStrPrint("%d/%d",n,m);
      if (sys_progresses[i].t0) {
	st2=MStrPrint("%s %fs",st,tS-sys_progresses[i].t0);
	Free(st);
      } else
	st2=st;
      if (sys_progresses[i].tf) {
	st=MStrPrint("%s/%fs",st2,sys_progresses[i].tf);
	Free(st2);
      } else
	st=st2;
      GrPrint(dc,(GR_WIDTH-FONT_WIDTH*StrLen(st))/2,(GR_HEIGHT-FONT_HEIGHT-
	    (PROGRESS_BARS_NUM*2-2-i*4)*PROGRESS_BAR_HEIGHT)/2,"%s",st);
      Free(st);
    }
  }
}

