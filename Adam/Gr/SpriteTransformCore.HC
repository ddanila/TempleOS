#include "/Adam/Gr/GrDefaultContext.HH"
public U0 Sprite3B(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y,I64 z,U8 *elems)
{//Plot a sprite into a CDC, post transform xyz translation.
  GRAPHICS_RESOLVE_DEFAULT_DC
  I64 old_x=dc->x,old_y=dc->y,old_z=dc->z,
	old_flags=dc->flags&DCF_TRANSFORMATION;
  dc->x=x; dc->y=y; dc->z=z;
  dc->flags|=DCF_TRANSFORMATION;
  Sprite3(dc,0,0,0,elems);
  dc->x=old_x; dc->y=old_y; dc->z=old_z;
  dc->flags=dc->flags&~DCF_TRANSFORMATION|old_flags;
}

public U0 Sprite3Mat4x4B(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y,I64 z,U8 *elems,I64 *m)
{//Plot rotated by matrix.
  GRAPHICS_RESOLVE_DEFAULT_DC
  I64 r[16],*old_r=dc->r,new_m[16],
	old_flags=dc->flags&DCF_TRANSFORMATION;
  MemCpy(new_m,m,16*sizeof(I64));
  dc->flags|=DCF_TRANSFORMATION;
  Mat4x4TranslationAdd(new_m,x,y,z);
  dc->r=Mat4x4MulMat4x4Equ(r,old_r,new_m);
  Sprite3(dc,0,0,0,elems);
  dc->r=old_r;
  dc->flags=dc->flags&~DCF_TRANSFORMATION|old_flags;
}

public U0 Sprite3XB(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y,I64 z,U8 *elems,F64 è=0)
{//Plot rotated around X axis.
  I64 r[16];
  Mat4x4IdentEqu(r);
  Mat4x4RotX(r,è);
  Sprite3Mat4x4B(dc,x,y,z,elems,r);
}

public U0 Sprite3YB(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y,I64 z,U8 *elems,F64 ê=0)
{//Plot rotated around Y axis.
  I64 r[16];
  Mat4x4IdentEqu(r);
  Mat4x4RotY(r,ê);
  Sprite3Mat4x4B(dc,x,y,z,elems,r);
}

public U0 Sprite3ZB(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y,I64 z,U8 *elems,F64 é=0)
{//Plot rotated around Z axis.
  I64 r[16];
  Mat4x4IdentEqu(r);
  Mat4x4RotZ(r,é);
  Sprite3Mat4x4B(dc,x,y,z,elems,r);
}
