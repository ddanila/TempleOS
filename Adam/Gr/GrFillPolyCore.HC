#include "/Adam/Gr/GrDefaultContext.HH"
public I64 GrFillPoly3(CDC *dc=GRAPHICS_DEFAULT_DC,I64 n,CD3I32 *poly)
{//3D. Must be convex.
  GRAPHICS_RESOLVE_DEFAULT_DC
//Returns cnt of pixs changed
  CD3I32 tri[3];
  I64 i,j,x,y,z,res=0;
  if (n<3) return 0;
  if (dc->flags & DCF_SYMMETRY) {
    for (i=1;i<n-1;i++) {
      j=i-1;
      if (i==1) {
	x=poly[j].x; y=poly[j].y; z=poly[j].z;
	if (dc->flags&DCF_TRANSFORMATION)
	  (*dc->transform)(dc,&x,&y,&z);
	DCReflect(dc,&x,&y,&z);
	tri[0].x=x; tri[0].y=y; tri[0].z=z;
      }

      j++;
      if (i==1) {
	x=poly[j].x; y=poly[j].y; z=poly[j].z;
	if (dc->flags&DCF_TRANSFORMATION)
	  (*dc->transform)(dc,&x,&y,&z);
	DCReflect(dc,&x,&y,&z);
      }
      tri[1].x=x; tri[1].y=y; tri[1].z=z;

      j++;
      x=poly[j].x; y=poly[j].y; z=poly[j].z;
      if (dc->flags&DCF_TRANSFORMATION)
	(*dc->transform)(dc,&x,&y,&z);
      DCReflect(dc,&x,&y,&z);
      tri[2].x=x; tri[2].y=y; tri[2].z=z;

      res+=GrFillTri0(dc,&tri[0],&tri[1],&tri[2]);
    }
  }
  if (dc->flags&DCF_JUST_MIRROR)
    return res;
  for (i=1;i<n-1;i++) {
    j=i-1;
    if (i==1) {
      x=poly[j].x; y=poly[j].y; z=poly[j].z;
      if (dc->flags&DCF_TRANSFORMATION)
	(*dc->transform)(dc,&x,&y,&z);
      tri[0].x=x; tri[0].y=y; tri[0].z=z;
    }

    j++;
    if (i==1) {
      x=poly[j].x; y=poly[j].y; z=poly[j].z;
      if (dc->flags&DCF_TRANSFORMATION)
	(*dc->transform)(dc,&x,&y,&z);
    }
    tri[1].x=x; tri[1].y=y; tri[1].z=z;

    j++;
    x=poly[j].x; y=poly[j].y; z=poly[j].z;
    if (dc->flags&DCF_TRANSFORMATION)
      (*dc->transform)(dc,&x,&y,&z);
    tri[2].x=x; tri[2].y=y; tri[2].z=z;

    res+=GrFillTri0(dc,&tri[0],&tri[1],&tri[2]);
  }
  return res;
}

