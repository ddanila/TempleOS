CHashClass *OptClassFwd(CHashClass *tmpc)
{//Class forwarding for unions and subclasses.
  CHashClass *tmpc1;
  while (tmpc1=tmpc->fwd_class)
    tmpc=tmpc1;
  return tmpc;
}
