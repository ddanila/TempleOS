class CWindowFault {
  CI386Heap heap;
  I64 calls,fail_at,releases;
};
U8 *WindowFaultAlloc(U8 *context,I64 bytes)
{
  CWindowFault *fault=context;
  if(fault->calls++==fault->fail_at)return 0;
  return I386HeapAlloc(&fault->heap,bytes,TRUE);
}
U0 WindowFaultFree(U8 *context,U8 *ptr)
{
  CWindowFault *fault=context;
  fault->releases++;
  I386HeapFree(&fault->heap,ptr);
}
I64 GraphicsWindowReserveTest()
{//Reservation publishes no partial pair, reclaims either failed stage and retries.
  CWindowFault fault;
  U8 *buffers[2];
  I64 stage,i;
  for(stage=0;stage<2;stage++) {
    buffers[0]=buffers[1]=0;
    fault.calls=fault.releases=0; fault.fail_at=stage;
    if(!I386HeapInit(&fault.heap,0x48000,65536))return 460;
    if(GraphicsWindowReserveCore(buffers,&fault,&WindowFaultAlloc,&WindowFaultFree) ||
        buffers[0] || buffers[1] || fault.heap.used || fault.heap.allocations ||
        fault.releases!=stage || !I386HeapValid(&fault.heap))return 461;
    fault.calls=fault.releases=0;fault.fail_at=-1;
    if(!GraphicsWindowReserveCore(buffers,&fault,&WindowFaultAlloc,&WindowFaultFree) ||
        I386HeapSize(&fault.heap,buffers[0])!=9600 ||
        I386HeapSize(&fault.heap,buffers[1])!=8192 || fault.heap.allocations!=2)return 462;
    for(i=0;i<9600;i++)if(buffers[0][i])return 463;
    for(i=0;i<8192;i++)if(buffers[1][i])return 464;
    if(GraphicsWindowReserveCore(buffers,&fault,&WindowFaultAlloc,&WindowFaultFree) ||
        fault.calls!=2 || fault.releases)return 465;
    WindowFaultFree(&fault,buffers[0]);WindowFaultFree(&fault,buffers[1]);
    if(fault.heap.used || fault.heap.allocations || !I386HeapValid(&fault.heap))return 466;
  }
  return 0;
}
