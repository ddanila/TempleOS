I64 JRContract(I64 unused)
{
  I64 i,x,y,k,mask=0,expected,lo,hi;
  Bool dims=TRUE,pen=TRUE,collision=TRUE,even=TRUE,odd=TRUE,bounds=TRUE,inside;
  CDC *a,*b,*c,*d;
  for(i=0;i<64;i++) {
    a=gr.pen_brushes[i];b=gr.collision_pen_brushes[i];c=gr.even_pen_brushes[i];d=gr.odd_pen_brushes[i];k=i+1;
    if(!a || !b || !c || !d) return 0;
    if(a->width!=i || a->height!=i || b->width!=i || b->height!=i || c->width!=i || c->height!=i || d->width!=i || d->height!=i) dims=FALSE;
    for(y=0;y<i;y++)for(x=0;x<i;x++) {
      inside=(2*(x+1)-k)*(2*(x+1)-k)+(2*(y+1)-k)*(2*(y+1)-k)<k*k;
      expected=0;if(inside)expected=255;
      if(a->body[y*a->width_internal+x]!=expected)pen=FALSE;
      expected=0;if(inside)expected=16;
      if(b->body[y*b->width_internal+x]!=expected)collision=FALSE;
      expected=0;if(inside && !((x^y)&1))expected=255;
      if(c->body[y*c->width_internal+x]!=expected)even=FALSE;
      expected=0;if(inside && ((x^y)&1))expected=255;
      if(d->body[y*d->width_internal+x]!=expected)odd=FALSE;
    }
    for(y=0;y<64;y++) {
      lo=hi=0;
      if(y<i)for(x=0;x<i;x++) {
        inside=(2*(x+1)-k)*(2*(x+1)-k)+(2*(i-y)-k)*(2*(i-y)-k)<k*k;
        if(inside) {if(x-i/2<lo)lo=x-i/2;if(x-i/2>hi)hi=x-i/2;}
      }
      if(gr.circle_lo[i][y]!=lo || gr.circle_hi[i][y]!=hi)bounds=FALSE;
    }
  }
  if(dims)mask|=1;if(pen)mask|=2;if(collision)mask|=4;
  if(even)mask|=8;if(odd)mask|=16;if(bounds)mask|=32;
  return mask;
}
