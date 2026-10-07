#include "/Adam/Gr/GrDefaultContext.HH"
//Complete original transformed and mirrored mesh rendering.
public I64 Gr3Mesh(CDC *dc=GRAPHICS_DEFAULT_DC,I64 vertex_cnt,CD3I32 *p,
	I64 tri_cnt,CMeshTri *tri)
{//Returns cnt of pixs changed.
  GRAPHICS_RESOLVE_DEFAULT_DC
  CColorROPU32 old_color=dc->color;
  I64 i,x,y,z,res=0;
  CD3I32 *pt,*pt_sym,*p_sym,*dst;
  CMeshTri *tri_sym=tri;
  if (dc->flags&DCF_TRANSFORMATION) {
    dst=pt=MAlloc(sizeof(CD3I32)*vertex_cnt);
    for (i=0;i<vertex_cnt;i++,p++,dst++) {
      x=p->x; y=p->y; z=p->z;
      (*dc->transform)(dc,&x,&y,&z);
      dst->x=x; dst->y=y; dst->z=z;
    }
    p=pt;
  } else
    pt=NULL;

  if (dc->flags & DCF_SYMMETRY) {
    dst=pt_sym=MAlloc(sizeof(CD3I32)*vertex_cnt);
    p_sym=p;
    for (i=0;i<vertex_cnt;i++,p_sym++,dst++) {
      x=p_sym->x; y=p_sym->y; z=p_sym->z;
      DCReflect(dc,&x,&y,&z);
      dst->x=x; dst->y=y; dst->z=z;
    }
    p_sym=pt_sym;
    for (i=0;i<tri_cnt;i++,tri_sym++) {
      (*dc->lighting)(dc,&p_sym[tri_sym->nums[0]],&p_sym[tri_sym->nums[2]],
	    &p_sym[tri_sym->nums[1]],tri_sym->color);
      res+=GrFillTri0(dc,&p_sym[tri_sym->nums[0]],&p_sym[tri_sym->nums[2]],
	    &p_sym[tri_sym->nums[1]]);
    }
    Free(pt_sym);
    if (dc->flags&DCF_JUST_MIRROR)
      goto mesh_done;
  }
  for (i=0;i<tri_cnt;i++,tri++) {
    (*dc->lighting)(dc,&p[tri->nums[0]],&p[tri->nums[1]],
	  &p[tri->nums[2]],tri->color);
    res+=GrFillTri0(dc,&p[tri->nums[0]],&p[tri->nums[1]],&p[tri->nums[2]]);
  }
mesh_done:
  dc->color=old_color;
  Free(pt);
  return res;
}

