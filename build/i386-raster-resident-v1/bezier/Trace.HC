class CBezierTrace
{
  I64 *samples;
  I64 count,mode,order;
  CD3I32 *points;
};
Bool TraceBezierPoint(U8 *context,I64 x,I64 y,I64 z)
{
  CBezierTrace *trace=context;
  I64 index=trace->count++;
  if(index>=1024)return FALSE;
  trace->samples[3*index]=x;
  trace->samples[3*index+1]=y;
  trace->samples[3*index+2]=z;
  if(trace->mode==3 && !index)
    trace->points[trace->order].z=99;
  return trace->mode!=2 || index<2;
}
I64 TraceBezier()
{
  CBezierTrace trace;
  CD3I32 points[4];
  I64 mode,order,mask=0,bytes;
  U8 *name;
  Bool result;
  Bool (*curve)(U8 *aux,CD3I32 *ctrl,
    Bool (*plot)(U8 *aux,I64 x,I64 y,I64 z),Bool first);
  trace.samples=CAlloc(1024*3*sizeof(I64));
  trace.points=points;
  for(order=2;order<=3;order++)for(mode=0;mode<4;mode++) {
    trace.order=order;trace.mode=mode;trace.count=0;
    points[0].x=-8;points[0].y=13;points[0].z=7;
    points[1].x=7;points[1].y=37;points[1].z=-18;
    points[2].x=35;points[2].y=-3;points[2].z=22;
    points[3].x=53;points[3].y=14;points[3].z=-23;
    if(order==2)curve=BEZIER_SECOND;
    else curve=BEZIER_THIRD;
    result=(*curve)(&trace,points,&TraceBezierPoint,mode!=1);
    bytes=trace.count*3*sizeof(I64);
    name=MStrPrint("Trace%d%d.BIN",order,mode);
    if(result==(mode!=2) && trace.count>1 && trace.count<1024 &&
        TRACE_WRITE(name,trace.samples,bytes)>0)
      mask|=1<<((order-2)*4+mode);
    Free(name);
  }
  Free(trace.samples);
  return mask;
}
