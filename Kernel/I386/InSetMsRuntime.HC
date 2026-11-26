class CInSetMsPlotState
{
  I64 mS,l,r;
};

Bool InSetMsPlot(U8 *aux,I64 x,I64 y,I64 z)
{
  CInSetMsPlotState *state=aux;
  MsSet(x,y,z,state->l,state->r);
  (*native_window_sleep)(state->mS);
  return TRUE;
}

public U0 InSetMs(I64 mS=7,I64 x=I64_MAX,I64 y=I64_MAX,I64 z=I64_MAX,
		I64 l=I64_MAX,I64 r=I64_MAX)
{//Move mouse to spot at certain speed.
  CInSetMsPlotState state;
  if (!(0<=x<GR_WIDTH))
    x=ms.pos.x;
  if (!(0<=y<GR_HEIGHT))
    y=ms.pos.y;
  if (z==I64_MAX)
    z=ms.pos.z;
  if (!(FALSE<=l<=TRUE))
    l=ms.lb;
  if (!(FALSE<=r<=TRUE))
    r=ms.rb;
  state.mS=mS;
  state.l=l;
  state.r=r;
  Line(&state,ms.pos.x,ms.pos.y,ms.pos.z,x,y,z,&InSetMsPlot);
}
