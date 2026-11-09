#ifndef MOUSE_SET_FUNCTION
#define MOUSE_SET_FUNCTION MsSet
#endif
U0 MOUSE_SET_FUNCTION(I64 x=I64_MAX,I64 y=I64_MAX,I64 z=I64_MAX,I64 l=I64_MAX,I64 r=I64_MAX)
{//Note: Generates a message. See $LK,"MsSet",A="FF:::/Demo/Games/Zing.HC,MsSet"$().
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

  x=(x-ms.offset.x)/ms.scale.x;
  y=(y-ms.offset.y)/ms.scale.y;
  z=(z-ms.offset.z)/ms.scale.z;
  MsUpdate(x,y,z,l,r);
  MsHardSet(x,y,z,l,r);
}
