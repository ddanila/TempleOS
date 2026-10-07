Bool GraphicsWindowReserveCore(U8 **buffers,U8 *context,
  U8 *(*allocate)(U8 *context,I64 bytes),U0 (*release)(U8 *context,U8 *ptr))
{//Exclusive empty output pair; callbacks return NULL on allocation failure.
  if(!buffers || !allocate || !release || buffers[0] || buffers[1])return FALSE;
  buffers[0]=(*allocate)(context,9600);
  if(!buffers[0])return FALSE;
  buffers[1]=(*allocate)(context,8192);
  if(!buffers[1]) {
    (*release)(context,buffers[0]);buffers[0]=NULL;
    return FALSE;
  }
  return TRUE;
}
