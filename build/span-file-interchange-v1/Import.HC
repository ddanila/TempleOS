U0 BridgeImportProbe()
{
  I64 input_size,output_size;
  U8 *input=FileRead("C:/IncomingBridge.DATA",&input_size),*output;
  MyMass *left,*right;
  MySpring *spring;
  if(!input || input_size!=312) {
    SpanProbeLog("FAIL Span incoming bridge size\n");
    return;
  }
  ode=SpanNew;
  SpanLoad(ode,input);
  left=ode->next_mass;
  right=left->next;
  spring=ode->next_spring;
  if(left->x!=100 || right->x!=180 || left->y!=200 || right->y!=200 ||
      right->next!=&ode->next_mass || spring->next!=&ode->next_spring ||
      spring->end1!=left || spring->end2!=right || spring->rest_len!=80 ||
      !(left->flags&MSF_FIXED) || right->flags&MSF_FIXED)
    SpanProbeLog("FAIL Span imported bridge topology\n");
  output=SpanSave(ode,&output_size);
  if(input_size!=output_size || MemCmp(input,output,input_size) ||
      !FileWrite("C:/ReturnedBridge.DATA",output,output_size))
    SpanProbeLog("FAIL Span exported bridge bytes\n");
  SpanDel(ode);
  ode=NULL;
  Free(input);
  Free(output);
  SpanProbeLog("SPAN interchange returned\n");
}
