U0 SpanProbeLog(U8 *s)
{
  while (*s) OutU8(0xE9,*s++);
}

U0 SpanProbe()
{
  MyMass *left,*right;
  MySpring *spring;
  U8 *saved,*readback,*reencoded,line[160];
  I64 size,read_size,encoded_size;
  ode=SpanNew;
  left=PlaceMass(100,200);
  right=PlaceMass(180,200);
  left->flags|=MSF_FIXED;
  mode_bttn.state=MD_STEEL;
  PlaceSpring(left,right);
  saved=SpanSave(ode,&size);
  StrPrint(line,"EXPORT steel-bridge.data %X %X\n",saved,size);
  SpanProbeLog(line);
  Sleep(2000); //Keep the exported buffer live for the QMP memory capture.
  FileWrite("B:/SpanProbe.DATA",saved,size);
  SpanDel(ode);
  ode=SpanNew;
  readback=FileRead("B:/SpanProbe.DATA",&read_size);
  if(!readback) {SpanProbeLog("FAIL Span readback\n");return;}
  SpanLoad(ode,readback);
  left=ode->next_mass;
  right=left->next;
  spring=ode->next_spring;
  if(left->x!=100 || right->x!=180 || left->y!=200 || right->y!=200 ||
      right->next!=&ode->next_mass || spring->next!=&ode->next_spring ||
      spring->end1!=left || spring->end2!=right || spring->rest_len!=80 ||
      !(left->flags&MSF_FIXED) || right->flags&MSF_FIXED)
    SpanProbeLog("FAIL Span reconstructed bridge\n");
  reencoded=SpanSave(ode,&encoded_size);
  if(size!=read_size || size!=encoded_size || MemCmp(saved,readback,size) ||
      MemCmp(saved,reencoded,size))
    SpanProbeLog("FAIL Span persistence bytes\n");
  StrPrint(line,"SPAN persisted %d bytes header %d mass %d spring %d\n",
      size,sizeof(SpanHeader),M_SIZE,S_SIZE);
  SpanProbeLog(line);
  Free(reencoded);
  Free(readback);
  Free(saved);
  SpanDel(ode);
  ode=NULL;
  SpanProbeLog("SPAN returned\n");
}
