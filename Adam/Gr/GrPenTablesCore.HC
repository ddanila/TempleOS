//Complete original construction of all four pen arrays and circle bounds.
U0 GrPenTablesInit()
{
  CDC *dc;
  I64 i,k,x,y,rr;
  for (i=0;i<GR_PEN_BRUSHES_NUM;i++) {
    k=i+1;

    rr=k*k;
    for (y=1;y<k;y++)
      for (x=1;x<k;x++)
	if (SqrI64(y*2-k)+SqrI64(x*2-k)<rr) {
	  if (x-1-i>>1<gr.circle_lo[i][i-y])
	    gr.circle_lo[i][i-y]=x-1-i>>1;
	  if (x-1-i>>1>gr.circle_hi[i][i-y])
	    gr.circle_hi[i][i-y]=x-1-i>>1;
	}

    dc=DCNew(i,i);
    gr.pen_brushes[i]=dc;
    dc->color=COLOR_MONO;
    rr=k*k;
    for (y=1;y<k;y++)
      for (x=1;x<k;x++)
	if (SqrI64(y*2-k)+SqrI64(x*2-k)<rr)
	  GrPlot0(dc,x-1,y-1);

    dc=DCNew(i,i);
    gr.collision_pen_brushes[i]=dc;
    dc->color=COLOR_INVALID;//Want color that never occurs.
    rr=k*k;
    for (y=1;y<k;y++)
      for (x=1;x<k;x++)
	if (SqrI64(y*2-k)+SqrI64(x*2-k)<rr)
	  GrPlot0(dc,x-1,y-1);

    dc=DCNew(i,i);
    gr.even_pen_brushes[i]=dc;
    dc->color=COLOR_MONO;
    rr=k*k;
    for (y=1;y<k;y++)
      for (x=1;x<k;x++)
	if (!(((x-1)^(y-1))&1) && SqrI64(y*2-k)+SqrI64(x*2-k)<rr)
	  GrPlot0(dc,x-1,y-1);

    dc=DCNew(i,i);
    gr.odd_pen_brushes[i]=dc;
    dc->color=COLOR_MONO;
    rr=k*k;
    for (y=1;y<k;y++)
      for (x=1;x<k;x++)
	if (((x-1)^(y-1))&1 && SqrI64(y*2-k)+SqrI64(x*2-k)<rr)
	  GrPlot0(dc,x-1,y-1);
  }
}
